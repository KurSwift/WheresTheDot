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
}

// MARK: - Theme

struct Theme {
    let id: ThemeID
    let name: String
    /// nil = always unlocked
    let unlockScore: Int?
    /// Dark base color for the scene/screen background
    let backgroundColor: Color
    /// Grid line color (SwiftUI + SpriteKit)
    let gridColor: Color
    /// Cycling palette used by GameScene for dot colors
    let dotColors: [UIColor]
    /// Accent color used in UI elements (progress bars, active badges)
    let accentColor: Color

    var isAlwaysUnlocked: Bool { unlockScore == nil }
}

// MARK: - Theme catalog

extension Theme {
    static let neon = Theme(
        id: .neon,
        name: "Neon",
        unlockScore: nil,
        backgroundColor: Color(UIColor(hex: "#05060A")),
        gridColor: .neonCyan,
        dotColors: [.neonCyan, .neonPink, .neonPurple, .neonLime, .neonOrange],
        accentColor: .neonCyan
    )

    static let forest = Theme(
        id: .forest,
        name: "Forest",
        unlockScore: 50,
        backgroundColor: Color(UIColor(hex: "#050D07")),
        gridColor: Color(UIColor(hex: "#4ADE80")),
        dotColors: [
            UIColor(hex: "#4ADE80"),
            UIColor(hex: "#22C55E"),
            UIColor(hex: "#FCD34D"),
            UIColor(hex: "#A3E635"),
            UIColor(hex: "#FBBF24")
        ],
        accentColor: Color(UIColor(hex: "#4ADE80"))
    )

    static let ocean = Theme(
        id: .ocean,
        name: "Ocean",
        unlockScore: 150,
        backgroundColor: Color(UIColor(hex: "#03080F")),
        gridColor: Color(UIColor(hex: "#22D3EE")),
        dotColors: [
            UIColor(hex: "#22D3EE"),
            UIColor(hex: "#3B82F6"),
            UIColor(hex: "#34D399"),
            UIColor(hex: "#F87171"),
            UIColor(hex: "#93C5FD")
        ],
        accentColor: Color(UIColor(hex: "#22D3EE"))
    )

    static let cosmos = Theme(
        id: .cosmos,
        name: "Cosmos",
        unlockScore: 350,
        backgroundColor: Color(UIColor(hex: "#080510")),
        gridColor: Color(UIColor(hex: "#A855F7")),
        dotColors: [
            UIColor(hex: "#A855F7"),
            UIColor(hex: "#818CF8"),
            UIColor(hex: "#E879F9"),
            UIColor(hex: "#F0ABFC"),
            UIColor(hex: "#FDE68A")
        ],
        accentColor: Color(UIColor(hex: "#A855F7"))
    )

    static let all: [Theme] = [.neon, .forest, .ocean, .cosmos]

    static func theme(for id: ThemeID) -> Theme {
        all.first { $0.id == id } ?? .neon
    }
}
