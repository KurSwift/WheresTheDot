//
//  RootView.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import SwiftUI


struct RootView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            switch appState.route {
            case .mainMenu:
                MainMenuView()
            case .game(let mode):
                GameContainerView(mode: mode)
            case .duel:
                DuelView()
            case .settings:
                SettingsView()
            case .themes:
                ThemesView()
            case .store:
                PurchaseView()
            case .admin:
                AdminView()
            }
        }
        .environmentObject(appState)
        // lastdot://duel — deep link for the App Store "Duel Week" in-app event
        .onOpenURL { url in
            guard url.host == "duel", RemoteConfigManager.shared.duelModeEnabled else { return }
            FirebaseEventsManager.logDuelSelected()
            appState.startDuel()
        }
    }
}
