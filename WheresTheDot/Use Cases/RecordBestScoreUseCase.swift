//
//  RecordBestScoreUseCase.swift
//  WheresTheDot
//

import Foundation

struct BestScoreResult: Equatable {
    let best: Int
    let previousBest: Int

    var isNewBest: Bool { best > previousBest }
}

/// Saves the score if it beats the personal best for the mode and reports the outcome.
struct RecordBestScoreUseCase {
    let repo: ScoreRepository

    func callAsFunction(score: Int, mode: GameMode) -> BestScoreResult {
        let previous = repo.bestScore(for: mode)
        if score > previous { repo.setBestScore(score, for: mode) }
        return BestScoreResult(best: max(score, previous), previousBest: previous)
    }
}
