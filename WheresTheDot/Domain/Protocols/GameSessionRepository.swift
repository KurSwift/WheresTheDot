//
//  GameSessionRepository.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation

protocol GameSessionRepository {
    func load() -> GameSnapshot
    func save(_ snapshot: GameSnapshot)
    func reset(_ snapshot: GameSnapshot)
}
