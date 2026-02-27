//
//  StartGameUseCase.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import CoreGraphics

struct StartGameUseCase {
    let repo: GameSessionRepository
    let layout: DotLayoutGenerating

    func callAsFunction(in area: CGRect) -> Round {
        let radius: CGFloat = 18
        let minDistance: CGFloat = 44

        let firstPos = layout.generateNewPosition(
            existing: [],
            in: area,
            radius: radius,
            minDistance: minDistance
        ) ?? CGPoint(x: area.midX, y: area.midY)

        let firstDot = Dot(id: UUID(), position: firstPos, radius: radius)

        var snap = GameSnapshot(
            roundIndex: 1,
            dots: [firstDot],
            newDotID: firstDot.id,
            isGameOver: false,
            radius: radius,
            minDistance: minDistance
        )

        repo.reset(snap)

        return Round(index: snap.roundIndex, dots: snap.dots, newDotID: firstDot.id)
    }
}
