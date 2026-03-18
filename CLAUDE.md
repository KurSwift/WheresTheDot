# WheresTheDot — Claude Code Instructions

## Project Overview

"Where's The Dot" is a casual iOS memory game built with Swift. Players must remember and tap the newest dot added to the screen each round. A wrong tap ends the game. Score equals the number of dots successfully identified.

## Architecture

Clean Architecture with strict layer separation:

```
WheresTheDot/
├── Domain/          # Entities, protocols, core business rules
├── Data/            # Concrete implementations (repositories, adapters)
├── Use Cases/       # Orchestrators between domain and presentation
├── Presentation/    # SwiftUI views, coordinators, state
│   ├── AnimatedDots/
│   ├── Components/
│   ├── Routes/
│   └── View Models/
├── Tools/           # Cross-cutting concerns (audio, haptics)
├── Utils/           # Extensions
├── GameScene.swift  # SpriteKit scene (rendering + touch input)
├── AppDelegate.swift
└── WheresTheDot.swift  # @main entry point
```

### Layer Responsibilities

- **Domain**: Immutable value types (`Dot`, `Round`, `GameSnapshot`, `Difficulty`), enums (`GameMode`, `RoundOutcome`, `PlayerAction`), and protocols (`DotLayoutGenerating`, `GameSessionRepository`, `LevelProgression`, `RandomNumberGenerating`).
- **Data**: Concrete implementations — `InMemoryGameSessionRepository`, `GKRandomAdapter` (wraps GameplayKit), `DotLayoutGenerator`, `SimpleArcadeProgression`.
- **Use Cases**: Callable structs (`StartGameUseCase`, `AddDotIfCorrectUseCase`). Call with `useCase(args)` not `useCase.execute(args)`.
- **Presentation**: `AppState` (navigation + settings), `GameCoordinator` (game flow), `AppContainer` (DI root).
- **Tools**: `AudioManager` (singleton, background music), `Haptics` (enum with static methods).

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
- **No external packages** — purely Apple frameworks

## Game Modes

- **Classic**: No time limit, endless rounds
- **Arcade**: Difficulty curve scales every 5 points (radius shrinks, timing tightens)
- **Timed**: Per-round time limit decreasing with score
- **Daily**: Deterministic seed (in progress)

## Visual Design

**Color palette** (`Color+Extensions.swift`):
- Neons: cyan, magenta, purple, lime, yellow, coral, orange, pink
- Background: `#05060A` (black), `#0B1220` (card dark)
- States: lime = success, red = danger

**Visual conventions:**
- Additive blend mode for glow/neon effects in SpriteKit
- `NeonGridBackground` (Canvas-based, not SpriteKit) for menu backgrounds
- `DottoButtonStyle` for all primary buttons — gradient capsule with glossy overlay
- Glass/material overlays for settings and modals

## Concurrency

- `@MainActor` on `AppState`, `AppContainer`, `GameCoordinator`, `AudioManager`, `Haptics`
- Use `Task { @MainActor in ... }` when bridging from non-actor contexts
- SpriteKit callbacks call back onto main thread via closures

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
