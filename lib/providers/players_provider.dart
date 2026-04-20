import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../services/database_service.dart';

class PlayersNotifier extends AsyncNotifier<List<Player>> {
  final _db = DatabaseService.instance;
  final _uuid = const Uuid();

  @override
  Future<List<Player>> build() => _db.getPlayers();

  Future<Player> addPlayer(String name) async {
    final existing = state.valueOrNull ?? [];
    final player = Player(
      id: _uuid.v4(),
      name: name.trim(),
      avatarColor: Player.defaultColor(existing.length),
      createdAt: DateTime.now(),
    );
    await _db.insertPlayer(player);
    state = AsyncData([...existing, player]);
    return player;
  }

  Future<void> updatePlayer(Player player) async {
    await _db.updatePlayer(player);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((p) => p.id == player.id ? player : p).toList(),
    );
  }

  Future<void> deletePlayer(String id) async {
    await _db.deletePlayer(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((p) => p.id != id).toList());
  }
}

final playersProvider =
    AsyncNotifierProvider<PlayersNotifier, List<Player>>(PlayersNotifier.new);
