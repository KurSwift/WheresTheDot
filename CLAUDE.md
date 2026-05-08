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
- **Tools**: `AudioManager` (singleton, background music), `Haptics` (enum with static methods), `FirebaseEventsManager` (analytics), `RemoteConfigManager` (remote config + local overrides), `GameCenterManager` (leaderboards + achievements), `StoreKitManager` (IAP, singleton), `AdsManager` (AdMob interstitials), `AdminConfig` (dev flag).

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
- Theme is applied to the scene via `scene.themeColors`, `scene.themeGridColor`, `scene.themeBackgroundColor`, `scene.themeDotShape`
- Setting `themeDotShape` to `.randomAssets` auto-resolves it to a specific `.asset` on first render

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
- **GameKit** — Game Center leaderboards + achievements via `GameCenterManager`
- **StoreKit 2** — IAP for premium bundle and individual themes via `StoreKitManager`
- **Google Mobile Ads (AdMob)** — interstitial ads via `AdsManager` (guarded by `#if canImport(GoogleMobileAds)`)
- **Firebase Analytics** — event tracking via `FirebaseEventsManager`
- **Firebase Remote Config** — runtime feature flags via `RemoteConfigManager`

## Game Modes

- **Classic**: No time limit, endless rounds
- **Arcade**: Difficulty scales every N points (configurable via Remote Config `arcade_difficulty_step`). Radius shrinks, timing tightens, dot size variation increases.
- **Daily**: Deterministic seed (in progress)

## Theme System

Themes are defined in `Domain/Theme.swift`. There are two unlock mechanisms:

**Score-unlocked themes** (cumulative lifetime score milestones):

| Theme | Unlock | Background | Grid | Dot Shape |
|---|---|---|---|---|
| Neon | Free | `#05060A` | Cyan | circle |
| Forest | 50 pts | `#050D07` | Green | randomAssets (forest_dot, 5 variants) |
| Ocean | 200 pts | `#03080F` | Cyan-blue | randomAssets (ocean_dot, 5 variants) |
| Cosmos | 300 pts | `#080510` | Purple | randomAssets (cosmos_dot, 5 variants) |

**Premium IAP-unlocked themes** (purchase via `StoreKitManager`):

| Theme | Product ID | Background | Grid | Dot Shape |
|---|---|---|---|---|
| Aurora | `…theme.aurora` | dark blue | `#BAE6FD` | randomAssets (aurora_dot, 5 variants) |
| Inferno | `…theme.inferno` | dark red | `#F97316` | asset (flame.fill) |
| DoctorPing | `…premium` | dark blue | `#64B5D9` | asset (DoctorPing) |
| Space Travel | `…premium` | dark teal | `#143d4a` | asset (star.fill) |

### DotShape

```swift
enum DotShape: Equatable {
    case circle
    case asset(named: String, fallbackSymbol: String)
    case randomAssets(prefix: String, count: Int, fallbackSymbol: String)
}
```

- `.circle` — rendered as `SKShapeNode` with additive-blend glow halo
- `.asset(named:fallbackSymbol:)` — tries xcassets PNG first, falls back to SF Symbol tinted as texture
- `.randomAssets(prefix:count:fallbackSymbol:)` — resolved once to a specific `.asset` when assigned to `GameScene.themeDotShape`

### Unlock Rules

- `ThemeID` is a `String`-rawValue `CaseIterable` enum — safe for `@AppStorage` and `Codable`.
- `Theme.name` is `LocalizedStringResource` so `Text(theme.name)` auto-localizes.
- `AppState.currentTheme` is the single source of truth for the active theme.
- `AppState.isUnlocked(theme:)` checks score milestones for free themes and StoreKit entitlements for premium themes.
- `CheckThemeUnlocksUseCase` records cumulative score and returns newly unlocked score-based themes on game over.
- Milestone values can be overridden via Remote Config (`theme_forest_milestone`, etc.).
- `RemoteConfigManager.shared.milestone(for:)` returns `nil` for premium themes (`.aurora`, `.inferno`, `.doctorping`, `.spacetravel`).
- Do not read `theme.unlockScore` for unlock logic — use `RemoteConfigManager.shared.milestone(for:)`.
- Do not gate premium themes on score — check `StoreKitManager.shared.isPurchased(_:)` or `AppState.isUnlocked(theme:)`.

## Firebase Analytics

All events go through `FirebaseEventsManager` (static methods only). `GameOverReason` enum provides typed `reason` parameters (`wrongTap` / `timeUp`).

Key events: `select_game_mode`, `game_over`, `game_ended`, `game_quit`, `round_correct`, `open_themes`, `select_theme`, `theme_unlocked`, `unlock_theme`, `open_store`, `purchase_initiated`, `purchase_completed`, `onboarding_started`, `onboarding_intro_dismissed`, `onboarding_completed`, `onboarding_skipped`, `leaderboard_opened`, `achievements_opened`, `open_settings`, `sound_enabled/disabled`, `haptics_enabled/disabled`, `color_blind_mode_enabled/disabled`.

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

## Monetization

### In-App Purchases (StoreKit 2)

`StoreKitManager.shared` manages all IAP. Product IDs (bundle: `com.optionalsankur.Dotto`):

| Product | ID suffix | Type |
|---|---|---|
| Remove Ads | `removeads` | Non-consumable |
| Aurora Theme | `theme.aurora` | Non-consumable |
| Inferno Theme | `theme.inferno` | Non-consumable |
| Premium Bundle (all) | `premium` | Non-consumable |

- `StoreKitManager.shared.isAdFree` — `true` if `removeads` or `premium` is purchased
- `StoreKitManager.shared.isPurchased(_:)` — check entitlement for any product ID
- DoctorPing and Space Travel themes are included in the `premium` bundle

### Ads (AdMob)

`AdsManager.shared` shows interstitial ads every 3rd game-over, guarded by `StoreKitManager.shared.isAdFree`. Integration requires:
1. SPM package: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`
2. `GADApplicationIdentifier` key in Info.plist
3. Real unit ID in `AdsManager.swift`

Call `AdsManager.shared.recordGameOver()` on both wrong-tap and time-up game-over paths.

## Game Center

`GameCenterManager` handles leaderboards and achievements. There are 12 achievements:

- First dot tapped
- Classic score milestones: 10, 25, 50, 100 pts
- Arcade score milestones: 10, 25, 50 pts
- Theme unlocks: Forest, Ocean, Cosmos
- Play 10 games

## Admin Panel

`AdminConfig.isEnabled` (default `false`) is a compile-time flag in `Tools/AdminConfig.swift`. When `true`, a wrench button appears in the main menu footer, routing to `AdminView` via `.admin` in `AppRoute`. `AdminView` includes gameplay tuning, feature flag overrides, theme milestone overrides, IAP simulation (Premium status), and ad counter controls. **Never ship with `isEnabled = true`.**

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

## Routes

`AppRoute` enum drives all navigation via `RootView`:
- `.mainMenu`
- `.game(GameMode)` — `GameMode`: `.classic`, `.arcade`, `.daily(seed: UInt64)`
- `.settings`
- `.themes`
- `.store` — `PurchaseView` premium purchase sheet
- `.admin` — only reachable when `AdminConfig.isEnabled == true`

## What to Avoid

- Do not add external Swift packages unless asked (AdMob SPM is the one approved exception)
- Do not introduce UIKit navigation (push/present); routing goes through `AppRoute` enum + `RootView`
- Do not add logic to `GameScene`; keep it as a pure rendering/input layer
- Do not break the protocol abstraction in Domain — concrete types belong in Data
- Do not use `UserDefaults` directly; go through a repository protocol
- Do not hardcode game tuning values that belong in Remote Config (time limits, difficulty step, milestones)
- Do not read `theme.unlockScore` for unlock checks — use `RemoteConfigManager.shared.milestone(for:)`
- Do not pass hardcoded colors to `NeonGridBackground` — use the active theme's colors
- Do not gate premium themes on score milestones — use `StoreKitManager.shared.isPurchased(_:)` or `AppState.isUnlocked(theme:)`
- Do not show ads without checking `StoreKitManager.shared.isAdFree` first
- Do not hardcode IAP product IDs inline — reference the constants defined in `StoreKitManager`
