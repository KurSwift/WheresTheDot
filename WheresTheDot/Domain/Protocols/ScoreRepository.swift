//
//  ScoreRepository.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation

protocol ScoreRepository: AnyObject {
    func bestScore(for mode: GameMode) -> Int
    func setBestScore(_ score: Int, for mode: GameMode)
}
