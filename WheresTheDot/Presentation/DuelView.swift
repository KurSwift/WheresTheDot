//
//  DuelView.swift
//  WheresTheDot
//

import SwiftUI
import SpriteKit
import GameKit

/// Two players, one device: each half of the screen shows the same board, rotated to face
/// the player at that edge. First to tap the newest dot scores; a wrong dot scores for the rival.
struct DuelView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var coordinator: DuelCoordinator
    @State private var scene: GameScene?
    @State private var layout: DuelBoardLayout?
    @State private var phase: Phase = .countdown(3)

    private enum Phase: Equatable {
        case countdown(Int)
        case playing
        case finished(winner: DuelPlayer)
    }

    init() {
        _coordinator = StateObject(wrappedValue: DuelCoordinator(
            target: RemoteConfigManager.shared.duelTargetScore,
            container: AppContainer()
        ))
    }

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea(edges: .vertical)
                    .background(appState.currentTheme.backgroundColor.ignoresSafeArea())
            } else {
                ProgressView()
                    .task { setup() }
            }

            if let layout {
                halves(layout)
                closeButton(layout)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: phase)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: coordinator.score)
        .onAppear {
            GKAccessPoint.shared.isActive = false
            guard appState.soundEnabled else { return }
            AudioManager.shared.startBackgroundMusic(filename: "gLoop2", ext: "wav")
        }
        .onDisappear {
            GKAccessPoint.shared.isActive = GameCenterManager.shared.isAuthenticated
            guard appState.soundEnabled else { return }
            AudioManager.shared.stopBackgroundMusic()
        }
    }
}

private extension DuelView {

    // MARK: - Overlay

    /// One half per player, each rotated so its top edge points at the split line.
    func halves(_ layout: DuelBoardLayout) -> some View {
        let stack = layout.sideBySide ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        return stack {
            if layout.sideBySide {
                half(for: .one).facing(degrees: 90)
                half(for: .two).facing(degrees: -90)
            } else {
                half(for: .two).facing(degrees: 180)
                half(for: .one).facing(degrees: 0)
            }
        }
        // The halves must match the scene's halves, which never mirror for right-to-left languages
        .environment(\.layoutDirection, .leftToRight)
        .ignoresSafeArea(edges: .vertical)
    }

    func half(for player: DuelPlayer) -> some View {
        VStack(spacing: 0) {
            scoreboard(for: player)
                .padding(.top, 12)
                .allowsHitTesting(false)
            Spacer(minLength: 0)
            switch phase {
            case .countdown(let n):
                countdown(n)
                    .allowsHitTesting(false)
            case .playing:
                EmptyView()
            case .finished(let winner):
                result(won: winner == player)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if case .finished = phase {
                Color.black.opacity(0.7)
            }
        }
    }

    func scoreboard(for player: DuelPlayer) -> some View {
        let score = coordinator.score
        return VStack(spacing: 2) {
            HStack(spacing: 10) {
                Text("\(score.points(for: player))")
                    .foregroundStyle(color(for: player))
                    .shadow(color: color(for: player).opacity(0.8), radius: 8)
                Text(verbatim: "–")
                    .foregroundStyle(.white.opacity(0.4))
                Text("\(score.points(for: player.rival))")
                    .foregroundStyle(color(for: player.rival).opacity(0.7))
            }
            .font(.system(size: 26, weight: .black, design: .rounded))
            .contentTransition(.numericText())

            Text("First to \(score.target)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .kerning(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(color(for: player).opacity(0.4), lineWidth: 1))
    }

    func countdown(_ n: Int) -> some View {
        VStack(spacing: 12) {
            Text("\(n)")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
            Text("Tap the NEW dot before your rival.\nWrong dot = point for your rival.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    func result(won: Bool) -> some View {
        VStack(spacing: 14) {
            Text(won ? "YOU WIN!" : "YOU LOSE")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(won ? Color.neonLime : .white.opacity(0.6))
                .shadow(color: won ? Color.neonLime.opacity(0.7) : .clear, radius: 14)

            Button("Rematch") { beginCountdown() }
                .buttonStyle(DottoButtonStyle(kind: .duel))
                .frame(maxWidth: 260)

            Button("Home") { appState.goHome() }
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.vertical, 6)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    /// Sits in the scoreboard band along the split, clear of both boards.
    func closeButton(_ layout: DuelBoardLayout) -> some View {
        Button {
            coordinator.quit()
            appState.goHome()
        } label: {
            Image(systemName: "xmark").padding(8)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Close")
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: layout.sideBySide ? .top : .leading)
    }

    func color(for player: DuelPlayer) -> Color {
        switch (player, appState.colorBlindMode) {
        case (.one, false): return .neonCyan
        case (.two, false): return .neonPink
        case (.one, true):  return .accessibleBlue
        case (.two, true):  return .accessibleAmber
        }
    }

    // MARK: - Flow

    func setup() {
        let scene = GameScene(size: .zero)
        scene.scaleMode = .resizeFill
        scene.mirrorsBoard = true
        scene.colorBlindMode = appState.colorBlindMode
        scene.themeDotShape = appState.currentTheme.dotShape
        scene.themeColors = appState.currentTheme.dotColors
        scene.themeGridColor = UIColor(appState.currentTheme.gridColor)
        scene.themeBackgroundColor = UIColor(appState.currentTheme.backgroundColor)

        scene.onSceneReady = { size in
            layout = DuelBoardLayout(size: size, fold: scene.foldFrame)
            beginCountdown()
        }

        // Fold/unfold or window resize mid-match: re-fit the board into the new halves
        scene.onSizeChanged = { _, newSize in
            let new = DuelBoardLayout(size: newSize, fold: scene.foldFrame)
            defer { layout = new }
            guard let old = layout, let round = coordinator.relayoutBoard(
                from: old.playerOneArea, to: new.playerOneArea, avoiding: new.blocked(scene.reservedRects)
            ), phase == .playing else { return }
            scene.render(round: round)
        }

        if appState.hapticsEnabled { Haptics.prepare() }
        scene.onTapFeedback = { [weak appState] in
            guard let appState, appState.hapticsEnabled else { return }
            Haptics.tap()
        }
        scene.onDotTappedAt = { id, point in handleTap(id, at: point) }

        self.scene = scene
    }

    func beginCountdown() {
        guard let scene else { return }
        scene.setInputEnabled(false)
        scene.clearOverlays()
        let steps = 3
        let step: TimeInterval = 0.8
        // Hides the previous board during a rematch countdown
        scene.showMemoryCover(duration: Double(steps) * step)
        phase = .countdown(steps)

        Task { @MainActor in
            for n in stride(from: steps - 1, through: 1, by: -1) {
                try? await Task.sleep(for: .seconds(step))
                phase = .countdown(n)
            }
            try? await Task.sleep(for: .seconds(step))
            guard let layout else { return }
            let round = coordinator.startMatch(in: layout.playerOneArea, avoiding: layout.blocked(scene.reservedRects))
            phase = .playing
            let animDuration = scene.render(round: round)
            try? await Task.sleep(for: .seconds(animDuration))
            scene.setInputEnabled(true)
        }
    }

    func handleTap(_ id: UUID, at point: CGPoint) {
        guard let scene, let layout, phase == .playing else { return }
        scene.setInputEnabled(false)

        let player = layout.player(at: point)
        guard let result = coordinator.handleTap(
            id, by: player, in: layout.playerOneArea, avoiding: layout.blocked(scene.reservedRects)
        ) else { return }

        if result.wasCorrect {
            if appState.hapticsEnabled { Haptics.correct() }
            scene.spawnCorrectBurst(at: point, color: UIColor(color(for: player)))
        } else {
            if appState.hapticsEnabled { Haptics.gameOver() }
            scene.showWrongFeedback()
        }
        scene.showOutcome(.correct(newDotID: result.correctDotID))

        Task { @MainActor in
            guard let next = result.nextRound else {
                try? await Task.sleep(for: .seconds(0.6))
                if let winner = result.score.winner { phase = .finished(winner: winner) }
                AdsManager.shared.recordGameOver()
                return
            }
            let cover = RemoteConfigManager.shared.memoryCoverDuration
            try? await Task.sleep(for: .seconds(0.3))
            scene.showMemoryCover(duration: cover)
            try? await Task.sleep(for: .seconds(cover + 0.18))
            guard phase == .playing else { return }
            let animDuration = scene.render(round: next)
            try? await Task.sleep(for: .seconds(animDuration))
            scene.setInputEnabled(true)
        }
    }
}

private extension View {
    /// Rotates a view to face a player at another edge, keeping it sized to its slot.
    func facing(degrees: Double) -> some View {
        GeometryReader { geo in
            let quarterTurn = abs(degrees) == 90
            self
                .frame(width: quarterTurn ? geo.size.height : geo.size.width,
                       height: quarterTurn ? geo.size.width : geo.size.height)
                .rotationEffect(.degrees(degrees))
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
