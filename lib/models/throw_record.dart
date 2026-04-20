abstract final class MultiplierType {
  static const single = 'single';
  static const double_ = 'double';
  static const triple = 'triple';
  static const bull = 'bull';
  static const outerBull = 'outer_bull';
  static const miss = 'miss';

  static bool isDouble(String type) => type == double_ || type == bull;

  static int computeScore(int rawValue, String type) {
    return switch (type) {
      double_ => rawValue * 2,
      triple => rawValue * 3,
      bull => 50,
      outerBull => 25,
      miss => 0,
      _ => rawValue, // single
    };
  }

  static String label(String type) => switch (type) {
        double_ => 'D',
        triple => 'T',
        bull => 'Bull',
        outerBull => 'Outer',
        miss => 'Miss',
        _ => 'S',
      };
}

abstract final class ComboType {
  static const exactMatch = 'exact_match';
  static const consecutiveDoubles = 'consecutive_doubles';
  static const zoneMastery = 'zone_mastery';
  static const streak = 'streak';
}

class ThrowRecord {
  final String id;
  final String gameId;
  final String playerId;
  final int round;
  final int dartNumber;
  final int scoreValue;
  final int rawValue;
  final String multiplierType;
  final double comboMultiplier;
  final String? comboType;
  final bool isBust;
  final DateTime createdAt;

  const ThrowRecord({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.round,
    required this.dartNumber,
    required this.scoreValue,
    required this.rawValue,
    required this.multiplierType,
    this.comboMultiplier = 1.0,
    this.comboType,
    this.isBust = false,
    required this.createdAt,
  });

  bool get isDouble => MultiplierType.isDouble(multiplierType);

  String get displayLabel {
    if (multiplierType == MultiplierType.bull) return 'Bull';
    if (multiplierType == MultiplierType.outerBull) return 'Outer';
    if (multiplierType == MultiplierType.miss) return 'Miss';
    return '${MultiplierType.label(multiplierType)}$rawValue';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'game_id': gameId,
        'player_id': playerId,
        'round': round,
        'dart_number': dartNumber,
        'score_value': scoreValue,
        'raw_value': rawValue,
        'multiplier_type': multiplierType,
        'combo_multiplier': comboMultiplier,
        'combo_type': comboType,
        'is_bust': isBust ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ThrowRecord.fromMap(Map<String, dynamic> map) => ThrowRecord(
        id: map['id'] as String,
        gameId: map['game_id'] as String,
        playerId: map['player_id'] as String,
        round: map['round'] as int,
        dartNumber: map['dart_number'] as int,
        scoreValue: map['score_value'] as int,
        rawValue: map['raw_value'] as int,
        multiplierType: map['multiplier_type'] as String,
        comboMultiplier: (map['combo_multiplier'] as num).toDouble(),
        comboType: map['combo_type'] as String?,
        isBust: (map['is_bust'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
