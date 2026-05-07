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
    @ObservedObject private var store = StoreKitManager.shared

    var body: some View {
        ZStack {
            NeonGridBackground(color: appState.currentTheme.gridColor, backgroundColor: appState.currentTheme.backgroundColor)
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
            GameCenterManager.shared.authenticateLocalPlayer()
        }
    }

    private var header: some View {
        Image("AppTitle")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    private var menuButtons: some View {
        VStack(spacing: 0) {
            Spacer()
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
            .accessibilityIdentifier("btn_classic_mode")
            .buttonStyle(DottoButtonStyle(kind: .classic))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            if RemoteConfigManager.shared.arcadeModeEnabled {
                Button {
                    FirebaseEventsManager.logGameModeSelected(.arcade)
                    appState.startGame(mode: .arcade)
                } label: {
                    Text("Arcade Mode")
                        .bold()
                        .padding()
                }
                .accessibilityIdentifier("btn_arcade_mode")
                .buttonStyle(DottoButtonStyle(kind: .arcade))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            Spacer()
            utilityRow
                .padding(.horizontal, 10)
                .padding(.top, 16)
        }
        .padding(.top, 8)
    }

    private var utilityRow: some View {
        HStack(spacing: 12) {
            utilityButton(icon: "paintpalette.fill", label: "Themes", color: .neonPurple) {
                FirebaseEventsManager.logThemesOpened()
                appState.openThemes()
            }
            .accessibilityIdentifier("btn_themes")

            utilityButton(icon: "gearshape.fill", label: "Options", color: .neonPurple) {
                FirebaseEventsManager.logSettingsOpened()
                appState.openSettings()
            }
            .accessibilityIdentifier("btn_options")

            if gameCenter.isAuthenticated {
                utilityButton(icon: "trophy.fill", label: "Leaderboards", color: .neonCyan) {
                    FirebaseEventsManager.logLeaderboardOpened()
                    GameCenterManager.shared.presentLeaderboards()
                }
                utilityButton(icon: "rosette", label: "Achievements", color: .neonCyan) {
                    GameCenterManager.shared.presentAchievements()
                }
            }
        }
    }

    private func utilityButton(
        icon: String,
        label: LocalizedStringKey,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(color.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            if AdminConfig.isEnabled {
                Button {
                    appState.openAdmin()
                } label: {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.neonOrange)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text("SKLabs")
                .font(.footnote)
                .foregroundStyle(Color.white)

            Spacer()

            if !store.isAdFree {
                Button {
                    appState.openStore()
                } label: {
                    Image(systemName: "star.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.neonYellow)
                }
                .buttonStyle(.plain)
            } else if AdminConfig.isEnabled {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.footnote)
                    .hidden()
            } else {
                Color.clear.frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    MainMenuView()
}
