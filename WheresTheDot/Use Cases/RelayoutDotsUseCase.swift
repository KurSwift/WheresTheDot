//
//  RelayoutDotsUseCase.swift
//  WheresTheDot
//

import Foundation
import CoreGraphics

/// Moves the current board into a new play area when the window changes size mid-game
/// (iPhone Duo fold/unfold, iPad resizing). Dots keep their relative positions so the
/// player's memory of the board still holds; a dot that lands on a blocked region
/// (camera cutout, fold) is moved to the nearest free spot the generator finds.
struct RelayoutDotsUseCase {
    let repo: GameSessionRepository
    let layout: DotLayoutGenerating

    func callAsFunction(from old: CGRect, to new: CGRect, avoiding blocked: [CGRect] = []) -> Round? {
        var snap = repo.load()
        guard !snap.isGameOver, let newID = snap.newDotID,
              old.width > 0, old.height > 0, old != new || !blocked.isEmpty else { return nil }

        var placed: [CGPoint] = []
        // ponytail: proportional scaling can squeeze dots below minDistance on a much
        // shorter display; accept slight overlap rather than reshuffling the board.
        snap.dots = snap.dots.map { dot in
            let fx: CGFloat = (dot.position.x - old.minX) / old.width
            let fy: CGFloat = (dot.position.y - old.minY) / old.height
            var p = CGPoint(x: new.minX + fx * new.width, y: new.minY + fy * new.height)
            let hitsBlocked = blocked.contains { $0.insetBy(dx: -dot.radius, dy: -dot.radius).contains(p) }
            if hitsBlocked, let free = layout.generateNewPosition(
                existing: placed, in: new, radius: dot.radius,
                minDistance: snap.minDistance, avoiding: blocked
            ) {
                p = free
            }
            placed.append(p)
            return Dot(id: dot.id, position: p, radius: dot.radius)
        }

        repo.save(snap)
        return Round(index: snap.roundIndex, dots: snap.dots, newDotID: newID)
    }
}
