//
//  GameCoordinator.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import CoreGraphics
internal import Combine

@MainActor
final class GameCoordinator: ObservableObject {
    @Published var roundIndex: Int = 0
    @Published var score: Int = 0
    @Published var message: String = ""

    // Arcade-specific state
    @Published var currentLevel: Int = 1
    @Published var showLevelUp: Bool = false
    @Published var timeLimitForRound: TimeInterval? = nil

    let mode: GameMode
    let start: StartGameUseCase
    private let addIfCorrect: AddDotIfCorrectUseCase
    private let relayout: RelayoutDotsUseCase
    private let progression: LevelProgression?
    private var gameStartedAt: Date?

    init(mode: GameMode = .classic,
         start: StartGameUseCase,
         addIfCorrect: AddDotIfCorrectUseCase,
         relayout: RelayoutDotsUseCase,
         progression: LevelProgression? = nil) {
        self.mode = mode
        self.start = start
        self.addIfCorrect = addIfCorrect
        self.relayout = relayout
        self.progression = progression
    }

    func startGame(in area: CGRect, avoiding blocked: [CGRect] = []) -> Round {
        var round = start(in: area, avoiding: blocked)
        #if DEBUG
        for _ in 1..<ScreenshotSetup.prefilledDots {
            if case .correct(let next) = addIfCorrect(tapped: round.newDotID, in: area, avoiding: blocked) { round = next }
        }
        #endif
        roundIndex = round.index
        score = round.dots.count
        message = ""
        currentLevel = progression?.state(forScore: score).level ?? 1
        showLevelUp = false
        gameStartedAt = Date()
        if let p = progression {
            timeLimitForRound = p.difficulty(for: currentLevel).timeLimit
        }
        return round
    }

    func handleTap(_ id: UUID, in area: CGRect, avoiding blocked: [CGRect] = []) -> TapOutcome {
        let outcome = addIfCorrect(tapped: id, in: area, avoiding: blocked)
        switch outcome {
        case .correct(let nextRound):
            let newScore = nextRound.dots.count
            roundIndex = nextRound.index
            score = newScore
            message = ""

            if let p = progression {
                let newLevel = p.state(forScore: newScore).level
                timeLimitForRound = p.difficulty(for: newLevel).timeLimit
                if newLevel > currentLevel {
                    currentLevel = newLevel
                    showLevelUp = true
                }
            }

        case .wrong(let gameOverScore, _):
            score = gameOverScore
            finishGame(message: "Game Over")
        }
        return outcome
    }

    /// Re-fits the current board after the window changes size (fold/unfold, iPad resize).
    func relayoutBoard(from old: CGRect, to new: CGRect, avoiding blocked: [CGRect] = []) -> Round? {
        relayout(from: old, to: new, avoiding: blocked)
    }

    /// Arcade timer ran out: ends the game with the current score.
    func timeUp() {
        finishGame(message: "Time's up!")
    }

    private func finishGame(message: String) {
        self.message = message
        timeLimitForRound = nil
        let duration = gameStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        FirebaseEventsManager.logGameEnded(duration: duration, score: score, mode: mode)
        GameCenterManager.shared.submitScore(score, for: mode)
        GameCenterManager.shared.reportScoreAchievements(score: score, mode: mode)
        GameCenterManager.shared.trackGamePlayed()
        gameStartedAt = nil
    }
}
