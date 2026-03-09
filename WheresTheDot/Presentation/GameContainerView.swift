//
//  GameContainerView.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import SwiftUI
import SpriteKit

struct GameContainerView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var container: AppContainer
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    let mode: GameMode

    @StateObject private var coordinator: GameCoordinator
    @State private var scene: GameScene?
    @State private var onboardingStep: Int? = nil

    private var onboardingText: LocalizedStringResource? {
        switch onboardingStep {
        case 1:
            return LocalizedStringResource(stringLiteral: "Tap the dot.")
        case 2:
            return LocalizedStringResource(stringLiteral: "A NEW dot was added.\nTap the NEW one.")
        case 3:
            return LocalizedStringResource(stringLiteral: "Now it gets real.\nMiss = Game Over.\nReady?")
        default:
            return nil
        }
    }

    private var buttonKind: DottoButtonStyle.Kind {
        switch mode {
        case .classic:    return .classic
        case .arcade:     return .arcade
        case .timed:      return .timeAttack
        case .daily:      return .classic
        }
    }

    init(mode: GameMode, coordinator: @autoclosure @escaping () -> GameCoordinator) {
        self.mode = mode
        _coordinator = StateObject(wrappedValue: coordinator())
    }

    var body: some View {
        ZStack {

            // =========================
            // SpriteKit layer (bottom)
            // =========================
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .task { setup() }
            }

            hudDisplay
                .allowsHitTesting(false)

            topControls

            // Game Over overlay (separate layer, animated)
            if coordinator.message == "Game Over" || coordinator.message == "Time's up!" {
                gameOverOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
            }

            // Onboarding step-3 modal
            if onboardingStep == 3 {
                onboardingModal
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: coordinator.message)
        .onAppear {
            guard appState.soundEnabled else { return }
            AudioManager.shared.startBackgroundMusic(filename: "gLoop2", ext: "wav")
        }
        .onDisappear {
            guard appState.soundEnabled else { return }
            AudioManager.shared.stopBackgroundMusic()
        }
    }

    var onboardingOverlay: some View {
        VStack {
            Text("Onboarding")
        }
    }
}

private extension GameContainerView {

    // MARK: - HUD

    @MainActor
    private func restartGame() {
        guard let scene else { return }

        let area = CGRect(origin: .zero, size: scene.size).insetBy(dx: 30, dy: 120)

        scene.cancelRoundTimer()
        scene.clearOverlays()

        let firstRound = coordinator.startGame(in: area)
        scene.render(round: firstRound)
        scene.setInputEnabled(true)
        coordinator.message = ""
    }

    // MARK: - Sub-views

    private var hudDisplay: some View {
        VStack {
            HStack {
                Spacer()

                VStack(alignment: .trailing) {
                    Text("Round \(coordinator.roundIndex)")
                    Text("Score \(coordinator.score)")
                }
                .padding(10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            if let text = onboardingText, onboardingStep != 3 {
                Text(text)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 28)
            }
        }
        .padding()
    }

    /// Close button (and optional Skip) pinned to the top-left.
    private var topControls: some View {
        VStack {
            HStack(alignment: .top) {
                Button { appState.goHome() } label: {
                    Image(systemName: "xmark").padding(12)
                }
                .buttonStyle(.borderedProminent)

                if onboardingStep != nil {
                    Button {
                        hasSeenOnboarding = true
                        onboardingStep = nil
                        restartGame()
                    } label: {
                        Text("Skip")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding()

            Spacer()
        }
    }

    /// Full-screen game over overlay with neon styling.
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 36) {

                // Title
                Text("GAME OVER")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dottoDanger)
                    .shadow(color: Color.dottoDanger.opacity(0.75), radius: 20, x: 0, y: 0)

                // Score block
                VStack(spacing: 6) {
                    Text("SCORE")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(.white.opacity(0.45))
                        .kerning(4)

                    Text("\(coordinator.score)")
                        .font(.system(size: 88, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.18), radius: 10, x: 0, y: 0)
                }

                // Action buttons
                VStack(spacing: 14) {
                    Button("Try Again") {
                        restartGame()
                    }
                    .buttonStyle(DottoButtonStyle(kind: buttonKind))
                    .padding(.horizontal, 32)

                    Button("Home") {
                        appState.goHome()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 40)
        }
    }

    /// Onboarding step-3 modal (final confirmation before real game starts).
    private var onboardingModal: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 14) {
                Text("How to Play")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(onboardingText ?? "")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button {
                    hasSeenOnboarding = true
                    onboardingStep = nil
                    restartGame()
                } label: {
                    Text("Start")
                        .frame(maxWidth: 240)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(18)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 24)
        }
    }

    func timeLimit(for score: Int) -> TimeInterval {
        if score <= 6 { return 3.0 }
        if score <= 12 { return 2.0 }
        if score <= 18 { return 1.4 }
        return 1.0
    }

    // MARK: - Setup

    @MainActor
    func setup() {
        func shouldPulseNewDot(forScore score: Int) -> Bool {
            score <= 5
        }
        let coordinator = self.coordinator

        // 2) Create SpriteKit scene
        let scene = GameScene(size: .zero)
        scene.scaleMode = .resizeFill

        // Helper: compute playable area (avoid top HUD + safe-ish margins)
        func playableRect(for sceneSize: CGSize) -> CGRect {
            CGRect(origin: .zero, size: sceneSize)
                .insetBy(dx: 30, dy: 120)
        }

        // 3) Scene is ready (has a non-zero size) -> start game
        scene.onSceneReady = { size in
            let area = playableRect(for: size)

            let firstRound = coordinator.startGame(in: area)
            scene.render(round: firstRound)
            scene.setInputEnabled(true)

            if hasSeenOnboarding == false {
                onboardingStep = 1
                scene.setInputEnabled(true)
                scene.pulseDot(id: firstRound.newDotID)
            } else {
                onboardingStep = nil
                scene.setInputEnabled(true)

                if shouldPulseNewDot(forScore: firstRound.dots.count) {
                    scene.pulseDot(id: firstRound.newDotID)
                }
            }

//            scene.startRoundTimer(seconds: timeLimit(for: firstRound.dots.count)) {
//                // timeout -> game over (treat as wrong)
//                coordinator.message = "Time's up!"
//                scene.setInputEnabled(false)
//                // optional: highlight correct dot if you have it
//            }
        }

        if appState.hapticsEnabled {
            Haptics.prepare()
        }

        scene.onTapFeedback = { [weak appState] in
            guard let appState = appState, appState.hapticsEnabled else { return }
            Haptics.tap()
        }

        // 4) Handle taps
        scene.onDotTapped = { tappedID in
            if onboardingStep != nil {
                handleOnboardingTap(tappedID, scene: scene, playableRect: playableRect, coordinator: coordinator)
                return
            }

            scene.setInputEnabled(false)

            let area = playableRect(for: scene.size)
            let outcome = coordinator.handleTap(tappedID, in: area)

            switch outcome {
            case .correct(let nextRound):
                if appState.hapticsEnabled { Haptics.correct() }
                let score = nextRound.dots.count

                let coverDuration: TimeInterval = {
                    if score <= 5 { return 0.45 }
                    if score <= 12 { return 0.65 }
                    return 0.65
                }()

                scene.showMemoryCover(duration: coverDuration)

                Task { @MainActor in
                    let totalDelay = coverDuration + 0.18
                    try? await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))

                    scene.render(round: nextRound)
                    if let newNode = scene.dotNode(id: nextRound.newDotID) {
                        let color = UIColor.neonCyan
                        scene.spawnCorrectBurst(at: newNode.position, color: color)
                    }
                    if shouldPulseNewDot(forScore: nextRound.dots.count) {
                        scene.pulseDot(id: nextRound.newDotID)
                    }
                    scene.setInputEnabled(true)

//                    scene.startRoundTimer(seconds: timeLimit(for: nextRound.dots.count)) {
//                        coordinator.message = "Time's up!"
//                        scene.setInputEnabled(false)
//                    }
                }

            case .wrong(_, let correctDotID):
                if appState.hapticsEnabled { Haptics.gameOver() }
                scene.cancelRoundTimer()
                scene.clearOverlays()
                scene.showWrongFlash()
                scene.showWrongFeedback()
                scene.showOutcome(.wrong(chosenID: tappedID, newDotID: correctDotID))
                scene.setInputEnabled(false)
            }
        }

        // 5) Store references so SwiftUI can render + observe
        self.scene = scene
    }

    @MainActor
    private func handleOnboardingTap(
        _ tappedID: UUID,
        scene: GameScene,
        playableRect: (CGSize) -> CGRect,
        coordinator: GameCoordinator
    ) {
        scene.setInputEnabled(false)

        let area = playableRect(scene.size)
        let outcome = coordinator.handleTap(tappedID, in: area)

        switch outcome {
        case .correct(let nextRound):
            let cover: TimeInterval = (onboardingStep == 1) ? 0.35 : 0.45
            scene.showMemoryCover(duration: cover)

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64((cover + 0.18) * 1_000_000_000))

                scene.render(round: nextRound)
                scene.pulseDot(id: nextRound.newDotID)
                scene.setInputEnabled(true)

                if onboardingStep == 1 { onboardingStep = 2 }
                else if onboardingStep == 2 {
                    onboardingStep = 3
                    scene.setInputEnabled(false)
                }
            }

        case .wrong(_, let correctID):
            scene.showWrongFeedback()
            scene.showOutcome(.wrong(chosenID: tappedID, newDotID: correctID))
            coordinator.message = "Try again!"
            scene.setInputEnabled(true)
        }
    }
}
