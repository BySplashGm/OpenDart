abstract final class AppConstants {
  static const int maxDartsPerTurn = 3;
  static const int maxSector = 20;
  static const int bullValue = 50;
  static const int outerBullValue = 25;
  static const int maxTurnScore = 180; // T20 T20 T20
  static const int streakThreshold = 60;
  static const int streakRequiredTurns = 3;

  // Score variants
  static const List<int> gameVariants = [301, 501, 701];

  // Checkout range: show suggestions when remaining <= this
  static const int checkoutRange = 170;
}
