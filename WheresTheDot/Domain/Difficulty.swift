//
//  Difficulty.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import CoreGraphics

struct Difficulty: Equatable {
    var dotCount: Int
    var radius: CGFloat
    var showTime: TimeInterval
    var minDistance: CGFloat
    var timeLimit: TimeInterval?
}

enum PlayerAction: Equatable {
    case selectedDot(UUID)
    case timedOut
}

enum RoundOutcome: Equatable {
    case correct(newDotID: UUID)
    case wrong(chosenID: UUID, newDotID: UUID)
    case noSelection(newDotID: UUID)
}
