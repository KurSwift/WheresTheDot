# WheresTheDot — Claude Code Instructions

## Project Overview

"Where's The Dot" is a casual iOS memory game built with Swift. Players must remember and tap the newest dot added to the screen each round. A wrong tap ends the game. Score equals the number of dots successfully identified.

## Architecture

Clean Architecture with strict layer separation:

```
WheresTheDot/
├── Domain/          # Entities, protocols, core business rules
│   └── Protocols/   # DotLayoutGenerating, GameSessionRepository, LevelProgression, ThemeRepository, …
├── Data/            # Concrete implementations (repositories, adapters)
├── Use Cases/       # Orchestrators between domain and presentation
├── Presentation/    # SwiftUI views, coordinators, state
│   ├── AnimatedDots/
│   ├── Components/
│   ├── Routes/
│   └── View Models/
├── Tools/           # Cross-cutting concerns (audio, haptics, analytics, config)
├── Utils/           # Extensions
├── GameScene.swift  # SpriteKit scene (rendering + touch input)
└── WheresTheDot.swift  # @main entry point + AppDelegate
```

### Layer Responsibilities

- **Domain**: Immutable value types (`Dot`, `Round`, `GameSnapshot`, `Difficulty`, `Theme`), enums (`GameMode`, `RoundOutcome`, `ThemeID`), and protocols (`DotLayoutGenerating`, `GameSessionRepository`, `LevelProgression`, `ThemeRepository`, `RandomNumberGenerating`).
- **Data**: Concrete implementations — `InMemoryGameSessionRepository`, `GKRandomAdapter` (wraps GameplayKit), `DotLayoutGenerator`, `SimpleArcadeProgression`, `UserDefaultsThemeRepository`.
- **Use Cases**: Callable structs (`StartGameUseCase`, `AddDotIfCorrectUseCase`, `CheckThemeUnlocksUseCase`). Call with `useCase(args)` not `useCase.execute(args)`.
- **Presentation**: `AppState` (navigation + settings + theme), `GameCoordinator` (game flow), `AppContainer` (DI root).
- **Tools**: `AudioManager` (singleton, background music), `Haptics` (enum with static methods), `FirebaseEventsManager` (analytics), `RemoteConfigManager` (remote config + local overrides), `GameCenterManager` (leaderboards), `AdminConfig` (dev flag).

## Key Patterns

### Use Cases as Callable Structs
```swift
struct StartGameUseCase {
    func callAsFunction(in area: CGRect) -> Round { ... }
}
// Used as: startGame(in: area)
```

### Dependency Injection via AppContainer
```swift
@MainActor final class AppContainer: ObservableObject {
    let startGame: StartGameUseCase
    let addDotIfCorrect: AddDotIfCorrectUseCase
}
// Provided via .environmentObject(container) at root
```

### Coordinator for Game State
```swift
@MainActor final class GameCoordinator: ObservableObject {
    @Published var roundIndex: Int
    @Published var score: Int
    // Owns game flow; drives SpriteKit scene via closures
}
```

### SpriteKit ↔ SwiftUI Bridge
- `GameScene` is embedded in SwiftUI via `SpriteView`
- Scene communicates up via closures: `onDotTapped`, `onSceneReady`, `onTapFeedback`
- SwiftUI overlays (HUD, game-over sheet) sit on top of `SpriteView`
- Theme is applied to the scene via `scene.themeColors`, `scene.themeGridColor`, `scene.themeBackgroundColor`

### Protocols — Naming Convention
Protocol names use the `-ing` suffix: `DotLayoutGenerating`, `RandomNumberGenerating`, `LevelProgression`.

## Naming Conventions

| Category | Convention | Example |
|---|---|---|
| Types, structs, classes | PascalCase | `GameSnapshot`, `AppContainer` |
| Protocols | PascalCase + `-ing` | `DotLayoutGenerating` |
| Enums | PascalCase | `GameMode`, `RoundOutcome` |
| Files — Views | `*View.swift` | `MainMenuView.swift` |
| Files — Use Cases | `*UseCase.swift` | `StartGameUseCase.swift` |
| Files — Repositories | `*Repository.swift` | `InMemoryGameSessionRepository.swift` |
| Files — Adapters | `*Adapter.swift` | `GKRandomAdapter.swift` |
| Files — Styles | `*Style.swift` | `DottoButtonStyle.swift` |
| Files — Extensions | `Type+Extensions.swift` | `Color+Extensions.swift` |

## Tech Stack

- **Swift / SwiftUI** — primary UI framework
- **SpriteKit** — game rendering, animations, particle effects
- **GameplayKit** — RNG via `GKARC4RandomSource` (wrapped behind `RandomNumberGenerating`)
- **AVFoundation** — background music
- **UIKit** — haptics (`UIImpactFeedbackGenerator`), `UIColor` color definitions
- **GameKit** — Game Center leaderboards via `GameCenterManager`
- **Firebase Analytics** — event tracking via `FirebaseEventsManager`
- **Firebase Remote Config** — runtime feature flags via `RemoteConfigManager`
- **No additional external packages** — only Firebase (already integrated)

## Game Modes

- **Classic**: No time limit, endless rounds
- **Arcade**: Difficulty scales every N points (configurable via Remote Config `arcade_difficulty_step`). Radius shrinks, timing tightens, dot size variation increases.
- **Daily**: Deterministic seed (in progress)

## Theme System

Themes are defined in `Domain/Theme.swift` and unlock via cumulative lifetime score milestones:

| Theme | Unlock | Background | Grid |
|---|---|---|---|
| Neon | Free | `#05060A` | Cyan |
| Forest | 50 pts | `#050D07` | Green |
| Ocean | 150 pts | `#03080F` | Cyan-blue |
| Cosmos | 350 pts | `#080510` | Purple |

- `ThemeID` is a `String`-rawValue `CaseIterable` enum — safe for `@AppStorage` and `Codable`.
- `Theme.name` is `LocalizedStringResource` so `Text(theme.name)` auto-localizes.
- `AppState.currentTheme` is the single source of truth for the active theme.
- `CheckThemeUnlocksUseCase` records cumulative score and returns newly unlocked themes on game over.
- Milestone values can be overridden via Remote Config (`theme_forest_milestone`, etc.).
- Do not read `theme.unlockScore` for unlock logic — use `RemoteConfigManager.shared.milestone(for:)`.

## Firebase Analytics

All events go through `FirebaseEventsManager` (static methods only). `GameOverReason` enum provides typed `reason` parameters (`wrongTap` / `timeUp`).

Key events: `select_game_mode`, `game_over`, `game_ended`, `game_quit`, `open_themes`, `select_theme`, `theme_unlocked`, `onboarding_started`, `onboarding_intro_dismissed`, `onboarding_completed`, `onboarding_skipped`, `leaderboard_opened`, `open_settings`, `sound_enabled/disabled`, `haptics_enabled/disabled`, `color_blind_mode_enabled/disabled`.

## Firebase Remote Config

`RemoteConfigManager.shared` is the single access point. It has a local override layer (backed by UserDefaults with `rc.override.` prefix) used by the admin panel.

**Always read values from `RemoteConfigManager.shared` — never hardcode the following:**

| Key | Controls |
|---|---|
| `arcade_time_limit_base` | Base seconds for arcade timer at level 1 |
| `arcade_difficulty_step` | Points between difficulty levels |
| `memory_cover_duration` | Cover duration between rounds |
| `onboarding_enabled` | Kill switch for onboarding flow |
| `arcade_mode_enabled` | Feature flag for arcade mode |
| `default_theme` | Theme for first-time users |
| `theme_forest_milestone` | Forest unlock threshold |
| `theme_ocean_milestone` | Ocean unlock threshold |
| `theme_cosmos_milestone` | Cosmos unlock threshold |

Offline defaults live in `Supporting Files/remote_config_defaults.plist`.

## Admin Panel

`AdminConfig.isEnabled` (default `false`) is a compile-time flag in `Tools/AdminConfig.swift`. When `true`, a wrench button appears in the main menu footer, routing to `AdminView` via `.admin` in `AppRoute`. **Never ship with `isEnabled = true`.**

## Visual Design

**Color palette** (`Color+Extensions.swift`):
- Neons: cyan, magenta, purple, lime, yellow, coral, orange, pink
- Accessible variants: blue, amber, teal, yellow, lavender, danger
- Background: `#05060A` (Neon theme black), per-theme dark tints for others
- States: lime = success, red = danger

**Visual conventions:**
- Additive blend mode for glow/neon effects in SpriteKit
- `NeonGridBackground(color:backgroundColor:)` for menu/settings backgrounds — always pass `appState.currentTheme.gridColor` and `appState.currentTheme.backgroundColor`
- `DottoButtonStyle` for all primary buttons — gradient capsule with glossy overlay
- Glass/material overlays for settings and modals

## Localization

- Languages: **English** (source), **Spanish (es)**, **Latin American Spanish (es-419)**
- Strings file: `Supporting Files/Localizable.xcstrings`
- Theme names use `LocalizedStringResource` so `Text(theme.name)` localizes automatically
- Admin panel strings are intentionally not localized (developer-only UI)
- Do not add raw `String` literals to user-facing `Text()` calls without a corresponding xcstrings entry

## Concurrency

- `@MainActor` on `AppState`, `AppContainer`, `GameCoordinator`, `AudioManager`, `Haptics`
- `RemoteConfigManager` and `FirebaseEventsManager` are NOT actor-isolated — safe to call from anywhere
- Use `Task { @MainActor in ... }` when bridging from non-actor contexts
- SpriteKit callbacks return to main thread via closures

## Testing

- Framework: **Swift Testing** (`@Test`, `#expect`)
- Tests live in `WheresTheDotTests/`
- Domain logic (use cases, layout generators) should be unit-tested with injected fakes
- UI tests in `WheresTheDotUITests/` (currently stubs)

## What to Avoid

- Do not add external Swift packages unless asked
- Do not introduce UIKit navigation (push/present); routing goes through `AppRoute` enum + `RootView`
- Do not add logic to `GameScene`; keep it as a pure rendering/input layer
- Do not break the protocol abstraction in Domain — concrete types belong in Data
- Do not use `UserDefaults` directly; go through a repository protocol
- Do not hardcode game tuning values that belong in Remote Config (time limits, difficulty step, milestones)
- Do not read `theme.unlockScore` for unlock checks — use `RemoteConfigManager.shared.milestone(for:)`
- Do not pass hardcoded colors to `NeonGridBackground` — use the active theme's colors
