//
//  UserDefaultsScoreRepository.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation

final class UserDefaultsScoreRepository: ScoreRepository {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func bestScore(for mode: GameMode) -> Int {
        defaults.integer(forKey: key(for: mode))
    }

    func setBestScore(_ score: Int, for mode: GameMode) {
        defaults.set(score, forKey: key(for: mode))
    }

    private func key(for mode: GameMode) -> String {
        switch mode {
        case .classic: return "score.best.classic"
        case .arcade:  return "score.best.arcade"
        case .daily:   return "score.best.daily"
        }
    }
}
