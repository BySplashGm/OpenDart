import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Player {
  final String id;
  final String name;
  final int avatarColor;
  final DateTime createdAt;

  const Player({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.createdAt,
  });

  Color get color => Color(avatarColor);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatar_color': avatarColor,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Player.fromMap(Map<String, dynamic> map) => Player(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarColor: map['avatar_color'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Player copyWith({String? name, int? avatarColor}) => Player(
        id: id,
        name: name ?? this.name,
        avatarColor: avatarColor ?? this.avatarColor,
        createdAt: createdAt,
      );

  static int defaultColor(int index) =>
      AppColors.avatarColors[index % AppColors.avatarColors.length].toARGB32();
}
