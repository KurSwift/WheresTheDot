//
//  ThemeRepository.swift
//  WheresTheDot
//

import Foundation

protocol ThemeRepository: AnyObject {
    var activeThemeID: ThemeID { get }
    var unlockedThemeIDs: Set<ThemeID> { get }
    var cumulativeScore: Int { get }

    func setActiveTheme(_ id: ThemeID)
    func addCumulativeScore(_ score: Int)
    func markUnlocked(_ id: ThemeID)
}
