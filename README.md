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
├── Tools/           # Cross-cutting concerns (analytics, config, audio, haptics, ads, IAP)
├── Utils/           # Extensions
└── GameScene.swift  # SpriteKit scene — pure rendering + touch input
```

| Layer | Key types |
|---|---|
| Domain | `Dot`, `Round`, `GameSnapshot`, `Difficulty`, `Theme`, `ThemeID` |
| Data | `InMemoryGameSessionRepository`, `SimpleArcadeProgression`, `UserDefaultsThemeRepository`, `UserDefaultsScoreRepository` |
| Use Cases | `StartGameUseCase`, `AddDotIfCorrectUseCase`, `CheckThemeUnlocksUseCase`, `EvaluateSelectionUseCase`, `AdvanceDifficultyUseCase` |
| Presentation | `AppState`, `GameCoordinator`, `AppContainer`, `GameContainerView` |
| Tools | `FirebaseEventsManager`, `RemoteConfigManager`, `GameCenterManager`, `AudioManager`, `AdsManager`, `StoreKitManager` |

Use cases are **callable structs** (`callAsFunction`) — called as `startGame(in: area)`, not `startGame.execute(in: area)`.

---

## Tech Stack

- **Swift / SwiftUI** — UI
- **SpriteKit** — game rendering, dot animations, particle effects
- **GameplayKit** — seeded RNG (`GKARC4RandomSource`) behind a `RandomNumberGenerating` protocol
- **GameKit** — Game Center leaderboards and achievements
- **StoreKit 2** — in-app purchases (premium upgrade)
- **AVFoundation** — background music
- **Firebase Analytics** — event tracking
- **Firebase Remote Config** — runtime feature flags and game tuning
- **Google Mobile Ads** — interstitial ads shown after game over (suppressed for premium users)

---

## Theme / Progression System

Themes unlock either by reaching a cumulative lifetime score or via in-app purchase:

| Theme | Unlock | Vibe |
|---|---|---|
| Neon | Free | Cyan grid, neon dot palette |
| Forest | 50 pts | Green grid, earthy tones |
| Ocean | Premium | Cyan-blue grid, cool palette |
| Cosmos | Premium | Purple grid, deep space palette |
| Aurora | Premium | Icy blue grid, snowflake-shaped dots |
| Inferno | Premium | Orange grid, fire-shaped dots |
| DoctorPing | Premium | Medical blue grid, stethoscope dots |
| Space Travel | Premium | Dark grid, star-shaped dots |

Each theme applies a unique background color, grid color, and dot palette to both menus and the live game scene. Score-based milestone values (Forest) are remotely configurable.

---

## Premium / Monetization

The app is free to play. A single **Last Dot Premium** IAP (`com.optionalsankur.Dotto.premium`) unlocks:

- Ad-free experience (interstitials suppressed permanently)
- Ocean and Cosmos themes
- DoctorPing and Space Travel themes

Aurora and Inferno are also available as individual theme purchases (`com.optionalsankur.Dotto.theme.aurora` / `.theme.inferno`), and are included when the premium bundle is active.

Ads are managed by `AdsManager` (Google Mobile Ads), which shows an interstitial every N game overs and skips it automatically for premium users. `StoreKitManager` handles product fetching, purchase flow, and entitlement verification via StoreKit 2 transaction listeners.

---

## Game Center

`GameCenterManager` integrates leaderboards and achievements.

**Leaderboards**: separate boards for Classic (`lastdot_classic`) and Arcade (`lastdot_arcade`) modes.

**Achievements** (12 total):

| Achievement | Trigger |
|---|---|
| `lastdot.first_dot` | Score ≥ 1 in any mode |
| `lastdot.score10_classic` | Score ≥ 10 in Classic |
| `lastdot.score25_classic` | Score ≥ 25 in Classic |
| `lastdot.score50_classic` | Score ≥ 50 in Classic |
| `lastdot.score100_classic` | Score ≥ 100 in Classic |
| `lastdot.score10_arcade` | Score ≥ 10 in Arcade |
| `lastdot.score25_arcade` | Score ≥ 25 in Arcade |
| `lastdot.score50_arcade` | Score ≥ 50 in Arcade |
| `lastdot.unlock_forest` | Forest theme unlocked |
| `lastdot.unlock_ocean` | Ocean theme unlocked |
| `lastdot.unlock_cosmos` | Cosmos theme unlocked |
| `lastdot.play_10_games` | 10 games played (progressive) |

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
| `store_opened` | Purchase screen opened |
| `iap_purchased` | IAP completed (includes `product_id`) |
| `iap_restored` | Purchases restored |
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
