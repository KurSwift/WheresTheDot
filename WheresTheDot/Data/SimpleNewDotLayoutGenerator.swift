//
//  SimpleNewDotLayoutGenerator.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import CoreGraphics

final class SimpleNewDotLayoutGenerator: DotLayoutGenerating {
    private let rng: RandomNumberGenerating
    private let maxAttempts: Int

    init(rng: RandomNumberGenerating, maxAttempts: Int = 600) {
        self.rng = rng
        self.maxAttempts = maxAttempts
    }

    func generateNewPosition(
        existing: [CGPoint],
        in area: CGRect,
        radius: CGFloat,
        minDistance: CGFloat
    ) -> CGPoint? {
        let xmin = Int(area.minX + radius)
        let xmax = Int(area.maxX - radius)
        let ymin = Int(area.minY + radius)
        let ymax = Int(area.maxY - radius)

        guard xmin < xmax, ymin < ymax else { return nil }

        func ok(_ p: CGPoint) -> Bool {
            for q in existing {
                let dx = p.x - q.x
                let dy = p.y - q.y
                if (dx*dx + dy*dy) < (minDistance*minDistance) { return false }
            }
            return true
        }

        for _ in 0..<maxAttempts {
            let x = CGFloat(rng.nextInt(in: xmin...xmax))
            let y = CGFloat(rng.nextInt(in: ymin...ymax))
            let p = CGPoint(x: x, y: y)
            if ok(p) { return p }
        }

        return nil
    }
}
