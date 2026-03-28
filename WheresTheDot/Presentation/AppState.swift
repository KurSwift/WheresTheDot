//
//  AppState.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class AppState: ObservableObject {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("colorBlindMode") var colorBlindMode: Bool = false

    // MARK: - Theme

    let themeRepo: ThemeRepository = UserDefaultsThemeRepository()

    @AppStorage("activeThemeID") private var activeThemeIDRaw: String = ThemeID.neon.rawValue

    var currentTheme: Theme {
        Theme.theme(for: ThemeID(rawValue: activeThemeIDRaw) ?? .neon)
    }

    lazy var checkThemeUnlocks = CheckThemeUnlocksUseCase(repo: themeRepo)

    func setActiveTheme(_ id: ThemeID) {
        themeRepo.setActiveTheme(id)
        activeThemeIDRaw = id.rawValue
    }

    // MARK: - Navigation

    @Published private(set) var route: AppRoute = .mainMenu

    // MARK: - Navigation API

    func goHome() {
        route = .mainMenu
    }

    func startGame(mode: GameMode) {
        route = .game(mode)
    }

    func openSettings() {
        route = .settings
    }

    func openThemes() {
        route = .themes
    }

    // MARK: - Helpers

    var isInGame: Bool {
        if case .game = route { return true }
        return false
    }
}
