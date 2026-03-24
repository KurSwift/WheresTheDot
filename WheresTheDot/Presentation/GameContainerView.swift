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
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    let mode: GameMode

    @StateObject private var coordinator: GameCoordinator
    @State private var scene: GameScene?
    @State private var onboardingStep: Int? = nil

    // Arcade timer bar
    @State private var timerBarStart: Date? = nil

    private var onboardingText: LocalizedStringResource? {
        switch onboardingStep {
        case 1:
            return LocalizedStringResource(stringLiteral: "Tap the dot.")
        case 2:
            return LocalizedStringResource(stringLiteral: "A NEW dot was added.\nTap the NEW one.")
        case 3:
            return LocalizedStringResource(stringLiteral: "Keep going.\nCan you find the new dot?")
        case 4:
            return LocalizedStringResource(stringLiteral: "Another one!\nKeep going.")
        case 5:
            return LocalizedStringResource(stringLiteral: "Now it gets real.\nMiss = Game Over.\nReady?")
        default:
            return nil
        }
    }

    private var buttonKind: DottoButtonStyle.Kind {
        switch mode {
        case .classic:    return .classic
        case .arcade:     return .arcade
        case .daily:      return .classic
        }
    }

    init(mode: GameMode) {
        self.mode = mode
        let container = AppContainer(mode: mode)
        _coordinator = StateObject(wrappedValue: GameCoordinator(
            mode: mode,
            start: container.startGame,
            addIfCorrect: container.addDotIfCorrect,
            progression: container.progression
        ))
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

            // Arcade timer bar — full-width strip at very top
            if mode == .arcade, timerBarStart != nil {
                arcadeTimerBar
                    .allowsHitTesting(false)
            }

            hudDisplay
                .allowsHitTesting(false)

            topControls

            // Level-up banner (arcade only) — floats at top, non-blocking
            if coordinator.showLevelUp {
                levelUpBanner
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .allowsHitTesting(false)
            }

            // Game Over overlay (separate layer, animated)
            if coordinator.message == "Game Over" || coordinator.message == "Time's up!" {
                gameOverOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
            }

            // Onboarding step-5 modal
            if onboardingStep == 5 {
                onboardingModal
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: coordinator.message)
        .animation(.easeInOut(duration: 0.25), value: coordinator.showLevelUp)
        .onChange(of: appState.colorBlindMode) { _, newValue in
            scene?.colorBlindMode = newValue
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

    // MARK: - Arcade timer bar

    private var arcadeTimerBar: some View {
        VStack {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                let progress = arcadeTimerProgress(at: context.date)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                        Rectangle()
                            .fill(timerBarColor(progress))
                            .frame(width: geo.size.width * progress)
                            .shadow(color: timerBarColor(progress).opacity(0.8), radius: 6, y: 0)
                    }
                }
                .frame(height: 4)
            }
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }

    private func arcadeTimerProgress(at date: Date) -> CGFloat {
        guard let start = timerBarStart,
              let limit = coordinator.timeLimitForRound,
              limit > 0 else { return 1.0 }
        let elapsed = date.timeIntervalSince(start)
        return max(0, CGFloat(1.0 - elapsed / limit))
    }

    private func timerBarColor(_ progress: CGFloat) -> Color {
        if appState.colorBlindMode {
            if progress > 0.5 { return .accessibleBlue }
            if progress > 0.25 { return .accessibleAmber }
            return .accessibleDanger
        }
        if progress > 0.5 { return .neonCyan }
        if progress > 0.25 { return .neonOrange }
        return .dottoDanger
    }

    // MARK: - Level-up banner

    private var levelUpLevelColor: Color {
        if appState.colorBlindMode {
            let colors: [Color] = [.accessibleBlue, .accessibleAmber, .accessibleTeal, .accessibleYellow, .accessibleLavender]
            return colors[(coordinator.currentLevel - 1) % colors.count]
        }
        let colors: [Color] = [.neonCyan, .neonPink, .neonPurple, .neonLime, .neonOrange]
        return colors[(coordinator.currentLevel - 1) % colors.count]
    }

    /// Small floating pill that slides in from the top and auto-dismisses.
    /// Does not block the dot field or game input.
    private var levelUpBanner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(levelUpLevelColor.opacity(0.45))
                    .frame(width: 18, height: 1)
                Text("LEVEL \(coordinator.currentLevel)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(levelUpLevelColor)
                    .shadow(color: levelUpLevelColor.opacity(0.9), radius: 10)
                    .kerning(4)
                Rectangle()
                    .fill(levelUpLevelColor.opacity(0.45))
                    .frame(width: 18, height: 1)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(levelUpLevelColor.opacity(0.35), lineWidth: 1))
            .padding(.top, 96)

            Spacer()
        }
    }

    // MARK: - HUD

    @MainActor
    private func restartGame() {
        guard let scene else { return }

        let area = CGRect(origin: .zero, size: scene.size).insetBy(dx: 30, dy: 120)

        scene.cancelRoundTimer()
        scene.clearOverlays()
        timerBarStart = nil

        let firstRound = coordinator.startGame(in: area)
        scene.render(round: firstRound)
        scene.setInputEnabled(true)
        coordinator.message = ""

        if mode == .arcade, let limit = coordinator.timeLimitForRound {
            timerBarStart = Date()
            scene.startRoundTimer(seconds: limit) {
                coordinator.message = "Time's up!"
                scene.setInputEnabled(false)
                timerBarStart = nil
            }
        }
    }

    // MARK: - Sub-views

    private var hudDisplay: some View {
        VStack {
            HStack {
                Spacer()

                if mode == .arcade {
                    arcadeHUD
                } else {
                    classicHUD
                }
            }

            Spacer()

            if let text = onboardingText, onboardingStep != 5 {
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

    private var classicHUD: some View {
        VStack(alignment: .trailing) {
            Text("Round \(coordinator.roundIndex)")
            Text("Score \(coordinator.score)")
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var arcadeHUD: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("LVL \(coordinator.currentLevel)")
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundStyle(levelUpLevelColor)
                .shadow(color: levelUpLevelColor.opacity(0.7), radius: 6)
            Text("SCORE  \(coordinator.score)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
                .kerning(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36, weight: .black))
                    Text("GAME OVER")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                }
                .foregroundStyle(appState.colorBlindMode ? Color.accessibleDanger : Color.dottoDanger)
                .shadow(color: (appState.colorBlindMode ? Color.accessibleDanger : Color.dottoDanger).opacity(0.75), radius: 20, x: 0, y: 0)

                // Score block
                VStack(spacing: 6) {
                    if mode == .arcade {
                        Text("LVL \(coordinator.currentLevel)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(levelUpLevelColor.opacity(0.8))
                            .kerning(3)
                    }

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

    // MARK: - Setup

    @MainActor
    func setup() {
        func shouldPulseNewDot(forScore score: Int) -> Bool {
            score <= 5
        }
        let coordinator = self.coordinator

        // Create SpriteKit scene
        let scene = GameScene(size: .zero)
        scene.scaleMode = .resizeFill
        scene.colorBlindMode = appState.colorBlindMode

        func playableRect(for sceneSize: CGSize) -> CGRect {
            CGRect(origin: .zero, size: sceneSize)
                .insetBy(dx: 30, dy: 120)
        }

        func startArcadeTimer(limit: TimeInterval) {
            timerBarStart = Date()
            scene.startRoundTimer(seconds: limit) {
                coordinator.message = "Time's up!"
                scene.setInputEnabled(false)
                timerBarStart = nil
            }
        }

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

                if mode == .arcade, let limit = coordinator.timeLimitForRound {
                    startArcadeTimer(limit: limit)
                }
            }
        }

        if appState.hapticsEnabled {
            Haptics.prepare()
        }

        scene.onTapFeedback = { [weak appState] in
            guard let appState = appState, appState.hapticsEnabled else { return }
            Haptics.tap()
        }

        // Handle taps
        scene.onDotTapped = { tappedID in
            if onboardingStep != nil {
                handleOnboardingTap(tappedID, scene: scene, playableRect: playableRect, coordinator: coordinator)
                return
            }

            scene.setInputEnabled(false)
            scene.cancelRoundTimer()
            timerBarStart = nil

            let area = playableRect(for: scene.size)
            let outcome = coordinator.handleTap(tappedID, in: area)

            switch outcome {
            case .correct(let nextRound):
                if appState.hapticsEnabled { Haptics.correct() }
                let score = nextRound.dots.count

                let coverDuration: TimeInterval = {
                    if score <= 5  { return 0.45 }
                    if score <= 12 { return 0.65 }
                    return 0.65
                }()

                scene.showMemoryCover(duration: coverDuration)

                Task { @MainActor in
                    let totalDelay = coverDuration + 0.18
                    try? await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))

                    scene.render(round: nextRound)
                    if let newNode = scene.dotNode(id: nextRound.newDotID) {
                        let colors: [UIColor] = appState.colorBlindMode
                            ? [.accessibleBlue, .accessibleAmber, .accessibleTeal, .accessibleYellow, .accessibleLavender]
                            : [.neonCyan, .neonPink, .neonPurple, .neonLime, .neonOrange]
                        let burstColor = colors[(max(1, score) - 1) % colors.count]
                        scene.spawnCorrectBurst(at: newNode.position, color: burstColor)
                    }

                    let isLevelUp = coordinator.showLevelUp
                    if isLevelUp {
                        let levelColors: [UIColor] = appState.colorBlindMode
                            ? [.accessibleBlue, .accessibleAmber, .accessibleTeal, .accessibleYellow, .accessibleLavender]
                            : [.neonCyan, .neonPink, .neonPurple, .neonLime, .neonOrange]
                        let levelColor = levelColors[(coordinator.currentLevel - 1) % levelColors.count]
                        scene.flashLevelUp(color: levelColor)
                        scene.spawnLevelUpNewDot(id: nextRound.newDotID, color: levelColor)
                        // Dismiss banner non-blocking — game resumes immediately
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            coordinator.showLevelUp = false
                        }
                    } else if shouldPulseNewDot(forScore: nextRound.dots.count) {
                        scene.pulseDot(id: nextRound.newDotID)
                    }

                    scene.setInputEnabled(true)

                    if mode == .arcade, let limit = coordinator.timeLimitForRound {
                        startArcadeTimer(limit: limit)
                    }
                }

            case .wrong(_, let correctDotID):
                if appState.hapticsEnabled { Haptics.gameOver() }
                scene.cancelRoundTimer()
                scene.clearOverlays()
                scene.showWrongFlash()
                scene.showWrongFeedback()
                scene.showOutcome(.wrong(chosenID: tappedID, newDotID: correctDotID))
                scene.setInputEnabled(false)
                timerBarStart = nil
            }
        }

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

                if let step = onboardingStep, step < 4 {
                    onboardingStep! += 1
                }
                else if onboardingStep == 4 {
                    onboardingStep = 5
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
