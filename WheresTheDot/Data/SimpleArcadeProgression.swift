//
//  SimpleArcadeProgression.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 16/02/26.
//

import Foundation

struct SimpleArcadeProgression: LevelProgression {
    func initialState() -> LevelState {
        .init(level: 1, nextLevelScore: 5)
    }

    func state(forScore score: Int) -> LevelState {
        let step = max(1, RemoteConfigManager.shared.arcadeDifficultyStep)
        let level = max(1, (score / step) + 1)
        let next = level * step
        return .init(level: level, nextLevelScore: next)
    }

    func difficulty(for level: Int) -> Difficulty {
        let radius = max(9, 18 - CGFloat(level - 1))
        let minDistance = max(22, 40 - CGFloat(level - 1) * 1.5)
        let cover = max(0.15, 0.45 - Double(level - 1) * 0.02)
        let timeLimitBase = RemoteConfigManager.shared.arcadeTimeLimitBase
        let timeLimit = max(0.8, timeLimitBase - Double(level - 1) * 0.08)
        // Size variation: none in levels 1-2, grows by 2pt per level from level 3, capped at 8pt
        let radiusVariation = max(0, min(CGFloat(level - 2) * 2, 8))

        return Difficulty(dotCount: 10,
                          radius: radius,
                          showTime: 1,
                          minDistance: minDistance,
                          timeLimit: timeLimit,
                          radiusVariation: radiusVariation)
    }
}
