/// Holds app-wide game rule constants.
/// Full per-game rules (doubleOut, doubleIn) are stored directly on [Game].
/// A configurable rules engine is deferred to Phase 2.
abstract final class GameRules {
  static const List<int> variants = [301, 501, 701];
}
