import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/game.dart';
import '../models/throw_record.dart';
import '../models/combo_result.dart';
import '../services/database_service.dart';
import '../services/game_service.dart';
import '../utils/score_validator.dart';
import '../utils/constants.dart';

class GameState {
  final Game game;
  final Map<String, int> remainingScores;
  final int currentPlayerIndex;
  final int currentRound;
  final List<ThrowRecord> currentTurnThrows;
  final List<ThrowRecord> allThrows;
  final ComboResult? lastCombo;
  final Map<String, int> streakCounts;
  final bool isGameOver;
  final String? bustPlayerId;

  const GameState({
    required this.game,
    required this.remainingScores,
    required this.currentPlayerIndex,
    required this.currentRound,
    required this.currentTurnThrows,
    required this.allThrows,
    this.lastCombo,
    required this.streakCounts,
    this.isGameOver = false,
    this.bustPlayerId,
  });

  String get currentPlayerId => game.playerOrder[currentPlayerIndex];

  int get currentRemaining => remainingScores[currentPlayerId] ?? 0;

  int get dartsThisTurn => currentTurnThrows.length;

  bool get canThrow => dartsThisTurn < AppConstants.maxDartsPerTurn && !isGameOver;

  GameState copyWith({
    Game? game,
    Map<String, int>? remainingScores,
    int? currentPlayerIndex,
    int? currentRound,
    List<ThrowRecord>? currentTurnThrows,
    List<ThrowRecord>? allThrows,
    ComboResult? Function()? lastCombo,
    Map<String, int>? streakCounts,
    bool? isGameOver,
    String? Function()? bustPlayerId,
  }) =>
      GameState(
        game: game ?? this.game,
        remainingScores: remainingScores ?? this.remainingScores,
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
        currentRound: currentRound ?? this.currentRound,
        currentTurnThrows: currentTurnThrows ?? this.currentTurnThrows,
        allThrows: allThrows ?? this.allThrows,
        lastCombo: lastCombo != null ? lastCombo() : this.lastCombo,
        streakCounts: streakCounts ?? this.streakCounts,
        isGameOver: isGameOver ?? this.isGameOver,
        bustPlayerId: bustPlayerId != null ? bustPlayerId() : this.bustPlayerId,
      );
}

class GameNotifier extends Notifier<GameState?> {
  final _db = DatabaseService.instance;
  final _uuid = const Uuid();

  @override
  GameState? build() => null;

  Future<void> startGame(Game game) async {
    await _db.insertGame(game);
    final scores = {for (final id in game.playerOrder) id: game.startingScore};
    state = GameState(
      game: game,
      remainingScores: scores,
      currentPlayerIndex: 0,
      currentRound: 1,
      currentTurnThrows: [],
      allThrows: [],
      streakCounts: {for (final id in game.playerOrder) id: 0},
    );
  }

  Future<ThrowRecord?> recordThrow(int rawValue, String multiplierType) async {
    final s = state;
    if (s == null || !s.canThrow) return null;

    final score = ScoreValidator.computeScore(rawValue, multiplierType);
    if (score == null) return null;

    final bustResult = ScoreValidator.checkBust(
      remaining: s.currentRemaining,
      scoreValue: score,
      multiplierType: multiplierType,
      doubleOut: s.game.doubleOut,
    );

    final isBust = bustResult.isBust;
    final isWin = !isBust &&
        ScoreValidator.isWinningThrow(
          newRemaining: bustResult.newRemaining,
          multiplierType: multiplierType,
          doubleOut: s.game.doubleOut,
        );

    final t = ThrowRecord(
      id: _uuid.v4(),
      gameId: s.game.id,
      playerId: s.currentPlayerId,
      round: s.currentRound,
      dartNumber: s.dartsThisTurn + 1,
      scoreValue: score,
      rawValue: rawValue,
      multiplierType: multiplierType,
      isBust: isBust,
      createdAt: DateTime.now(),
    );

    await _db.insertThrow(t);

    final newTurnThrows = [...s.currentTurnThrows, t];
    final newAllThrows = [...s.allThrows, t];

    final newRemaining = isBust ? s.currentRemaining : bustResult.newRemaining;
    final newScores = {...s.remainingScores, s.currentPlayerId: newRemaining};

    if (isWin) {
      final finishedGame = s.game.copyWith(
        endDate: DateTime.now(),
        winnerId: s.currentPlayerId,
      );
      await _db.updateGame(finishedGame);
      state = s.copyWith(
        game: finishedGame,
        remainingScores: newScores,
        currentTurnThrows: newTurnThrows,
        allThrows: newAllThrows,
        isGameOver: true,
      );
      return t;
    }

    // Auto-advance turn on bust or after 3 darts
    final turnDone = isBust || newTurnThrows.length >= AppConstants.maxDartsPerTurn;

    if (turnDone) {
      state = s.copyWith(
        remainingScores: newScores,
        currentTurnThrows: newTurnThrows,
        allThrows: newAllThrows,
        bustPlayerId: isBust ? () => s.currentPlayerId : () => null,
      );
      await _advanceTurn(isBust: isBust, turnThrows: newTurnThrows, newScores: newScores, newAllThrows: newAllThrows);
    } else {
      state = s.copyWith(
        remainingScores: newScores,
        currentTurnThrows: newTurnThrows,
        allThrows: newAllThrows,
        bustPlayerId: () => null,
      );
    }

    return t;
  }

  Future<void> _advanceTurn({
    required bool isBust,
    required List<ThrowRecord> turnThrows,
    required Map<String, int> newScores,
    required List<ThrowRecord> newAllThrows,
  }) async {
    final s = state;
    if (s == null) return;

    // Evaluate combos only when combo mode is enabled and turn wasn't a bust
    ComboResult? combo;
    if (!isBust && s.game.comboMode) {
      final nonBustThrows = turnThrows.where((t) => !t.isBust).toList();
      final turnTotal = GameService.turnTotal(nonBustThrows);
      final streakCount = (s.streakCounts[s.currentPlayerId] ?? 0);

      // Get previous player's last turn score for exact match
      final prevPlayerIndex = (s.currentPlayerIndex - 1 + s.game.playerOrder.length) %
          s.game.playerOrder.length;
      final prevPlayerId = s.game.playerOrder[prevPlayerIndex];
      final prevTurnTotal = GameService.lastTurnTotalForPlayer(
        prevPlayerId,
        s.currentRound,
        newAllThrows,
      );

      combo = GameService.evaluateCombos(
        currentTurnThrows: nonBustThrows,
        previousTurnScore: prevTurnTotal,
        streakCount: streakCount,
      );

      // Update streak count
      final newStreak = GameService.updateStreak(streakCount, turnTotal);
      final newStreakCounts = {...s.streakCounts, s.currentPlayerId: newStreak};

      final nextIndex = (s.currentPlayerIndex + 1) % s.game.playerOrder.length;
      final nextRound = nextIndex == 0 ? s.currentRound + 1 : s.currentRound;

      state = s.copyWith(
        remainingScores: newScores,
        currentPlayerIndex: nextIndex,
        currentRound: nextRound,
        currentTurnThrows: [],
        allThrows: newAllThrows,
        lastCombo: () => combo,
        streakCounts: newStreakCounts,
        bustPlayerId: () => null,
      );
    } else {
      final nextIndex = (s.currentPlayerIndex + 1) % s.game.playerOrder.length;
      final nextRound = nextIndex == 0 ? s.currentRound + 1 : s.currentRound;

      state = s.copyWith(
        remainingScores: newScores,
        currentPlayerIndex: nextIndex,
        currentRound: nextRound,
        currentTurnThrows: [],
        allThrows: newAllThrows,
        lastCombo: () => null,
        bustPlayerId: () => null,
      );
    }
  }

  Future<void> undoLastThrow() async {
    final s = state;
    if (s == null || s.allThrows.isEmpty) return;

    final last = s.allThrows.last;
    await _db.deleteThrow(last.id);

    final newAllThrows = s.allThrows.sublist(0, s.allThrows.length - 1);
    final newTurnThrows = s.currentTurnThrows.isEmpty
        ? s.currentTurnThrows
        : s.currentTurnThrows.sublist(0, s.currentTurnThrows.length - 1);

    // Restore score
    final restored = (s.remainingScores[last.playerId] ?? 0) +
        (last.isBust ? 0 : last.scoreValue);
    final newScores = {...s.remainingScores, last.playerId: restored};

    state = s.copyWith(
      remainingScores: newScores,
      currentTurnThrows: newTurnThrows,
      allThrows: newAllThrows,
      lastCombo: () => null,
      bustPlayerId: () => null,
    );
  }

  void dismissCombo() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(lastCombo: () => null);
  }

  void reset() => state = null;
}

final gameProvider = NotifierProvider<GameNotifier, GameState?>(GameNotifier.new);
