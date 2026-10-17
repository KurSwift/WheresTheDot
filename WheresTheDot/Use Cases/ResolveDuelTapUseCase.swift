//
//  ResolveDuelTapUseCase.swift
//  WheresTheDot
//

import Foundation
import CoreGraphics

struct DuelTapResult: Equatable {
    let scorer: DuelPlayer
    let wasCorrect: Bool
    let correctDotID: UUID
    let score: DuelScore
    /// The next board, or `nil` when this point won the match.
    let nextRound: Round?
}

/// Duel rules: the first player to tap the newest dot scores; tapping any other dot
/// gives the point to the rival. Either way the board grows by one dot, until someone
/// reaches the target score.
struct ResolveDuelTapUseCase {
    let repo: GameSessionRepository
    let addDot: AddDotIfCorrectUseCase

    func callAsFunction(tapped id: UUID, by player: DuelPlayer, score: DuelScore,
                        in area: CGRect, avoiding blocked: [CGRect] = []) -> DuelTapResult? {
        let snap = repo.load()
        guard !snap.isGameOver, let newID = snap.newDotID, score.winner == nil else { return nil }

        let wasCorrect = id == newID
        let scorer = wasCorrect ? player : player.rival
        var score = score
        score.award(scorer)

        var nextRound: Round?
        if score.winner == nil,
           // Tapping the newest dot on the scorer's behalf adds the next dot to the shared board
           case .correct(let next) = addDot(tapped: newID, in: area, avoiding: blocked) {
            nextRound = next
        }
        return DuelTapResult(scorer: scorer, wasCorrect: wasCorrect, correctDotID: newID,
                             score: score, nextRound: nextRound)
    }
}
