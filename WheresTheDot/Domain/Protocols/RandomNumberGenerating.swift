//
//  RandomNumberGenerating.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation

protocol RandomNumberGenerating {
    func nextInt(in range: ClosedRange<Int>) -> Int
}
