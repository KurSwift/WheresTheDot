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

            controlsOverlay
            
            if onboardingStep == 3 {
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
                            // Finish onboarding and restart real game fresh
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
        }
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

    private var controlsOverlay: some View {
        VStack {
            HStack {
                Button { appState.goHome() } label: {
                    Image(systemName: "xmark").padding(12)
                }
                .buttonStyle(.borderedProminent)
                if onboardingStep != nil {
                    Button {
                        // Skip onboarding and start real game
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

            if coordinator.message == "Game Over" || coordinator.message == "Time’s up!" {
                ZStack {
                    // Dim background
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()

                    VStack(spacing: 14) {
                        Text(coordinator.message)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Final score: \(coordinator.score)")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Button {
                            restartGame()
                        } label: {
                            Text("Play Again")
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
//                coordinator.message = "Time’s up!"
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
            // Add haptics
            
            
            if onboardingStep != nil {
                handleOnboardingTap(tappedID, scene: scene, playableRect: playableRect, coordinator: coordinator)
                return
            }
            
            scene.setInputEnabled(false)
            

            let area = playableRect(for: scene.size)
            let outcome = coordinator.handleTap(tappedID, in: area)

            switch outcome {
            case .correct(let nextRound):
                // Difficulty: cover screen duration can depend on score
                if appState.hapticsEnabled { Haptics.correct() }
                let score = nextRound.dots.count

                // Example curve:
                // 1–5 dots: 0.25s
                // 6–12 dots: 0.45s
                // 13+: 0.65s
                let coverDuration: TimeInterval = {
                    if score <= 5 { return 0.45 }
                    if score <= 12 { return 0.65 }
                    return 0.65
                }()

                // Show cover
                scene.showMemoryCover(duration: coverDuration)

                // Render next round AFTER the cover (so it truly hides the update)
                Task { @MainActor in
                    let totalDelay = coverDuration + 0.18 // includes fade timings
                    try? await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))

                    scene.render(round: nextRound)
                    if let newNode = scene.dotNode(id: nextRound.newDotID) {
                        let color = UIColor.neonCyan // or arcadeColor(nextRound.dots.count) if you expose it
                        scene.spawnCorrectBurst(at: newNode.position, color: color)
                    }
                    if shouldPulseNewDot(forScore: nextRound.dots.count) {
                        scene.pulseDot(id: nextRound.newDotID)
                    }
                    scene.setInputEnabled(true)

//                    scene.startRoundTimer(seconds: timeLimit(for: nextRound.dots.count)) {
//                        coordinator.message = "Time’s up!"
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
            // In onboarding we want to demonstrate the cover screen
            let cover: TimeInterval = (onboardingStep == 1) ? 0.35 : 0.45
            scene.showMemoryCover(duration: cover)

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64((cover + 0.18) * 1_000_000_000))

                scene.render(round: nextRound)
                scene.pulseDot(id: nextRound.newDotID) // always pulse during onboarding
                scene.setInputEnabled(true)

                // Advance tutorial steps
                if onboardingStep == 1 { onboardingStep = 2 }
                else if onboardingStep == 2 {
                    onboardingStep = 3
                    // Step 3 is modal; stop input until they press Start
                    scene.setInputEnabled(false)
                }
            }

        case .wrong(_, let correctID):
            // Ideally shouldn't happen in onboarding, but keep it friendly
            scene.showWrongFeedback()
            scene.showOutcome(.wrong(chosenID: tappedID, newDotID: correctID))
            coordinator.message = "Try again!"
            scene.setInputEnabled(true)
        }
    }
}
