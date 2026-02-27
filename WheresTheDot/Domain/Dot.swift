//
//  Dot.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import CoreGraphics

struct Dot: Identifiable, Equatable, Hashable {
    let id: UUID
    let position: CGPoint
    let radius: CGFloat
}

