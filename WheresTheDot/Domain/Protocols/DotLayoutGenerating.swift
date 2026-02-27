//
//  DotLayoutGenerating.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import CoreGraphics

protocol DotLayoutGenerating {
    func generateNewPosition(
        existing: [CGPoint],
        in area: CGRect,
        radius: CGFloat,
        minDistance: CGFloat
    ) -> CGPoint?
}
