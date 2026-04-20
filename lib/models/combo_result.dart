import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ComboResult {
  final String type;
  final double multiplier;
  final String displayText;
  final String emoji;
  final Color color;

  const ComboResult({
    required this.type,
    required this.multiplier,
    required this.displayText,
    required this.emoji,
    required this.color,
  });

  static ComboResult exactMatch() => const ComboResult(
        type: 'exact_match',
        multiplier: 1.5,
        displayText: 'EXACT MATCH!',
        emoji: '🎯',
        color: AppColors.gold,
      );

  static ComboResult consecutiveDoubles(int count) => ComboResult(
        type: 'consecutive_doubles',
        multiplier: 1.0 + (count - 1) * 0.3,
        displayText: '$count× DOUBLES!',
        emoji: '✌️',
        color: AppColors.blue,
      );

  static ComboResult zoneMastery() => const ComboResult(
        type: 'zone_mastery',
        multiplier: 1.4,
        displayText: 'ZONE MASTER!',
        emoji: '🔥',
        color: AppColors.red,
      );

  static ComboResult streak(int count) => ComboResult(
        type: 'streak',
        multiplier: 1.0 + count * 0.1,
        displayText: '$count× STREAK!',
        emoji: '⚡',
        color: AppColors.green,
      );

  String get multiplierLabel =>
      multiplier > 1.0 ? '${multiplier.toStringAsFixed(1)}×' : '';
}
