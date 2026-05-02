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
                NeonGridBackground()
                VStack {
                    options
                        .padding()
                    Spacer()
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var options: some View {
        VStack {
            Toggle("Sound", isOn: $appState.soundEnabled)
                .padding()
                .toggleStyle(.switch)
                .glassEffect()
                .padding()
                .onChange(of: appState.soundEnabled) { _, newValue in
                    FirebaseEventsManager.logSoundToggled(enabled: newValue)
                }
            Toggle("Haptics", isOn: $appState.hapticsEnabled)
                .padding()
                .toggleStyle(.switch)
                .glassEffect()
                .padding()
                .onChange(of: appState.hapticsEnabled) { _, newValue in
                    FirebaseEventsManager.logHapticsToggled(enabled: newValue)
                }
            Toggle("Color Blind Mode", isOn: $appState.colorBlindMode)
                .padding()
                .toggleStyle(.switch)
                .glassEffect()
                .padding()
                .onChange(of: appState.colorBlindMode) { _, newValue in
                    FirebaseEventsManager.logColorBlindModeToggled(enabled: newValue)
                }

            // MARK: Premium section

            VStack(spacing: 12) {
                Button {
                    appState.openStore()
                } label: {
                    Label(appState.isAdFree ? "Premium (Active)" : "Get Premium", systemImage: "star.fill")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(DottoButtonStyle(kind: .options))
                .disabled(appState.isAdFree)

                Button {
                    Task { await store.restorePurchases() }
                } label: {
                    HStack {
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

            Spacer()
            Button {
                appState.goHome()
            } label: {
                Text("Back to Menu")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(DottoButtonStyle(kind: .options))
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
