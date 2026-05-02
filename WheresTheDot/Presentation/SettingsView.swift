//
//  SettingsView.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var store = StoreKitManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                NeonGridBackground(
                    color: appState.currentTheme.gridColor,
                    backgroundColor: appState.currentTheme.backgroundColor
                )
                ScrollView {
                    VStack(spacing: 24) {
                        preferencesSection
                        premiumSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { appState.goHome() }
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(appState.currentTheme.gridColor)
                }
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Preferences", icon: "slider.horizontal.3")
            VStack(spacing: 0) {
                settingsToggle(
                    label: "Sound",
                    icon: "speaker.wave.2.fill",
                    iconColor: .neonCyan,
                    isOn: $appState.soundEnabled
                ) { FirebaseEventsManager.logSoundToggled(enabled: $0) }

                Divider().overlay(.white.opacity(0.08))

                settingsToggle(
                    label: "Haptics",
                    icon: "iphone.radiowaves.left.and.right",
                    iconColor: .neonPurple,
                    isOn: $appState.hapticsEnabled
                ) { FirebaseEventsManager.logHapticsToggled(enabled: $0) }

                Divider().overlay(.white.opacity(0.08))

                settingsToggle(
                    label: "Color Blind Mode",
                    icon: "eye.fill",
                    iconColor: .accessibleBlue,
                    isOn: $appState.colorBlindMode
                ) { FirebaseEventsManager.logColorBlindModeToggled(enabled: $0) }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(appState.currentTheme.gridColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Premium", icon: "star.fill")
            VStack(spacing: 12) {
                Button {
                    appState.openStore()
                } label: {
                    Label(
                        appState.isAdFree ? "Premium (Active)" : "Get Premium",
                        systemImage: "star.fill"
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(DottoButtonStyle(kind: .options))
                .disabled(appState.isAdFree)

                Button {
                    Task { await store.restorePurchases() }
                } label: {
                    HStack(spacing: 8) {
                        if store.isLoading {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text("Restore Purchases")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .buttonStyle(DottoButtonStyle(kind: .options))
                .disabled(store.isLoading)
            }
        }
    }

    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(.caption, design: .rounded).weight(.bold))
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
            .padding(.leading, 4)
    }

    private func settingsToggle(
        label: String,
        icon: String,
        iconColor: Color,
        isOn: Binding<Bool>,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(label)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(.white)
            }
        }
        .toggleStyle(.switch)
        .tint(iconColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onChange(of: isOn.wrappedValue) { _, newValue in onChange(newValue) }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
