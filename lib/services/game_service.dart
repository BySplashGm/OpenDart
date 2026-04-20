import '../models/throw_record.dart';
import '../models/combo_result.dart';
import '../utils/constants.dart';

class TurnResult {
  final int totalScore;
  final bool hasBust;
  final ComboResult? combo;
  final bool isWin;

  const TurnResult({
    required this.totalScore,
    required this.hasBust,
    this.combo,
    required this.isWin,
  });
}

abstract final class GameService {
  /// Evaluates combo bonuses for a completed turn.
  /// [currentTurnThrows] — the 1-3 darts thrown this turn (not busted individually).
  /// [previousTurnScore] — the total non-bust score of the previous active player's last turn (for exact match).
  /// [streakCount] — how many consecutive turns >= [AppConstants.streakThreshold] the current player has.
  static ComboResult? evaluateCombos({
    required List<ThrowRecord> currentTurnThrows,
    required int? previousTurnScore,
    required int streakCount,
  }) {
    if (currentTurnThrows.isEmpty) return null;

    final nonBustThrows = currentTurnThrows.where((t) => !t.isBust).toList();
    if (nonBustThrows.isEmpty) return null;

    final turnTotal = nonBustThrows.fold<int>(0, (sum, t) => sum + t.scoreValue);

    // Zone mastery: all 3 darts hit the same sector
    if (nonBustThrows.length == 3) {
      final allSameSector = nonBustThrows.every(
        (t) => t.rawValue == nonBustThrows.first.rawValue &&
               t.multiplierType != MultiplierType.miss,
      );
      if (allSameSector) return ComboResult.zoneMastery();
    }

    // Consecutive doubles: 2+ doubles in one turn
    final doubleCount = nonBustThrows
        .where((t) => MultiplierType.isDouble(t.multiplierType))
        .length;
    if (doubleCount >= 2) return ComboResult.consecutiveDoubles(doubleCount);

    // Exact match: same turn total as previous player
    if (previousTurnScore != null && turnTotal == previousTurnScore && turnTotal > 0) {
      return ComboResult.exactMatch();
    }

    // Streak: 3+ consecutive turns >= threshold
    if (turnTotal >= AppConstants.streakThreshold && streakCount >= AppConstants.streakRequiredTurns) {
      return ComboResult.streak(streakCount);
    }

    return null;
  }

  /// Returns the updated streak count for a player after a turn.
  static int updateStreak(int currentStreak, int turnTotal) {
    if (turnTotal >= AppConstants.streakThreshold) {
      return currentStreak + 1;
    }
    return 0;
  }

  /// Computes the total score for a list of throws (excluding busts).
  static int turnTotal(List<ThrowRecord> throws) =>
      throws.where((t) => !t.isBust).fold<int>(0, (sum, t) => sum + t.scoreValue);

  /// Gets the last full non-bust turn total for a given player from [allThrows].
  /// Looks back through completed turns (groups of up to 3 darts per round).
  static int? lastTurnTotalForPlayer(
    String playerId,
    int currentRound,
    List<ThrowRecord> allThrows,
  ) {
    final lastRound = currentRound - 1;
    if (lastRound < 1) return null;

    final throws = allThrows
        .where((t) => t.playerId == playerId && t.round == lastRound && !t.isBust)
        .toList();

    if (throws.isEmpty) return null;
    return throws.fold<int>(0, (sum, t) => sum + t.scoreValue);
  }
}
