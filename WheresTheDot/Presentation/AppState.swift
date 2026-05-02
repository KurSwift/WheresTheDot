//
//  AppState.swift
//  WheresTheDot
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
    let store = StoreKitManager.shared

    @AppStorage("activeThemeID") private var activeThemeIDRaw: String = ThemeID.neon.rawValue

    var currentTheme: Theme {
        Theme.theme(for: ThemeID(rawValue: activeThemeIDRaw) ?? .neon)
    }

    lazy var checkThemeUnlocks = CheckThemeUnlocksUseCase(repo: themeRepo)

    func isUnlocked(theme: Theme) -> Bool {
        if theme.isAlwaysUnlocked { return true }
        if theme.isPremium { return store.isPurchased(theme.productID ?? "") }
        return themeRepo.unlockedThemeIDs.contains(theme.id)
    }

    func setActiveTheme(_ id: ThemeID) {
        let theme = Theme.theme(for: id)
        guard isUnlocked(theme: theme) else { return }
        themeRepo.setActiveTheme(id)
        activeThemeIDRaw = id.rawValue
    }

    var isAdFree: Bool { store.isAdFree }

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

    func openStore() {
        FirebaseEventsManager.logStoreOpened()
        route = .store
    }

    func openAdmin() {
        route = .admin
    }

    // MARK: - Helpers

    var isInGame: Bool {
        if case .game = route { return true }
        return false
    }
}
