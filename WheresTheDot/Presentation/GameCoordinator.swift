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

    let start: StartGameUseCase
    private let addIfCorrect: AddDotIfCorrectUseCase

    init(start: StartGameUseCase, addIfCorrect: AddDotIfCorrectUseCase) {
        self.start = start
        self.addIfCorrect = addIfCorrect
    }

    func startGame(in area: CGRect) -> Round {
        let round = start(in: area)
        roundIndex = round.index
        score = round.dots.count
        message = ""
        return round
    }

    func handleTap(_ id: UUID, in area: CGRect) -> TapOutcome {
        let outcome = addIfCorrect(tapped: id, in: area)
        switch outcome {
        case .correct(let nextRound):
            roundIndex = nextRound.index
            score = nextRound.dots.count
            message = ""
        case .wrong(let gameOverScore, _):
            score = gameOverScore
            message = "Game Over"
        }
        return outcome
    }
}
