//
//  InMemoryGameSessionRepository.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation

final class InMemoryGameSessionRepository: GameSessionRepository {
    private var snapshot: GameSnapshot

    init(initial: GameSnapshot) {
        self.snapshot = initial
    }

    func load() -> GameSnapshot { snapshot }
    func save(_ snapshot: GameSnapshot) { self.snapshot = snapshot }
    func reset(_ snapshot: GameSnapshot) { self.snapshot = snapshot }
}
