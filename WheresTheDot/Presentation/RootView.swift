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
            case .settings:
                SettingsView()
            case .themes:
                ThemesView()
            case .admin:
                AdminView()
            }
        }
        .environmentObject(appState)
    }
}
