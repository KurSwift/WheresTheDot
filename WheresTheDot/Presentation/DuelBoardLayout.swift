//
//  DuelBoardLayout.swift
//  WheresTheDot
//

import CoreGraphics

/// Splits the scene between two players sitting at opposite edges. Player one's board lives in
/// the bottom (or left) half; `GameScene.mirrorsBoard` draws it again, mirrored through the
/// center, for player two. Coordinates are SpriteKit scene coordinates (origin bottom-left).
struct DuelBoardLayout: Equatable {
    let size: CGSize
    /// Players face each other across a vertical line (left/right halves).
    let sideBySide: Bool

    /// Splits along the fold when there is one (iPhone Duo inner display), otherwise across the long side.
    init(size: CGSize, fold: CGRect? = nil) {
        self.size = size
        if let fold {
            sideBySide = fold.height > fold.width
        } else {
            sideBySide = size.width > size.height
        }
    }

    /// Where player one's dots may go: clear of the screen edge and of the scoreboard band along the split.
    var playerOneArea: CGRect {
        let band: CGFloat = 100
        if sideBySide {
            return CGRect(x: 40, y: 40, width: size.width / 2 - 40 - band, height: size.height - 80)
        }
        // The scene runs under the vertical safe areas: keep clear of the Dynamic Island and home indicator
        return CGRect(x: 30, y: 70, width: size.width - 60, height: size.height / 2 - 70 - band)
    }

    func player(at point: CGPoint) -> DuelPlayer {
        let inFirstHalf = sideBySide ? point.x < size.width / 2 : point.y < size.height / 2
        return inFirstHalf ? .one : .two
    }

    func mirrored(_ rect: CGRect) -> CGRect {
        CGRect(x: size.width - rect.maxX, y: size.height - rect.maxY, width: rect.width, height: rect.height)
    }

    /// Reserved regions (cameras, fold) plus their mirror images, so neither copy of the board lands on them.
    func blocked(_ reserved: [CGRect]) -> [CGRect] {
        reserved + reserved.map(mirrored)
    }
}
