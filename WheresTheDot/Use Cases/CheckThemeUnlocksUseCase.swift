//
//  CheckThemeUnlocksUseCase.swift
//  WheresTheDot
//

import Foundation

struct CheckThemeUnlocksUseCase {
    let repo: ThemeRepository

    /// Records the session score and returns any themes newly unlocked as a result.
    func callAsFunction(score: Int) -> [Theme] {
        let before = repo.unlockedThemeIDs
        repo.addCumulativeScore(score)
        let total = repo.cumulativeScore

        var newlyUnlocked: [Theme] = []
        for theme in Theme.all {
            guard let milestone = RemoteConfigManager.shared.milestone(for: theme.id) else { continue }
            if !before.contains(theme.id) && total >= milestone {
                repo.markUnlocked(theme.id)
                newlyUnlocked.append(theme)
            }
        }
        return newlyUnlocked
    }
}
