//
//  GameSnapshot.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import CoreGraphics

struct GameSnapshot: Equatable {
    var roundIndex: Int
    var dots: [Dot]
    var newDotID: UUID?
    var isGameOver: Bool
    
    var radius: CGFloat
    var minDistance: CGFloat

    var score: Int { dots.count } // score = number of dots on screen
    var level: LevelState?
    var difficulty: Difficulty?
}
