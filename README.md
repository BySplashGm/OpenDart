# OpenDart

An open-source darts scoring app built with Flutter.

## Features

- **501 / 301 / 701** — standard game variants with double-out checkout rules
- **Local multiplayer** — multiple players on one device, turn-based
- **Checkout suggestions** — hints shown when you're in range (e.g. `T20 → D20`)
- **Statistics** — PPD average, win rate, zone accuracy (single/double/triple/bull), 180s, game history, leaderboard
- **Combo Mode** *(optional)* — Balatro-inspired mechanics: exact match bonuses, consecutive doubles, zone mastery, streaks — cosmetic only, does not affect actual scores
- **Offline** — all data stored locally via SQLite, no account or network required

## Screenshots

> Coming soon

## Getting Started

### Requirements

- Flutter SDK ≥ 3.11
- Dart SDK ≥ 3.11
- Xcode 15+ (iOS builds)
- Android Studio or connected Android device

### Run

```bash
git clone https://github.com/BySplashGm/OpenDart.git
cd OpenDart
flutter pub get
flutter run
```

Supported targets: **iOS and Android only**.

## Architecture

```
lib/
├── models/        # Plain data classes (Player, Game, ThrowRecord, …)
├── services/      # Business logic (DatabaseService, GameService, StatsService)
├── providers/     # Riverpod state (players, active game, stats)
├── ui/
│   ├── screens/   # Full-page views
│   └── widgets/   # Reusable components
├── utils/         # Score validation, checkout table, constants
└── theme/         # Balatro-inspired dark theme
```

State management: [Riverpod](https://riverpod.dev)  
Local storage: [sqflite](https://pub.dev/packages/sqflite)  
Animations: [flutter_animate](https://pub.dev/packages/flutter_animate)

## Game Rules

- Starts at 501, 301, or 701
- Each player throws up to 3 darts per turn
- Score is subtracted from the starting total
- **Bust**: going below 0, reaching 1, or reaching 0 without a double/bull → score restored, turn ends
- **Win**: reach exactly 0 with a double or bullseye

## Contributing

Issues and pull requests are welcome. See [TASKS.md](TASKS.md) for the current feature roadmap.

## License

MIT
