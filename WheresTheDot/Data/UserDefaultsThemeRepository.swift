//
//  UserDefaultsThemeRepository.swift
//  WheresTheDot
//

import Foundation

final class UserDefaultsThemeRepository: ThemeRepository {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let activeThemeID      = "theme.activeThemeID"
        static let unlockedThemeIDs   = "theme.unlockedThemeIDs"
        static let cumulativeScore    = "theme.cumulativeScore"
        static let userHasSetTheme    = "theme.userHasSetTheme"
    }

    var activeThemeID: ThemeID {
        // If the user has never explicitly picked a theme, use the remote default.
        guard defaults.bool(forKey: Keys.userHasSetTheme),
              let raw = defaults.string(forKey: Keys.activeThemeID),
              let id = ThemeID(rawValue: raw) else {
            return RemoteConfigManager.shared.defaultTheme
        }
        return id
    }

    var unlockedThemeIDs: Set<ThemeID> {
        let raws = defaults.stringArray(forKey: Keys.unlockedThemeIDs) ?? []
        var ids = Set(raws.compactMap { ThemeID(rawValue: $0) })
        ids.insert(.neon) // always unlocked
        return ids
    }

    var cumulativeScore: Int {
        defaults.integer(forKey: Keys.cumulativeScore)
    }

    func setActiveTheme(_ id: ThemeID) {
        defaults.set(id.rawValue, forKey: Keys.activeThemeID)
        defaults.set(true, forKey: Keys.userHasSetTheme)
    }

    func addCumulativeScore(_ score: Int) {
        let newTotal = cumulativeScore + score
        defaults.set(newTotal, forKey: Keys.cumulativeScore)
    }

    func markUnlocked(_ id: ThemeID) {
        var current = defaults.stringArray(forKey: Keys.unlockedThemeIDs) ?? []
        guard !current.contains(id.rawValue) else { return }
        current.append(id.rawValue)
        defaults.set(current, forKey: Keys.unlockedThemeIDs)
    }
}
