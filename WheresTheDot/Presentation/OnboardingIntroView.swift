//
//  OnboardingIntroView.swift
//  WheresTheDot
//

import SwiftUI

struct OnboardingIntroView: View {
    let onDismiss: () -> Void

    // Demo animation state
    @State private var dot1Scale: CGFloat = 0
    @State private var dot2Scale: CGFloat = 0
    @State private var newDotScale: CGFloat = 0
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            NeonGridBackground()

            VStack(spacing: 0) {
                Spacer()

                // Header
                VStack(spacing: 10) {
                    Text("How to Play")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Each round a new dot is added.\nFind and tap only the new one.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 52)

                demoArea

                Spacer()

                Button("Got it — Let's Play") {
                    FirebaseEventsManager.logOnboardingIntroDismissed()
                    onDismiss()
                }
                    .buttonStyle(DottoButtonStyle(kind: .classic))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 52)
            }
        }
        .task { await runAnimationLoop() }
    }

    // MARK: - Demo

    private var demoArea: some View {
        ZStack {
            // Existing dots (dim)
            dot(color: .neonPink, opacity: 0.7)
                .scaleEffect(dot1Scale)
                .offset(x: -52, y: 12)

            dot(color: .neonCyan, opacity: 0.7)
                .scaleEffect(dot2Scale)
                .offset(x: 44, y: -18)

            // New dot with ring hint
            ZStack {
                Circle()
                    .stroke(Color.neonCyan.opacity(ringOpacity), lineWidth: 2)
                    .frame(width: 54, height: 54)
                    .scaleEffect(ringScale)

                dot(color: .neonCyan, opacity: 0.9)
            }
            .scaleEffect(newDotScale)
            .offset(x: -8, y: 30)

            // Label
            if newDotScale > 0.5 {
                Text("new!")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.neonCyan.opacity(0.8))
                    .offset(x: 28, y: 50)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(width: 240, height: 160)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: newDotScale)
    }

    private func dot(color: Color, opacity: Double) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: 26, height: 26)
            .shadow(color: color.opacity(0.6), radius: 8)
    }

    // MARK: - Animation loop

    private func runAnimationLoop() async {
        while !Task.isCancelled {
            // Reset
            dot1Scale = 0; dot2Scale = 0; newDotScale = 0
            ringScale = 1.0; ringOpacity = 0

            try? await Task.sleep(nanoseconds: 400_000_000)

            // Existing dots pop in with a small stagger
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { dot1Scale = 1 }
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { dot2Scale = 1 }

            try? await Task.sleep(nanoseconds: 900_000_000)

            // New dot appears + ring shows
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { newDotScale = 1 }
            withAnimation(.easeIn(duration: 0.15)) { ringOpacity = 0.85 }

            try? await Task.sleep(nanoseconds: 500_000_000)

            // Ring expands and fades — the visual cue
            withAnimation(.easeOut(duration: 0.75)) {
                ringScale = 1.8
                ringOpacity = 0
            }

            try? await Task.sleep(nanoseconds: 1_600_000_000)

            // Fade everything out before looping
            withAnimation(.easeOut(duration: 0.35)) {
                dot1Scale = 0; dot2Scale = 0; newDotScale = 0
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
            ringScale = 1.0  // silent reset, no animation needed
        }
    }
}
