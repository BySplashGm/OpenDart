import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../models/throw_record.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'opendart.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar_color INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE games (
        id TEXT PRIMARY KEY,
        starting_score INTEGER NOT NULL,
        player_ids TEXT NOT NULL,
        player_order TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        winner_id TEXT,
        double_out INTEGER NOT NULL DEFAULT 1,
        double_in INTEGER NOT NULL DEFAULT 0,
        combo_mode INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE throws (
        id TEXT PRIMARY KEY,
        game_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        round INTEGER NOT NULL,
        dart_number INTEGER NOT NULL,
        score_value INTEGER NOT NULL,
        raw_value INTEGER NOT NULL,
        multiplier_type TEXT NOT NULL,
        combo_multiplier REAL NOT NULL DEFAULT 1.0,
        combo_type TEXT,
        is_bust INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE games ADD COLUMN combo_mode INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  // ---- Players ----

  Future<void> insertPlayer(Player player) async {
    final db = await database;
    await db.insert('players', player.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Player>> getPlayers() async {
    final db = await database;
    final rows = await db.query('players', orderBy: 'created_at ASC');
    return rows.map(Player.fromMap).toList();
  }

  Future<Player?> getPlayerById(String id) async {
    final db = await database;
    final rows = await db.query('players', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Player.fromMap(rows.first);
  }

  Future<void> updatePlayer(Player player) async {
    final db = await database;
    await db.update('players', player.toMap(),
        where: 'id = ?', whereArgs: [player.id]);
  }

  Future<void> deletePlayer(String id) async {
    final db = await database;
    await db.delete('players', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Games ----

  Future<void> insertGame(Game game) async {
    final db = await database;
    await db.insert('games', game.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Game?> getGameById(String id) async {
    final db = await database;
    final rows = await db.query('games', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Game.fromMap(rows.first);
  }

  Future<List<Game>> getGameHistory({int? limit}) async {
    final db = await database;
    final rows = await db.query(
      'games',
      where: 'winner_id IS NOT NULL',
      orderBy: 'end_date DESC',
      limit: limit,
    );
    return rows.map(Game.fromMap).toList();
  }

  Future<List<Game>> getGamesForPlayer(String playerId) async {
    final db = await database;
    // player_ids is a JSON array; use LIKE for a simple check
    final rows = await db.query(
      'games',
      where: "player_ids LIKE ? AND winner_id IS NOT NULL",
      whereArgs: ['%$playerId%'],
      orderBy: 'end_date DESC',
    );
    return rows.map(Game.fromMap).toList();
  }

  Future<void> updateGame(Game game) async {
    final db = await database;
    await db.update('games', game.toMap(),
        where: 'id = ?', whereArgs: [game.id]);
  }

  // ---- Throws ----

  Future<void> insertThrow(ThrowRecord t) async {
    final db = await database;
    await db.insert('throws', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ThrowRecord>> getThrowsForGame(String gameId) async {
    final db = await database;
    final rows = await db.query(
      'throws',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'round ASC, dart_number ASC',
    );
    return rows.map(ThrowRecord.fromMap).toList();
  }

  Future<List<ThrowRecord>> getThrowsForPlayer(String playerId) async {
    final db = await database;
    final rows = await db.query(
      'throws',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ThrowRecord.fromMap).toList();
  }

  Future<void> deleteThrow(String throwId) async {
    final db = await database;
    await db.delete('throws', where: 'id = ?', whereArgs: [throwId]);
  }

  Future<void> deleteThrowsForGame(String gameId) async {
    final db = await database;
    await db.delete('throws', where: 'game_id = ?', whereArgs: [gameId]);
  }
}
