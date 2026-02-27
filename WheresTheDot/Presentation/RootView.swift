//
//  RootView.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import SwiftUI


struct RootView: View {
    @State private var container = AppContainer()
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            switch appState.route {
            case .mainMenu:
                MainMenuView()
            case .game(let mode):
                GameContainerView(
                        mode: mode,
                        coordinator: GameCoordinator(start: container.startGame,
                                                     addIfCorrect: container.addDotIfCorrect)
                    )
            case .settings:
                SettingsView()
            }
        }
        .environmentObject(appState)
        .environmentObject(container)
    }
}
