//
//  LevelProgression.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 16/02/26.
//

import Foundation

protocol LevelProgression {
    func initialState() -> LevelState
    func state(forScore score: Int) -> LevelState
    func difficulty(for level: Int) -> Difficulty
}
