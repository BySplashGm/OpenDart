import '../models/game.dart';
import '../models/throw_record.dart';
import '../services/database_service.dart';

class PlayerStats {
  final String playerId;
  final double averagePPD;
  final double checkoutRate;
  final int totalGames;
  final int totalWins;
  final int highestTurn;
  final int count180s;
  final Map<String, int> zoneAccuracy;
  final List<String> topCheckouts;
  final List<double> recentAverages;

  const PlayerStats({
    required this.playerId,
    required this.averagePPD,
    required this.checkoutRate,
    required this.totalGames,
    required this.totalWins,
    required this.highestTurn,
    required this.count180s,
    required this.zoneAccuracy,
    required this.topCheckouts,
    required this.recentAverages,
  });
}

class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  final _db = DatabaseService.instance;

  Future<PlayerStats> getPlayerStats(String playerId) async {
    final throws = await _db.getThrowsForPlayer(playerId);
    final games = await _db.getGamesForPlayer(playerId);

    return PlayerStats(
      playerId: playerId,
      averagePPD: _computePPD(throws),
      checkoutRate: _computeCheckoutRate(throws, games, playerId),
      totalGames: games.length,
      totalWins: games.where((g) => g.winnerId == playerId).length,
      highestTurn: _computeHighestTurn(throws, playerId),
      count180s: _count180s(throws, playerId),
      zoneAccuracy: _computeZoneAccuracy(throws),
      topCheckouts: _computeTopCheckouts(throws, games, playerId),
      recentAverages: await _computeRecentAverages(playerId, games),
    );
  }

  double _computePPD(List<ThrowRecord> throws) {
    final valid = throws.where((t) => !t.isBust).toList();
    if (valid.isEmpty) return 0;
    final total = valid.fold(0, (sum, t) => sum + t.scoreValue);
    return total / valid.length;
  }

  double _computeCheckoutRate(
    List<ThrowRecord> throws,
    List<Game> games,
    String playerId,
  ) {
    // Opportunities: turns where remaining score was <= 170 (would need to check game context)
    // Simplified: wins / finished games
    if (games.isEmpty) return 0;
    final wins = games.where((g) => g.winnerId == playerId).length;
    return wins / games.length;
  }

  int _computeHighestTurn(List<ThrowRecord> throws, String playerId) {
    if (throws.isEmpty) return 0;

    // Group by game_id + round
    final turnMap = <String, List<ThrowRecord>>{};
    for (final t in throws.where((t) => !t.isBust)) {
      final key = '${t.gameId}_${t.round}';
      turnMap.putIfAbsent(key, () => []).add(t);
    }

    if (turnMap.isEmpty) return 0;
    return turnMap.values
        .map((darts) => darts.fold(0, (sum, t) => sum + t.scoreValue))
        .reduce((a, b) => a > b ? a : b);
  }

  int _count180s(List<ThrowRecord> throws, String playerId) {
    final turnMap = <String, List<ThrowRecord>>{};
    for (final t in throws.where((t) => !t.isBust)) {
      final key = '${t.gameId}_${t.round}';
      turnMap.putIfAbsent(key, () => []).add(t);
    }

    return turnMap.values
        .where((darts) =>
            darts.length == 3 &&
            darts.fold(0, (sum, t) => sum + t.scoreValue) == 180)
        .length;
  }

  Map<String, int> _computeZoneAccuracy(List<ThrowRecord> throws) {
    final counts = <String, int>{
      'single': 0,
      'double': 0,
      'triple': 0,
      'bull': 0,
      'outer_bull': 0,
      'miss': 0,
    };
    for (final t in throws) {
      final key = counts.containsKey(t.multiplierType) ? t.multiplierType : 'single';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  List<String> _computeTopCheckouts(
    List<ThrowRecord> throws,
    List<Game> games,
    String playerId,
  ) {
    final winGameIds = games
        .where((g) => g.winnerId == playerId)
        .map((g) => g.id)
        .toSet();

    // Find the last throw of each won game for this player
    final checkoutThrows = <String>[];
    for (final gameId in winGameIds) {
      final gameThrows = throws
          .where((t) => t.gameId == gameId && !t.isBust)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (gameThrows.isNotEmpty) {
        checkoutThrows.add(gameThrows.last.displayLabel);
      }
    }

    // Count occurrences and return top 5
    final freq = <String, int>{};
    for (final label in checkoutThrows) {
      freq[label] = (freq[label] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  Future<List<double>> _computeRecentAverages(
    String playerId,
    List<Game> games, {
    int lastN = 10,
  }) async {
    final recent = games.take(lastN).toList();
    final result = <double>[];

    for (final game in recent) {
      final gameThrows = (await _db.getThrowsForGame(game.id))
          .where((t) => t.playerId == playerId && !t.isBust)
          .toList();
      if (gameThrows.isEmpty) {
        result.add(0);
      } else {
        final total = gameThrows.fold(0, (sum, t) => sum + t.scoreValue);
        result.add(total / gameThrows.length);
      }
    }
    return result;
  }
}
