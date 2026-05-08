//
//  Theme.swift
//  WheresTheDot
//

import SwiftUI
import UIKit

// MARK: - ThemeID

enum ThemeID: String, CaseIterable, Codable {
    case neon
    case forest
    case ocean
    case cosmos
    case aurora
    case inferno
    case doctorping
    case spacetravel
}

// MARK: - DotShape

enum DotShape: Equatable {
    case circle
    /// PNG asset from xcassets. Falls back to the SF Symbol if the asset isn't found at runtime.
    case asset(named: String, fallbackSymbol: String)
    /// Pool of numbered assets (`{prefix}_1` … `{prefix}_{count}`). One is picked randomly per game session.
    case randomAssets(prefix: String, count: Int, fallbackSymbol: String)
}

// MARK: - Theme

struct Theme {
    let id: ThemeID
    let name: LocalizedStringResource
    /// nil = always unlocked (for score-unlocked themes this holds the milestone)
    let unlockScore: Int?
    /// true = requires IAP, not earned by score
    let isPremium: Bool
    /// StoreKit product ID for premium themes; nil for score-unlocked themes
    let productID: String?
    let backgroundColor: Color
    let gridColor: Color
    let dotColors: [UIColor]
    let accentColor: Color
    let dotShape: DotShape

    var isAlwaysUnlocked: Bool { unlockScore == nil && !isPremium }
}

// MARK: - Theme catalog

extension Theme {
    static let neon = Theme(
        id: .neon,
        name: "Neon" as LocalizedStringResource,
        unlockScore: nil,
        isPremium: false,
        productID: nil,
        backgroundColor: Color(UIColor(hex: "#05060A")),
        gridColor: .neonCyan,
        dotColors: [.neonCyan, .neonPink, .neonPurple, .neonLime, .neonOrange],
        accentColor: .neonCyan,
        dotShape: .circle
    )

    static let forest = Theme(
        id: .forest,
        name: "Forest" as LocalizedStringResource,
        unlockScore: 50,
        isPremium: false,
        productID: nil,
        backgroundColor: Color(UIColor(hex: "#050D07")),
        gridColor: Color(UIColor(hex: "#4ADE80")),
        dotColors: [
            UIColor(hex: "#4ADE80"),
            UIColor(hex: "#22C55E"),
            UIColor(hex: "#FCD34D"),
            UIColor(hex: "#A3E635"),
            UIColor(hex: "#FBBF24")
        ],
        accentColor: Color(UIColor(hex: "#4ADE80")),
        dotShape: .randomAssets(prefix: "forest_dot", count: 5, fallbackSymbol: "tree.fill")
    )

    static let ocean = Theme(
        id: .ocean,
        name: "Ocean" as LocalizedStringResource,
        unlockScore: 200,
        isPremium: false,
        productID: nil,
        backgroundColor: Color(UIColor(hex: "#03080F")),
        gridColor: Color(UIColor(hex: "#22D3EE")),
        dotColors: [
            UIColor(hex: "#22D3EE"),
            UIColor(hex: "#3B82F6"),
            UIColor(hex: "#34D399"),
            UIColor(hex: "#F87171"),
            UIColor(hex: "#93C5FD")
        ],
        accentColor: Color(UIColor(hex: "#22D3EE")),
        dotShape: .randomAssets(prefix: "ocean_dot", count: 5, fallbackSymbol: "drop.fill")
    )

    static let cosmos = Theme(
        id: .cosmos,
        name: "Cosmos" as LocalizedStringResource,
        unlockScore: 300,
        isPremium: false,
        productID: nil,
        backgroundColor: Color(UIColor(hex: "#080510")),
        gridColor: Color(UIColor(hex: "#A855F7")),
        dotColors: [
            UIColor(hex: "#A855F7"),
            UIColor(hex: "#818CF8"),
            UIColor(hex: "#E879F9"),
            UIColor(hex: "#F0ABFC"),
            UIColor(hex: "#FDE68A")
        ],
        accentColor: Color(UIColor(hex: "#A855F7")),
        dotShape: .randomAssets(prefix: "cosmos_dot", count: 5, fallbackSymbol: "moon.fill")
    )

    static let aurora = Theme(
        id: .aurora,
        name: "Aurora" as LocalizedStringResource,
        unlockScore: nil,
        isPremium: true,
        productID: "com.optionalsankur.Dotto.theme.aurora",
        backgroundColor: Color(UIColor(hex: "#030A15")),
        gridColor: Color(UIColor(hex: "#BAE6FD")),
        dotColors: [
            UIColor(hex: "#7DD3FC"),
            UIColor(hex: "#E0F2FE"),
            UIColor(hex: "#38BDF8"),
            UIColor(hex: "#818CF8"),
            UIColor(hex: "#BAE6FD")
        ],
        accentColor: Color(UIColor(hex: "#7DD3FC")),
        dotShape: .randomAssets(prefix: "aurora_dot", count: 5, fallbackSymbol: "flake")
    )

    static let inferno = Theme(
        id: .inferno,
        name: "Inferno" as LocalizedStringResource,
        unlockScore: nil,
        isPremium: true,
        productID: "com.optionalsankur.Dotto.theme.inferno",
        backgroundColor: Color(UIColor(hex: "#100305")),
        gridColor: Color(UIColor(hex: "#F97316")),
        dotColors: [
            UIColor(hex: "#EF4444"),
            UIColor(hex: "#F97316"),
            UIColor(hex: "#F59E0B"),
            UIColor(hex: "#FCD34D"),
            UIColor(hex: "#FB7185")
        ],
        accentColor: Color(UIColor(hex: "#F97316")),
        dotShape: .asset(named: "flame.fill", fallbackSymbol: "flame.fill")
    )

    static let doctorping = Theme(
        id: .doctorping,
        name: "DoctorPing" as LocalizedStringResource,
        unlockScore: nil,
        isPremium: true,
        productID: "com.optionalsankur.Dotto.premium",
        backgroundColor: Color(UIColor(hex: "#040A10")),
        gridColor: Color(UIColor(hex: "#64B5D9")),
        dotColors: [
            UIColor(hex: "#64B5D9"), // medical blue
            UIColor(hex: "#81C784"), // hospital mint
            UIColor(hex: "#EF9A9A"), // soft rose/red
            UIColor(hex: "#90CAF9"), // light blue
            UIColor(hex: "#A5D6A7")  // mint green
        ],
        accentColor: Color(UIColor(hex: "#64B5D9")),
        dotShape: .asset(named: "DoctorPing", fallbackSymbol: "stethoscope")
    )

    static let spacetravel = Theme(
        id: .spacetravel,
        name: "Space Travel" as LocalizedStringResource,
        unlockScore: nil,
        isPremium: true,
        productID: "com.optionalsankur.Dotto.premium",
        backgroundColor: Color(UIColor(hex: "#0b1e29")),
        gridColor: Color(UIColor(hex: "#143d4a")),
        dotColors: [
            UIColor(hex: "#f2bd55"),
            UIColor(hex: "#c9dbe5"),
            UIColor(hex: "#848fca"),
            UIColor(hex: "#b0d8e8"),
            UIColor(hex: "#e8a0aa")
        ],
        accentColor: Color(UIColor(hex: "#e07a8a")),
        dotShape: .asset(named: "star.fill", fallbackSymbol: "star.fill")
    )

    static let all: [Theme] = [.neon, .forest, .ocean, .cosmos, .aurora, .inferno, .doctorping, .spacetravel]

    static func theme(for id: ThemeID) -> Theme {
        all.first { $0.id == id } ?? .neon
    }
}
