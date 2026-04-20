import 'dart:convert';

class Game {
  final String id;
  final int startingScore;
  final List<String> playerIds;
  final List<String> playerOrder;
  final DateTime startDate;
  final DateTime? endDate;
  final String? winnerId;
  final bool doubleOut;
  final bool doubleIn;
  final bool comboMode;

  const Game({
    required this.id,
    required this.startingScore,
    required this.playerIds,
    required this.playerOrder,
    required this.startDate,
    this.endDate,
    this.winnerId,
    this.doubleOut = true,
    this.doubleIn = false,
    this.comboMode = false,
  });

  bool get isFinished => winnerId != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'starting_score': startingScore,
        'player_ids': jsonEncode(playerIds),
        'player_order': jsonEncode(playerOrder),
        'start_date': startDate.millisecondsSinceEpoch,
        'end_date': endDate?.millisecondsSinceEpoch,
        'winner_id': winnerId,
        'double_out': doubleOut ? 1 : 0,
        'double_in': doubleIn ? 1 : 0,
        'combo_mode': comboMode ? 1 : 0,
      };

  factory Game.fromMap(Map<String, dynamic> map) => Game(
        id: map['id'] as String,
        startingScore: map['starting_score'] as int,
        playerIds: List<String>.from(jsonDecode(map['player_ids'] as String) as List),
        playerOrder: List<String>.from(jsonDecode(map['player_order'] as String) as List),
        startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
        endDate: map['end_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
            : null,
        winnerId: map['winner_id'] as String?,
        doubleOut: (map['double_out'] as int) == 1,
        doubleIn: (map['double_in'] as int) == 1,
        comboMode: ((map['combo_mode'] as int?) ?? 0) == 1,
      );

  Game copyWith({DateTime? endDate, String? winnerId}) => Game(
        id: id,
        startingScore: startingScore,
        playerIds: playerIds,
        playerOrder: playerOrder,
        startDate: startDate,
        endDate: endDate ?? this.endDate,
        winnerId: winnerId ?? this.winnerId,
        doubleOut: doubleOut,
        doubleIn: doubleIn,
        comboMode: comboMode,
      );
}
