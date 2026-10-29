import '../models/throw_record.dart';

abstract final class ScoreValidator {
  /// Returns true if [rawValue] is a legal sector (1-20).
  static bool isValidSector(int rawValue) => rawValue >= 1 && rawValue <= 20;

  /// Computes the dart score for a given raw sector and multiplier type.
  /// Returns null if the combination is illegal.
  static int? computeScore(int rawValue, String multiplierType) {
    if (multiplierType == MultiplierType.bull) return 50;
    if (multiplierType == MultiplierType.outerBull) return 25;
    if (multiplierType == MultiplierType.miss) return 0;
    if (!isValidSector(rawValue)) return null;
    return MultiplierType.computeScore(rawValue, multiplierType);
  }

  /// Determines if a throw would be a bust given the current remaining score.
  /// Also returns the new remaining score if not a bust.
  static ({bool isBust, int newRemaining}) checkBust({
    required int remaining,
    required int scoreValue,
    required String multiplierType,
    required bool doubleOut,
  }) {
    final newRemaining = remaining - scoreValue;

    if (newRemaining < 0) return (isBust: true, newRemaining: remaining);
    if (newRemaining == 1) return (isBust: true, newRemaining: remaining);

    if (newRemaining == 0 && doubleOut) {
      final isValidOut = MultiplierType.isDouble(multiplierType);
      if (!isValidOut) return (isBust: true, newRemaining: remaining);
    }

    return (isBust: false, newRemaining: newRemaining);
  }

  /// Returns true if the current remaining score can theoretically be checked out.
  static bool isCheckoutPossible(int remaining) =>
      remaining >= 2 && remaining <= 170;

  /// Returns true if this throw is a winning throw.
  static bool isWinningThrow({
    required int newRemaining,
    required String multiplierType,
    required bool doubleOut,
  }) {
    if (newRemaining != 0) return false;
    if (doubleOut) return MultiplierType.isDouble(multiplierType);
    return true;
  }
}
