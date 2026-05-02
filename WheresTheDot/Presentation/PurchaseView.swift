//
//  PurchaseView.swift
//  WheresTheDot
//

import SwiftUI
import StoreKit

struct PurchaseView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var store = StoreKitManager.shared

    private let features: [(icon: String, color: Color, text: LocalizedStringKey)] = [
        ("xmark.shield.fill",  .neonCyan,                                    "Play ad-free forever"),
        ("snowflake",          Color(UIColor(hex: "#7DD3FC")),                "Aurora Theme — icy blue palette"),
        ("flame.fill",         Color(UIColor(hex: "#F97316")),                "Inferno Theme — fire red palette"),
        ("stethoscope",        Color(UIColor(hex: "#64B5D9")),                "DoctorPing Theme — hospital palette"),
        ("star.fill",          Color(UIColor(hex: "#e07a8a")),                "Space Travel Theme — deep space palette"),
    ]

    var body: some View {
        ZStack {
            NeonGridBackground(
                color: appState.currentTheme.gridColor,
                backgroundColor: appState.currentTheme.backgroundColor
            )

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 28) {
                        heroSection
                        featuresCard
                        actionSection
                        restoreButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .alert("Purchase Error", isPresented: Binding(
            get: { store.purchaseError != nil },
            set: { if !$0 { store.purchaseError = nil } }
        )) {
            Button("OK", role: .cancel) { store.purchaseError = nil }
        } message: {
            Text(store.purchaseError ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { appState.goHome() } label: {
                Image(systemName: "xmark").padding(12)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 4)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "star.fill")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(Color.neonYellow)
                .shadow(color: Color.neonYellow.opacity(0.6), radius: 20)

            Text("Premium")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("One-time purchase. No subscription.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Features card

    private var featuresCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(feature.color)
                        .shadow(color: feature.color.opacity(0.5), radius: 6)
                        .frame(width: 28)

                    Text(feature.text)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                if index < features.count - 1 {
                    Divider().background(Color.white.opacity(0.07))
                        .padding(.horizontal, 20)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.neonYellow.opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: - Action

    @ViewBuilder
    private var actionSection: some View {
        if store.isAdFree {
            purchasedBadge
        } else if store.isLoading && store.premiumProduct == nil {
            ProgressView().tint(.white).padding(.top, 8)
        } else if let product = store.premiumProduct {
            buyButton(product: product)
        } else {
            unavailableNote
        }
    }

    private var purchasedBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.neonLime)
                .font(.system(size: 22))
            Text("Premium Active")
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundStyle(Color.neonLime)
        }
        .padding(.vertical, 12)
    }

    private func buyButton(product: Product) -> some View {
        Button {
            Task { await store.purchase(product) }
        } label: {
            HStack(spacing: 8) {
                if store.isLoading {
                    ProgressView().tint(.black).scaleEffect(0.85)
                }
                Text("Get Premium — \(product.displayPrice)")
                    .font(.system(.body, design: .rounded).weight(.black))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.neonYellow)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.neonYellow.opacity(0.4), radius: 14)
        }
        .buttonStyle(.plain)
        .disabled(store.isLoading)
    }

    private var unavailableNote: some View {
        Text("Store unavailable. Check your connection.")
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(.white.opacity(0.4))
            .multilineTextAlignment(.center)
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            HStack(spacing: 6) {
                if store.isLoading {
                    ProgressView().tint(.white).scaleEffect(0.75)
                }
                Text("Restore Purchases")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
        .disabled(store.isLoading)
    }
}
