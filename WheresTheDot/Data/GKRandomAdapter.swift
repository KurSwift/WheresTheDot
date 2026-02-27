//
//  GKRandomAdapter.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import GameplayKit

final class GKRandomAdapter: RandomNumberGenerating {
    private let source: GKRandomSource

    init(source: GKRandomSource = GKARC4RandomSource()) {
        self.source = source
    }

    func nextInt(in range: ClosedRange<Int>) -> Int {
        let dist = GKRandomDistribution(randomSource: source,
                                        lowestValue: range.lowerBound,
                                        highestValue: range.upperBound)
        return dist.nextInt()
    }
}
