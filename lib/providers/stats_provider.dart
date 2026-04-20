import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../services/stats_service.dart';
import '../services/database_service.dart';
import 'players_provider.dart';

final playerStatsProvider = FutureProvider.family(
  (ref, String playerId) => StatsService.instance.getPlayerStats(playerId),
);

final gameHistoryProvider = FutureProvider<List<Game>>((ref) async {
  // Refresh when players change
  ref.watch(playersProvider);
  return DatabaseService.instance.getGameHistory();
});
