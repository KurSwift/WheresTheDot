//
//  AppContainer.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
internal import Combine

@MainActor
final class AppContainer: ObservableObject {

    // Shared
    private let rng: RandomNumberGenerating
    private let layout: DotLayoutGenerating
    private let sessionRepo: GameSessionRepository

    // Use cases (NEW)
    let startGame: StartGameUseCase
    let addDotIfCorrect: AddDotIfCorrectUseCase

    init() {
        // Shared services
        let rng = GKRandomAdapter()
        let layout = SimpleNewDotLayoutGenerator(rng: rng)

        // Initial snapshot for *this* game mode
        let initialSnapshot = GameSnapshot(
            roundIndex: 0,
            dots: [],
            newDotID: nil,
            isGameOver: false,
            radius: 18,
            minDistance: 44
        )

        let repo = InMemoryGameSessionRepository(initial: initialSnapshot)

        self.rng = rng
        self.layout = layout
        self.sessionRepo = repo

        // Use cases
        self.startGame = StartGameUseCase(repo: repo, layout: layout)
        self.addDotIfCorrect = AddDotIfCorrectUseCase(repo: repo, layout: layout)
    }
}
