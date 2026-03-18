//
//  AddDotIfCorrectUseCase.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import CoreGraphics

enum TapOutcome: Equatable {
    case correct(nextRound: Round)
    case wrong(gameOverScore: Int, correctDotID: UUID)
}

struct AddDotIfCorrectUseCase {
    let repo: GameSessionRepository
    let layout: DotLayoutGenerating
    var progression: LevelProgression? = nil

    func callAsFunction(tapped id: UUID, in area: CGRect) -> TapOutcome {
        var snap = repo.load()

        let baseRadius = snap.radius
        let jitter = CGFloat.random(in: -2...2)
        let newRadius = max(8, baseRadius + jitter)

        guard !snap.isGameOver, let newID = snap.newDotID else {
            return .wrong(gameOverScore: snap.score, correctDotID: snap.newDotID ?? id)
        }

        // Wrong tap ends the game
        guard id == newID else {
            snap.isGameOver = true
            repo.save(snap)
            return .wrong(gameOverScore: snap.score, correctDotID: newID)
        }

        // Correct tap: add one new dot
        let existingPositions = snap.dots.map(\.position)
        let newPos = layout.generateNewPosition(
            existing: existingPositions,
            in: area,
            radius: snap.radius,
            minDistance: snap.minDistance
        ) ?? CGPoint(x: area.midX, y: area.midY)

        let newDot = Dot(id: UUID(), position: newPos, radius: newRadius)

        snap.roundIndex += 1
        snap.dots.append(newDot)
        snap.newDotID = newDot.id

        // Scale difficulty for arcade progression
        if let progression {
            let newScore = snap.dots.count
            let levelState = progression.state(forScore: newScore)
            let difficulty = progression.difficulty(for: levelState.level)
            snap.radius = difficulty.radius
            snap.minDistance = difficulty.minDistance
            snap.level = levelState
            snap.difficulty = difficulty
        }

        repo.save(snap)

        let round = Round(index: snap.roundIndex, dots: snap.dots, newDotID: newDot.id)
        return .correct(nextRound: round)
    }
}
