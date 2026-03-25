//
//  MainMenuView.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import SwiftUI
import GameKit

struct MainMenuView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var gameCenter = GameCenterManager.shared

    var body: some View {
        ZStack {
            NeonGridBackground()
            VStack {
                AnimatedDotsView()
                Spacer()
            }.opacity(0.5)
            VStack {
                header
                menuButtons
                Spacer()
                footer
            }
        }
        .onAppear {
            print("[MainMenuView] onAppear — isAuthenticated: \(GameCenterManager.shared.isAuthenticated)")
            GameCenterManager.shared.authenticateLocalPlayer()
        }
    }

    private var header: some View {
        Image("AppTitle")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    private var menuButtons: some View {
        VStack(alignment: .leading) {
            Button {
                FirebaseEventsManager.logGameModeSelected(.classic)
                appState.startGame(mode: .classic)
            } label: {
                HStack(spacing: 0) {
                    Text("Classic Mode")
                                        .bold()
                                        .padding()
                    Image(systemName: "infinity")
                        .bold()
                        .padding()
                }

            }
            .buttonStyle(DottoButtonStyle(kind: .classic))
            .padding(10)

            Button {
                FirebaseEventsManager.logGameModeSelected(.arcade)
                appState.startGame(mode: .arcade)
            } label: {
                Text("Arcade Mode")
                    .bold()
                    .padding()
            }
            .buttonStyle(DottoButtonStyle(kind: .arcade))
            .padding(10)

            Button {
                FirebaseEventsManager.logSettingsOpened()
                appState.openSettings()
            } label: {
                Text("Options")
                    .bold()
                    .padding()
            }
            .buttonStyle(DottoButtonStyle(kind: .options))
            .padding(10)

            if gameCenter.isAuthenticated {
                Button {
                    GameCenterManager.shared.presentLeaderboards()
                } label: {
                    HStack(spacing: 0) {
                        Text("Leaderboards")
                            .bold()
                            .padding()
                        Image(systemName: "trophy.fill")
                            .bold()
                            .padding()
                    }
                }
                .buttonStyle(DottoButtonStyle(kind: .classic))
                .padding(10)
            }
        }
        .padding(.top, 8)
    }

    private var footer: some View {
        Text("SKLabs")
            .font(.footnote)
            .foregroundStyle(Color.white)
    }


}

#Preview {
    MainMenuView()
}
