//
//  ThemeCardView.swift
//  WheresTheDot
//

import SwiftUI

struct ThemeCardView: View {
    let theme: Theme
    let isActive: Bool
    let isUnlocked: Bool
    let cumulativeScore: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            FirebaseEventsManager.logThemeSelected(theme.id)
            onSelect()
        }) {
            VStack(spacing: 12) {
                dotPreview
                    .frame(height: 48)

                Text(theme.name)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                if isActive {
                    activeBadge
                } else if isUnlocked {
                    Text("Tap to apply")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                } else {
                    lockInfo
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isActive ? 0.10 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isActive ? theme.accentColor : Color.white.opacity(0.08), lineWidth: isActive ? 1.5 : 1)
                    )
            )
            .shadow(color: isActive ? theme.accentColor.opacity(0.25) : .clear, radius: 12)
        }
        .disabled(isActive || !isUnlocked)
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var dotPreview: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                let color = Color(theme.dotColors[i % theme.dotColors.count])
                Circle()
                    .fill(color.opacity(isUnlocked ? 0.9 : 0.3))
                    .frame(width: CGFloat(14 - i * 2), height: CGFloat(14 - i * 2))
                    .shadow(color: color.opacity(isUnlocked ? 0.6 : 0), radius: 6)
            }
        }
    }

    private var activeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11))
            Text("Active")
                .font(.system(size: 11, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(theme.accentColor)
    }

    private var lockInfo: some View {
        VStack(spacing: 6) {
            let milestone = theme.unlockScore ?? 0
            let progress = min(1.0, Double(cumulativeScore) / Double(milestone))

            Text("Earn \(milestone) lifetime pts")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(theme.accentColor.opacity(0.5))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 3)

            Text("Total: \(cumulativeScore) / \(milestone)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}
