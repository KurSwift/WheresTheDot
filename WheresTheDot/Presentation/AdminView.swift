//
//  AdminView.swift
//  WheresTheDot
//
//  Accessible only when AdminConfig.isEnabled == true.
//  Local overrides are stored in UserDefaults and shadow Firebase values.
//

import SwiftUI

struct AdminView: View {
    @EnvironmentObject private var appState: AppState

    private let rc = RemoteConfigManager.shared

    // Gameplay
    @State private var arcadeTimeLimitBase: Double = 0
    @State private var arcadeDifficultyStep: Int = 0
    @State private var memoryCoverDuration: Double = 0

    // Flags
    @State private var onboardingEnabled: Bool = true
    @State private var arcadeModeEnabled: Bool = true

    // Themes
    @State private var defaultTheme: ThemeID = .neon
    @State private var forestMilestone: Int = 0
    @State private var oceanMilestone: Int = 0
    @State private var cosmosMilestone: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                NeonGridBackground(
                    color: appState.currentTheme.gridColor,
                    backgroundColor: appState.currentTheme.backgroundColor
                )

                List {
                    gameplaySection
                    featureFlagsSection
                    themesSection
                    resetSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Admin Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { appState.goHome() }
                }
            }
        }
        .onAppear { loadCurrentValues() }
    }

    // MARK: - Sections

    private var gameplaySection: some View {
        Section {
            overrideRow(key: RemoteConfigManager.Keys.arcadeTimeLimitBase) {
                HStack {
                    Text("Arcade time limit base")
                    Spacer()
                    Stepper(
                        String(format: "%.1fs", arcadeTimeLimitBase),
                        value: $arcadeTimeLimitBase,
                        in: 0.5...10.0,
                        step: 0.1
                    ) { _ in
                        rc.setOverride(arcadeTimeLimitBase, forKey: RemoteConfigManager.Keys.arcadeTimeLimitBase)
                    }
                }
            }

            overrideRow(key: RemoteConfigManager.Keys.arcadeDifficultyStep) {
                HStack {
                    Text("Difficulty step (pts)")
                    Spacer()
                    Stepper(
                        "\(arcadeDifficultyStep)",
                        value: $arcadeDifficultyStep,
                        in: 1...20
                    ) { _ in
                        rc.setOverride(arcadeDifficultyStep, forKey: RemoteConfigManager.Keys.arcadeDifficultyStep)
                    }
                }
            }

            overrideRow(key: RemoteConfigManager.Keys.memoryCoverDuration) {
                HStack {
                    Text("Memory cover duration")
                    Spacer()
                    Stepper(
                        String(format: "%.2fs", memoryCoverDuration),
                        value: $memoryCoverDuration,
                        in: 0.1...2.0,
                        step: 0.05
                    ) { _ in
                        rc.setOverride(memoryCoverDuration, forKey: RemoteConfigManager.Keys.memoryCoverDuration)
                    }
                }
            }
        } header: {
            Text("Gameplay")
        }
    }

    private var featureFlagsSection: some View {
        Section {
            overrideRow(key: RemoteConfigManager.Keys.onboardingEnabled) {
                Toggle("Onboarding enabled", isOn: $onboardingEnabled)
                    .onChange(of: onboardingEnabled) { _, v in
                        rc.setOverride(v, forKey: RemoteConfigManager.Keys.onboardingEnabled)
                    }
            }

            overrideRow(key: RemoteConfigManager.Keys.arcadeModeEnabled) {
                Toggle("Arcade mode enabled", isOn: $arcadeModeEnabled)
                    .onChange(of: arcadeModeEnabled) { _, v in
                        rc.setOverride(v, forKey: RemoteConfigManager.Keys.arcadeModeEnabled)
                    }
            }
        } header: {
            Text("Feature Flags")
        }
    }

    private var themesSection: some View {
        Section {
            overrideRow(key: RemoteConfigManager.Keys.defaultTheme) {
                Picker("Default theme", selection: $defaultTheme) {
                    ForEach(ThemeID.allCases, id: \.self) { id in
                        Text(id.rawValue.capitalized).tag(id)
                    }
                }
                .onChange(of: defaultTheme) { _, v in
                    rc.setOverride(v.rawValue, forKey: RemoteConfigManager.Keys.defaultTheme)
                }
            }

            overrideRow(key: RemoteConfigManager.Keys.forestMilestone) {
                HStack {
                    Text("Forest milestone")
                    Spacer()
                    Stepper("\(forestMilestone) pts", value: $forestMilestone, in: 1...1000, step: 5) { _ in
                        rc.setOverride(forestMilestone, forKey: RemoteConfigManager.Keys.forestMilestone)
                    }
                }
            }

            overrideRow(key: RemoteConfigManager.Keys.oceanMilestone) {
                HStack {
                    Text("Ocean milestone")
                    Spacer()
                    Stepper("\(oceanMilestone) pts", value: $oceanMilestone, in: 1...1000, step: 5) { _ in
                        rc.setOverride(oceanMilestone, forKey: RemoteConfigManager.Keys.oceanMilestone)
                    }
                }
            }

            overrideRow(key: RemoteConfigManager.Keys.cosmosMilestone) {
                HStack {
                    Text("Cosmos milestone")
                    Spacer()
                    Stepper("\(cosmosMilestone) pts", value: $cosmosMilestone, in: 1...1000, step: 5) { _ in
                        rc.setOverride(cosmosMilestone, forKey: RemoteConfigManager.Keys.cosmosMilestone)
                    }
                }
            }
        } header: {
            Text("Themes")
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                rc.clearAllOverrides()
                loadCurrentValues()
            } label: {
                Label("Reset all to Firebase values", systemImage: "arrow.counterclockwise")
            }
        }
    }

    // MARK: - Helpers

    /// Wraps a row with a colored leading dot indicating override status.
    @ViewBuilder
    private func overrideRow(key: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(rc.isOverridden(key) ? Color.neonOrange : Color.neonLime)
                .frame(width: 7, height: 7)
            content()
        }
    }

    private func loadCurrentValues() {
        arcadeTimeLimitBase  = rc.arcadeTimeLimitBase
        arcadeDifficultyStep = rc.arcadeDifficultyStep
        memoryCoverDuration  = rc.memoryCoverDuration
        onboardingEnabled    = rc.onboardingEnabled
        arcadeModeEnabled    = rc.arcadeModeEnabled
        defaultTheme         = rc.defaultTheme
        forestMilestone      = rc.milestone(for: .forest) ?? 50
        oceanMilestone       = rc.milestone(for: .ocean) ?? 150
        cosmosMilestone      = rc.milestone(for: .cosmos) ?? 350
    }
}
