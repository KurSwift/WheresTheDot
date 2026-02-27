//
//  Color+Extensions.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 12/02/26.
//

import Foundation
import UIKit
import SwiftUI

extension Color {
    static let dottoBlack = Color(uiColor: UIColor.dottoBlack)
    static let dottoCard = Color(uiColor: UIColor.dottoCard)
    /// Use with low alpha (e.g. 0.08–0.18) for the neon grid.
    static let dottoGridNeon = Color(uiColor: UIColor.dottoGridNeon)

    // MARK: - DOTTO Neons

    static let neonCyan    = Color(uiColor: UIColor.neonCyan)
    static let neonMagenta = Color(uiColor: UIColor.neonMagenta)
    static let neonPurple  = Color(uiColor: UIColor.neonPurple)
    static let neonLime    = Color(uiColor: UIColor.neonLime)
    static let neonYellow  = Color(uiColor: UIColor.neonYellow)
    static let neonCoral   = Color(uiColor: UIColor.neonCoral)
    static let neonOrange = Color(uiColor: UIColor.neonOrange)
    static let neonPink   = Color(uiColor: UIColor.neonPink)

    // MARK: - States

    static let dottoSuccess = Color(uiColor: UIColor.dottoSuccess)
    static let dottoDanger  = Color(uiColor: UIColor.dottoDanger)
}

extension UIColor {

    // MARK: - DOTTO Neutrals

    static let dottoBlack = UIColor(hex: "#05060A")
    static let dottoCard  = UIColor(hex: "#0B1220")

    /// Use with low alpha (e.g. 0.08–0.18) for the neon grid.
    static let dottoGridNeon = UIColor(hex: "#00F2FF").withAlphaComponent(0.18)

    // MARK: - DOTTO Neons

    static let neonCyan    = UIColor(hex: "#00F2FF")
    static let neonMagenta = UIColor(hex: "#FF2BD6")
    static let neonPurple  = UIColor(hex: "#8A4DFF")
    static let neonLime    = UIColor(hex: "#B8FF3B")
    static let neonYellow  = UIColor(hex: "#FFD84A")
    static let neonCoral   = UIColor(hex: "#FF4D5E")
    static let neonOrange = UIColor(red: 1.00, green: 0.55, blue: 0.10, alpha: 1.0)
    static let neonPink   = UIColor(red: 1.00, green: 0.20, blue: 0.85, alpha: 1.0)

    // MARK: - States

    static let dottoSuccess = UIColor(hex: "#2BFFB8")
    static let dottoDanger  = UIColor(hex: "#FF3B30")
}

// MARK: - Hex initializer

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }

        // Supports RGB (6) only. Easy to extend to RGBA (8) if you want.
        guard hexSanitized.count == 6 else {
            self.init(white: 0.0, alpha: alpha)
            return
        }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}


