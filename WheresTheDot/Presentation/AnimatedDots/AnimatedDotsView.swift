//
//  AnimatedDotsView.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 12/02/26.
//

import Foundation
import SwiftUI

struct AnimatedDotsView: View {
    struct Dot: Identifiable {
        let id = UUID()
        let x: CGFloat   // 0...1
        let y: CGFloat   // 0...1
        let color: Color
        let size: CGFloat
    }
    
    // Config
    let dotCount: Int = 6
    let areaHeight: CGFloat = 400
    let spawnDelay: Duration = .milliseconds(260)
    let showAfterLast: Duration = .milliseconds(650)
    let fadeOutDuration: Duration = .milliseconds(250)
    
    @State private var dots: [Dot] = []
    @State private var visibleCount: Int = 0
    @State private var opacity: Double = 1.0
    @State private var loopTask: Task<Void, Never>?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(dots.enumerated()), id: \.element.id) { index, dot in
                    Circle()
                        .fill(dot.color)
                        .frame(width: dot.size, height: dot.size)
                        .shadow(color: dot.color.opacity(0.6), radius: 10, x: 0, y: 0)
                        .position(
                            x: dot.x * geo.size.width,
                            y: dot.y * geo.size.height
                        )
                        .opacity(index < visibleCount ? 1 : 0)
                        .scaleEffect(index < visibleCount ? 1 : 0.65)
                        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: visibleCount)
                }
            }
            .opacity(opacity)
            .onAppear {
                // Start loop once
                loopTask?.cancel()
                loopTask = Task { await runLoop() }
            }
            .onDisappear {
                loopTask?.cancel()
                loopTask = nil
            }
        }
        .frame(height: areaHeight)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .ignoresSafeArea()
    }
    
    // MARK: - Loop
    
    @MainActor
    private func runLoop() async {
        while !Task.isCancelled {
            // Build a new “pattern”
            let colors: [Color] = [.neonCyan, .neonMagenta, .white, .neonLime, .neonPurple, .neonYellow]
            
            dots = makeDots(count: dotCount, color: colors.randomElement() ?? Color.neonCyan)
            visibleCount = 0
            opacity = 1.0
            
            // Spawn one by one
            for i in 1...dots.count {
                visibleCount = i
                try? await Task.sleep(for: spawnDelay)
                if Task.isCancelled { return }
            }
            
            // Hold after last appears
            try? await Task.sleep(for: showAfterLast)
            if Task.isCancelled { return }
            
            // Fade all out
            withAnimation(.easeOut(duration: fadeOutDuration.timeInterval)) {
                opacity = 0.0
            }
            try? await Task.sleep(for: fadeOutDuration)
            if Task.isCancelled { return }
            
            // Small pause before next loop
            try? await Task.sleep(for: .milliseconds(200))
        }
    }
    
    // MARK: - Dot generation
    
    private func makeDots(count: Int, color: Color = Color.neonCyan) -> [Dot] {
        // Palette DOTTO (ajústala a tu gusto)
        let colors: [Color] = [.neonCyan, .neonMagenta, .white, .neonLime, .neonPurple, .neonYellow]
        
        // Constrain the dots to a “nice” band (so they don’t touch edges)
        // x: 10%..90%, y: 15%..85%
        func r(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
            CGFloat.random(in: min...max)
        }
        
        // Optional: keep a minimum distance so they don’t overlap
        var result: [Dot] = []
        let minDist: CGFloat = 0.18 // normalized distance in 0..1 space
        let maxAttempts = 200
        
        for idx in 0..<count {
            var attempt = 0
            var candidate: Dot?
            
            while attempt < maxAttempts {
                let x = r(0.12, 0.88)
                let y = r(0.18, 0.82)
                let size = r(34, 44)
                
                let d = Dot(x: x, y: y, color: color, size: size)
                
                if isFarEnough(d, from: result, minDist: minDist) {
                    candidate = d
                    break
                }
                attempt += 1
            }
            
            result.append(candidate ?? Dot(x: r(0.12, 0.88), y: r(0.18, 0.82), color: colors[idx % colors.count], size: r(34, 44)))
        }
        
        return result
    }
    
    private func isFarEnough(_ dot: Dot, from others: [Dot], minDist: CGFloat) -> Bool {
        for o in others {
            let dx = dot.x - o.x
            let dy = dot.y - o.y
            if (dx*dx + dy*dy) < (minDist * minDist) { return false }
        }
        return true
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        // approximate conversion for animations
        let components = self.components
        return TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}

#Preview {
    AnimatedDotsView()
}
