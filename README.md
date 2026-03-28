# Last Dot

A fast-paced iOS memory game where you race to find the newest dot on the screen. Each round adds one more — tap the wrong one and it's game over.

---

## Gameplay

- A new dot appears every round
- Find and tap **only** the new one
- Wrong tap = Game Over
- Your score is the number of rounds survived

**Classic mode** — no time pressure, pure focus
**Arcade mode** — a countdown timer shrinks every level, dots get smaller and fade as difficulty scales

---

## Architecture

The project follows **Clean Architecture** with strict layer separation:

```
WheresTheDot/
├── Domain/          # Value types, enums, protocols — no dependencies
├── Data/            # Concrete implementations (repositories, adapters)
├── Use Cases/       # Orchestrators between domain and presentation
├── Presentation/    # SwiftUI views, coordinators, state
├── Tools/           # Cross-cutting concerns (analytics, config, audio, haptics)
├── Utils/           # Extensions
└── GameScene.swift  # SpriteKit scene — pure rendering + touch input
```

| Layer | Key types |
|---|---|
| Domain | `Dot`, `Round`, `GameSnapshot`, `Difficulty`, `Theme`, `ThemeID` |
| Data | `InMemoryGameSessionRepository`, `SimpleArcadeProgression`, `UserDefaultsThemeRepository` |
| Use Cases | `StartGameUseCase`, `AddDotIfCorrectUseCase`, `CheckThemeUnlocksUseCase` |
| Presentation | `AppState`, `GameCoordinator`, `AppContainer`, `GameContainerView` |
| Tools | `FirebaseEventsManager`, `RemoteConfigManager`, `GameCenterManager`, `AudioManager` |

Use cases are **callable structs** (`callAsFunction`) — called as `startGame(in: area)`, not `startGame.execute(in: area)`.

---

## Tech Stack

- **Swift / SwiftUI** — UI
- **SpriteKit** — game rendering, dot animations, particle effects
- **GameplayKit** — seeded RNG (`GKARC4RandomSource`) behind a `RandomNumberGenerating` protocol
- **GameKit** — Game Center leaderboard integration
- **AVFoundation** — background music
- **Firebase Analytics** — event tracking
- **Firebase Remote Config** — runtime feature flags and game tuning

---

## Theme / Progression System

Players unlock visual themes by accumulating a lifetime score across all sessions:

| Theme | Unlock | Vibe |
|---|---|---|
| Neon | Free | Cyan grid, neon dot palette |
| Forest | 50 pts | Green grid, earthy tones |
| Ocean | 150 pts | Blue grid, cool palette |
| Cosmos | 350 pts | Purple grid, deep space palette |

Each theme applies a unique background color, grid color, and dot palette to both the menus and the live game scene. Milestone values are remotely configurable.

---

## Remote Config

Game tuning constants are controlled via Firebase Remote Config — no app update required to change them. Defaults are defined in `Supporting Files/remote_config_defaults.plist`.

| Key | Default | Controls |
|---|---|---|
| `arcade_time_limit_base` | 2.5 | Base seconds for the arcade timer |
| `arcade_difficulty_step` | 5 | Points between difficulty levels |
| `memory_cover_duration` | 0.45 | Cover duration between rounds |
| `onboarding_enabled` | true | Kill switch for the onboarding flow |
| `arcade_mode_enabled` | true | Feature flag for arcade mode |
| `default_theme` | neon | Theme applied on first launch |
| `theme_forest_milestone` | 50 | Forest unlock threshold |
| `theme_ocean_milestone` | 150 | Ocean unlock threshold |
| `theme_cosmos_milestone` | 350 | Cosmos unlock threshold |

---

## Getting Started

### Requirements

- Xcode 16+
- iOS 17+ deployment target
- A Firebase project with Analytics and Remote Config enabled

### Setup

1. Clone the repo
2. Add your `GoogleService-Info.plist` to `WheresTheDot/Supporting Files/`
   *(the file in this repo is excluded from version control)*
3. Open `WheresTheDot.xcodeproj`
4. Build and run

> The app uses Xcode's file system synchronized groups — no manual `.xcodeproj` edits needed when adding new files inside existing folders.

### Firebase console setup

In your Firebase project, create the Remote Config parameters listed above before running in release mode. The app will fall back to the plist defaults if Remote Config is unreachable.

---

## Analytics Events

All events are dispatched through `FirebaseEventsManager`. Key events:

| Event | Trigger |
|---|---|
| `select_game_mode` | Mode button tapped |
| `game_over` | Wrong tap or time up (includes `reason`, `score`, `mode`) |
| `game_ended` | Session ended (includes `duration_seconds`, `score`, `mode`) |
| `game_quit` | X button tapped mid-game |
| `theme_unlocked` | Milestone reached |
| `select_theme` | Theme card tapped |
| `onboarding_started` / `completed` / `skipped` | Onboarding funnel |
| `leaderboard_opened` | Game Center leaderboard tapped |

---

## Admin Panel

A developer-only panel for overriding Remote Config values locally without touching Firebase.

To enable: set `AdminConfig.isEnabled = true` in `Tools/AdminConfig.swift`.
A wrench icon appears in the main menu footer. Overrides persist in UserDefaults across launches.

**Never ship with `AdminConfig.isEnabled = true`.**

---

## Localization

The app is localized in **English**, **Spanish (es)**, and **Latin American Spanish (es-419)** via `Supporting Files/Localizable.xcstrings`. Theme names use `LocalizedStringResource` so `Text(theme.name)` localizes automatically.

---

## Project Guidelines

See [`CLAUDE.md`](CLAUDE.md) for architecture rules, naming conventions, and what to avoid when contributing.
