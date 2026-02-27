//
//  DotLayoutGenerator.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import CoreGraphics

final class SimpleDotLayoutGenerator: DotLayoutGenerating {
    
    private let rng: RandomNumberGenerating

    init(rng: RandomNumberGenerating) {
        self.rng = rng
    }

    func generatePositions(count: Int, in area: CGRect, radius: CGFloat, minDistance: CGFloat) -> [CGPoint] {
        guard count > 0 else { return [] }

        var points: [CGPoint] = []
        let maxAttempts = 1500

        func isValid(_ p: CGPoint) -> Bool {
            for q in points {
                let dx = p.x - q.x
                let dy = p.y - q.y
                if (dx*dx + dy*dy) < (minDistance*minDistance) { return false }
            }
            return true
        }

        let xmin = Int(area.minX + radius)
        let xmax = Int(area.maxX - radius)
        let ymin = Int(area.minY + radius)
        let ymax = Int(area.maxY - radius)

        var attempts = 0
        while points.count < count && attempts < maxAttempts {
            attempts += 1
            let x = CGFloat(rng.nextInt(in: xmin...xmax))
            let y = CGFloat(rng.nextInt(in: ymin...ymax))
            let p = CGPoint(x: x, y: y)
            if isValid(p) { points.append(p) }
        }

        // If packing fails, return what we got (or relax minDistance later)
        return points
    }
}

extension SimpleDotLayoutGenerator {

    func generateNewPosition(
        existing: [CGPoint],
        in area: CGRect,
        radius: CGFloat,
        minDistance: CGFloat
    ) -> CGPoint? {

        // Prevent invalid bounds (e.g. too much inset)
        let xmin = area.minX + radius
        let xmax = area.maxX - radius
        let ymin = area.minY + radius
        let ymax = area.maxY - radius

        guard xmin < xmax, ymin < ymax else { return nil }

        let minDist2 = minDistance * minDistance
        let maxAttempts = 600

        func isValid(_ p: CGPoint) -> Bool {
            for q in existing {
                let dx = p.x - q.x
                let dy = p.y - q.y
                if (dx * dx + dy * dy) < minDist2 { return false }
            }
            return true
        }

        for _ in 0..<maxAttempts {
            let x = CGFloat(rng.nextInt(in: Int(xmin)...Int(xmax)))
            let y = CGFloat(rng.nextInt(in: Int(ymin)...Int(ymax)))
            let p = CGPoint(x: x, y: y)

            if isValid(p) { return p }
        }

        // Could not find a non-overlapping position within attempt limit.
        // You can return nil, or relax minDistance and retry (later).
        return nil
    }
}
