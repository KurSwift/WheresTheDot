//
//  ThemesView.swift
//  WheresTheDot
//

import SwiftUI

struct ThemesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var unlockedIDs: Set<ThemeID> = []
    @State private var cumulativeScore: Int = 0

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            NeonGridBackground(color: appState.currentTheme.gridColor, backgroundColor: appState.currentTheme.backgroundColor)

            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Theme.all, id: \.id) { theme in
                            ThemeCardView(
                                theme: theme,
                                isActive: appState.currentTheme.id == theme.id,
                                isUnlocked: unlockedIDs.contains(theme.id),
                                cumulativeScore: cumulativeScore
                            ) {
                                appState.setActiveTheme(theme.id)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear { refresh() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { appState.goHome() } label: {
                Image(systemName: "xmark").padding(12)
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            VStack(spacing: 2) {
                Text("Themes")
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .foregroundStyle(.white)
                Text("Lifetime score: \(cumulativeScore)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()
            // Spacer to balance the close button
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private func refresh() {
        unlockedIDs = appState.themeRepo.unlockedThemeIDs
        cumulativeScore = appState.themeRepo.cumulativeScore
    }
}
