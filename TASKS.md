# OpenDart — MVP Task Breakdown

> Track progress here throughout development. Check off tasks as completed.

---

## Phase 0 — Project Bootstrap

- [x] Update `pubspec.yaml` with all dependencies (sqflite, riverpod, flutter_animate, google_fonts, intl, uuid, path)
- [x] Create `TASKS.md` (this file)
- [x] Run `flutter pub get`
- [x] Establish `lib/` package structure

---

## Phase 1 — Data Layer

### 1.1 Models (`lib/models/`)

| File | Description | Status |
|------|-------------|--------|
| `player.dart` | Player entity: id, name, avatarColor, createdAt | [x] |
| `game.dart` | Game entity: id, startingScore, playerIds, playerOrder, dates, winner | [x] |
| `throw_record.dart` | ThrowRecord: dart throw details, raw/score value, multiplierType, comboMultiplier | [x] |
| `game_rules.dart` | GameRules: startingScore, doubleOut, doubleIn | [x] |
| `combo_result.dart` | ComboResult: type, multiplier, displayText | [x] |

### 1.2 Database Schema (`lib/services/database_service.dart`)

**Tables:**

```sql
players  (id TEXT PK, name TEXT, avatar_color INT, created_at INT)
games    (id TEXT PK, starting_score INT, player_ids TEXT/JSON, player_order TEXT/JSON,
          start_date INT, end_date INT?, winner_id TEXT?, double_out INT, double_in INT)
throws   (id TEXT PK, game_id TEXT FK, player_id TEXT, round INT, dart_number INT,
          score_value INT, raw_value INT, multiplier_type TEXT, combo_multiplier REAL,
          combo_type TEXT?, is_bust INT, created_at INT)
```

**Methods to implement:**
- [x] `init()` — create tables if not exist
- [x] `insertPlayer` / `getPlayers` / `updatePlayer` / `deletePlayer`
- [x] `insertGame` / `getGames` / `updateGame` / `getGameById`
- [x] `insertThrow` / `getThrowsForGame` / `getThrowsForPlayer` / `deleteLastThrow`

---

## Phase 2 — Game Logic

### 2.1 Utilities (`lib/utils/`)

| File | Responsibility | Status |
|------|---------------|--------|
| `constants.dart` | App-wide constants (colors, sector ranges, etc.) | [x] |
| `score_validator.dart` | Validate throw values, compute bust conditions | [x] |
| `checkout_helper.dart` | Pre-computed checkout suggestions table (2–170) | [x] |

### 2.2 Game Service (`lib/services/game_service.dart`)

- [x] Turn management (3 darts per turn, advance player)
- [x] Score subtraction + bust detection
  - `remaining - score < 0` → bust
  - `remaining - score == 1` → bust
  - `remaining - score == 0` AND last dart not double/bull → bust
- [x] Win detection (remaining == 0, last dart = double/bull)
- [x] Combo evaluation after each full turn:
  - **Exact Match**: Turn total == previous player's turn total → 1.5×
  - **Consecutive Doubles**: 2+ doubles in one turn → 1.3× per extra double
  - **Zone Mastery**: All 3 darts hit same sector → 1.4×
  - **Streak Bonus**: 3 consecutive turns ≥ 60 pts → celebration
- [x] Undo last dart

### 2.3 Stats Service (`lib/services/stats_service.dart`)

- [x] `getAveragePPD(playerId)` — avg points per dart (non-bust throws)
- [x] `getCheckoutRate(playerId)` — success rate when at checkout range
- [x] `getCommonCheckouts(playerId)` — top 5 winning last throws
- [x] `getZoneAccuracy(playerId)` — breakdown by single/double/triple/bull
- [x] `getHighestTurn(playerId)` — max points in a single turn
- [x] `getCount180s(playerId)` — turns totalling 180
- [x] `getRecentAverages(playerId, {int lastN = 10})` — PPD trend over last N games

---

## Phase 3 — State Management

### 3.1 Riverpod Providers (`lib/providers/`)

| File | Description | Status |
|------|-------------|--------|
| `players_provider.dart` | AsyncNotifier for CRUD on player list | [x] |
| `game_provider.dart` | Notifier for active game state machine | [x] |
| `stats_provider.dart` | Family providers for per-player/game stats | [x] |

**GameState fields:**
```
game, remainingScores, currentPlayerIndex, currentRound,
currentTurnThrows (1-3 darts), allThrows, lastCombo,
streakCounts, isGameOver
```

**GameNotifier actions:**
- [x] `recordThrow(rawValue, multiplierType)` — record dart, check bust/win
- [x] `undoLastThrow()` — remove last dart, restore score
- [x] `endTurn()` — evaluate combos, advance to next player
- [x] `endGame(winnerId)` — persist final state

---

## Phase 4 — UI

### 4.1 Theme (`lib/theme/app_theme.dart`)

Balatro-inspired dark palette:
- Background: `#0D1117` (deep navy)
- Card surface: `#1A1B2E` (dark purple)
- Accent gold: `#FFD700`
- Accent red: `#E63946`
- Accent green: `#2DC653`
- Font: Google Fonts Nunito (bold, rounded)
- [x] Define `AppTheme` with colors, text styles, card decoration

### 4.2 Screens (`lib/ui/screens/`)

| Screen | Key Elements | Status |
|--------|-------------|--------|
| `home_screen.dart` | Logo, Quick Start, Manage Players, Stats buttons | [x] |
| `players_screen.dart` | Player list, Add (FAB), swipe-to-delete, rename | [x] |
| `game_setup_screen.dart` | Variant selector (301/501/701), player picker, Start button | [x] |
| `active_game_screen.dart` | Score pad, current score, other players panel, combo banner, undo | [x] |
| `game_summary_screen.dart` | Winner card, turn breakdown, key stats, Play Again | [x] |
| `stats_screen.dart` | Tab: per-player stats / game history / leaderboard | [x] |

### 4.3 Widgets (`lib/ui/widgets/`)

| Widget | Description | Status |
|--------|-------------|--------|
| `score_input_pad.dart` | Number grid + S/D/T + Bull/Outer buttons | [x] |
| `player_score_card.dart` | Remaining score, PPD, active combo indicator | [x] |
| `combo_banner.dart` | Animated slide-in/out combo announcement | [x] |
| `checkout_suggestion.dart` | Checkout path chip (e.g. `T20 → D20`) | [x] |
| `stat_card.dart` | Reusable stat display card | [x] |

---

## Phase 5 — Testing

### Unit Tests (`test/`)

| Test | Coverage | Status |
|------|----------|--------|
| `game_logic_test.dart` | Score calculation, bust detection, win detection, combos, checkouts | [x] |

### Widget Tests

| Test | Coverage | Status |
|------|----------|--------|
| `score_input_pad_test.dart` | Input flow, invalid combos disabled | [ ] |
| `active_game_test.dart` | Full turn, score update, undo, bust | [ ] |

> Widget tests require sqflite FFI setup for test environment — Phase 2.

---

## Dependencies

```
sqflite: ^2.3.3       — SQLite storage
path: ^1.9.0          — DB file path
flutter_riverpod: ^2.6.1 — State management
google_fonts: ^6.2.1  — Nunito font
flutter_animate: ^4.5.0  — Score/combo animations
intl: ^0.19.0         — Date formatting
uuid: ^4.5.0          — Entity ID generation
```

---

## Architecture Notes

- **Combos are cosmetic** — multipliers are stored and displayed but do NOT modify the actual 501/301/701 score (rules remain pure)
- **Offline-first** — all data is local SQLite, no network calls
- **Clean separation**: `models/` ← `services/` ← `providers/` ← `ui/`
- **Phase 2 deferred**: Custom rules engine, advanced combo mechanics, chip system
