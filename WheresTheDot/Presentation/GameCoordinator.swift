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
    private let progression: LevelProgression?
    private var gameStartedAt: Date?

    init(mode: GameMode = .classic,
         start: StartGameUseCase,
         addIfCorrect: AddDotIfCorrectUseCase,
         progression: LevelProgression? = nil) {
        self.mode = mode
        self.start = start
        self.addIfCorrect = addIfCorrect
        self.progression = progression
    }

    func startGame(in area: CGRect) -> Round {
        let round = start(in: area)
        roundIndex = round.index
        score = round.dots.count
        message = ""
        currentLevel = 1
        showLevelUp = false
        gameStartedAt = Date()
        if let p = progression {
            timeLimitForRound = p.difficulty(for: 1).timeLimit
        }
        return round
    }

    func handleTap(_ id: UUID, in area: CGRect) -> TapOutcome {
        let outcome = addIfCorrect(tapped: id, in: area)
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
            message = "Game Over"
            timeLimitForRound = nil
            let duration = gameStartedAt.map { Date().timeIntervalSince($0) } ?? 0
            FirebaseEventsManager.logGameEnded(duration: duration, score: gameOverScore, mode: mode)
            GameCenterManager.shared.submitScore(gameOverScore, for: mode)
            gameStartedAt = nil
        }
        return outcome
    }
}
