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

    var body: some View {
        NavigationStack {
//            Form {
//                Section("Preferences") {
//                    Toggle("Sound", isOn: $appState.soundEnabled)
//                    Toggle("Haptics", isOn: $appState.hapticsEnabled)
//                }
//
//                Section {
//                    Button {
//                        appState.goHome()
//                    } label: {
//                        Text("Back to Menu")
//                            .frame(maxWidth: .infinity, alignment: .center)
//                    }
//                }
//            }
            ZStack {
                NeonGridBackground()
                VStack {
                    header
                        .glassEffectTransition(.matchedGeometry)
                    options
                        .padding()
                    Spacer()
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("D").foregroundStyle(Color(uiColor: .neonMagenta))
                Text("O").foregroundStyle(Color(uiColor:.neonCyan))
                Text("T").foregroundStyle(Color(uiColor:.white))
                Text("T").foregroundStyle(Color(uiColor:.neonLime))
                Text("O").foregroundStyle(Color(uiColor:.neonPurple))
            }
            .font(Font.custom("Chalkduster", size: 80))
        }
    }
    
    private var options: some View {
        VStack {
            Toggle("Sound", isOn: $appState.soundEnabled)
                .padding()
                .toggleStyle(.switch)
                .glassEffect()
                .padding()
            Toggle("Haptics", isOn: $appState.hapticsEnabled)
                .padding()
                .toggleStyle(.switch)
                .glassEffect()
                .padding()
            Toggle("Color Blind Mode", isOn: $appState.colorBlindMode)
                .padding()
                .toggleStyle(.switch)
                .glassEffect()
                .padding()
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
