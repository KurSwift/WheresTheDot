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

    // MARK: - Helpers

    var isInGame: Bool {
        if case .game = route { return true }
        return false
    }
}
