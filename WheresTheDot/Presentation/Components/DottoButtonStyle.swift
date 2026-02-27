//
//  DottoButtonStyle.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 12/02/26.
//

import Foundation
import SwiftUI

struct DottoButtonStyle: ButtonStyle {
    enum Kind {
        case classic, arcade, timeAttack, options
    }
    
    let kind: Kind
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 64)
            .contentShape(Capsule())
            .background {
                Capsule()
                    .fill(backgroundGradient)
                    .overlay {
                        // glossy highlight
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    }
            }
            .shadow(color: glowColor.opacity(configuration.isPressed ? 0.35 : 0.55),
                    radius: configuration.isPressed ? 8 : 14,
                    x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
    
    private var backgroundGradient: LinearGradient {
            switch kind {
            case .classic:
                return LinearGradient(colors: [.neonCyan.opacity(0.85), .neonCyan.opacity(0.65)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
            case .arcade:
                return LinearGradient(colors: [.neonOrange.opacity(0.85), .neonOrange.opacity(0.65)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)

            case .timeAttack:
                return LinearGradient(colors: [.neonMagenta.opacity(0.85), .neonMagenta.opacity(0.65)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)

            case .options:
                return LinearGradient(colors: [.neonPurple.opacity(0.85), .neonPurple.opacity(0.65)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }

        private var glowColor: Color {
            switch kind {
            case .arcade:    return .neonOrange
            case .classic:   return .neonCyan
            case .timeAttack:return .neonMagenta
            case .options:   return .neonPurple
            }
        }
}
