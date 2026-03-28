//
//  NeonGridView.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 12/02/26.
//

import Foundation
import SwiftUI

struct NeonGridBackground: View {
    var spacing: CGFloat = 44
    var majorEvery: Int = 5
    var lineWidth: CGFloat = 1
    var majorLineWidth: CGFloat = 1.5

    var color: Color = .neonCyan
    var backgroundColor: Color = .dottoBlack
    var minorOpacity: Double = 0.08
    var majorOpacity: Double = 0.14

    var glowRadius: CGFloat = 8
    var glowOpacity: Double = 0.20

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let cols = Int(ceil(size.width / spacing))
                let rows = Int(ceil(size.height / spacing))

                // --- minor lines ---
                var minor = Path()
                for i in 0...cols {
                    let x = CGFloat(i) * spacing
                    minor.move(to: CGPoint(x: x, y: 0))
                    minor.addLine(to: CGPoint(x: x, y: size.height))
                }
                for j in 0...rows {
                    let y = CGFloat(j) * spacing
                    minor.move(to: CGPoint(x: 0, y: y))
                    minor.addLine(to: CGPoint(x: size.width, y: y))
                }

                // glow pass
                context.addFilter(.shadow(color: color.opacity(glowOpacity),
                                          radius: glowRadius, x: 0, y: 0))
                context.stroke(minor, with: .color(color.opacity(minorOpacity)), lineWidth: lineWidth)

                // --- major lines ---
                var major = Path()
                for i in stride(from: 0, through: cols, by: majorEvery) {
                    let x = CGFloat(i) * spacing
                    major.move(to: CGPoint(x: x, y: 0))
                    major.addLine(to: CGPoint(x: x, y: size.height))
                }
                for j in stride(from: 0, through: rows, by: majorEvery) {
                    let y = CGFloat(j) * spacing
                    major.move(to: CGPoint(x: 0, y: y))
                    major.addLine(to: CGPoint(x: size.width, y: y))
                }

                // strong glow pass
                context.addFilter(.shadow(color: color.opacity(glowOpacity + 0.08),
                                          radius: glowRadius + 2, x: 0, y: 0))
                context.stroke(major, with: .color(color.opacity(majorOpacity)), lineWidth: majorLineWidth)
            }
            .background(backgroundColor)
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
