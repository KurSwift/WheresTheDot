//
//  ThemesView.swift
//  WheresTheDot
//

import SwiftUI
import StoreKit

struct ThemesView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var store = StoreKitManager.shared
    @State private var unlockedIDs: Set<ThemeID> = []
    @State private var cumulativeScore: Int = 0

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            NeonGridBackground(color: appState.currentTheme.gridColor, backgroundColor: appState.currentTheme.backgroundColor)

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 20) {
                        if !appState.isAdFree {
                            removeAdsBanner
                                .padding(.horizontal, 20)
                                .padding(.top, 4)
                        }

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Theme.all, id: \.id) { theme in
                                ThemeCardView(
                                    theme: theme,
                                    isActive: appState.currentTheme.id == theme.id,
                                    isUnlocked: appState.isUnlocked(theme: theme),
                                    cumulativeScore: cumulativeScore,
                                    priceText: priceText(for: theme),
                                    onSelect: {
                                        appState.setActiveTheme(theme.id)
                                    },
                                    onBuy: theme.isPremium ? {
                                        appState.openStore()
                                    } : nil
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 12)
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
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    // MARK: - Remove Ads Banner

    private var removeAdsBanner: some View {
        Button { appState.openStore() } label: {
            HStack(spacing: 12) {
                Image(systemName: "xmark.shield.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.neonCyan)
                    .shadow(color: Color.neonCyan.opacity(0.6), radius: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remove Ads")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Text("One-time purchase — play ad-free forever")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.neonCyan.opacity(0.2), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func priceText(for theme: Theme) -> String? {
        guard theme.isPremium, let productID = theme.productID else { return nil }
        return store.products.first(where: { $0.id == productID })?.displayPrice
    }

    private func refresh() {
        unlockedIDs = appState.themeRepo.unlockedThemeIDs
        cumulativeScore = appState.themeRepo.cumulativeScore
    }
}
