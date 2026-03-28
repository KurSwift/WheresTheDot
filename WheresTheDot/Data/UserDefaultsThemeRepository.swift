//
//  UserDefaultsThemeRepository.swift
//  WheresTheDot
//

import Foundation

final class UserDefaultsThemeRepository: ThemeRepository {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let activeThemeID    = "theme.activeThemeID"
        static let unlockedThemeIDs = "theme.unlockedThemeIDs"
        static let cumulativeScore  = "theme.cumulativeScore"
    }

    var activeThemeID: ThemeID {
        guard let raw = defaults.string(forKey: Keys.activeThemeID),
              let id = ThemeID(rawValue: raw) else { return .neon }
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
