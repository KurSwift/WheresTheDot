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

    // Use cases
    let startGame: StartGameUseCase
    let addDotIfCorrect: AddDotIfCorrectUseCase

    // Exposed so GameCoordinator can read time limits per level
    let progression: LevelProgression?

    init(mode: GameMode = .classic) {
        let rng = GKRandomAdapter()
        let layout = SimpleNewDotLayoutGenerator(rng: rng)

        // For arcade, seed the initial difficulty from level-1 parameters
        let progression: LevelProgression? = (mode == .arcade) ? SimpleArcadeProgression() : nil
        let level1 = progression?.difficulty(for: 1)

        let initialSnapshot = GameSnapshot(
            roundIndex: 0,
            dots: [],
            newDotID: nil,
            isGameOver: false,
            radius: level1?.radius ?? 18,
            minDistance: level1?.minDistance ?? 44
        )

        let repo = InMemoryGameSessionRepository(initial: initialSnapshot)

        self.rng = rng
        self.layout = layout
        self.sessionRepo = repo
        self.progression = progression

        self.startGame = StartGameUseCase(repo: repo, layout: layout)
        self.addDotIfCorrect = AddDotIfCorrectUseCase(repo: repo, layout: layout, progression: progression)
    }
}
