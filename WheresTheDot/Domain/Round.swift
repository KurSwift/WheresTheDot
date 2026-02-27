//
//  Round.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation

struct Round: Equatable {
    let index: Int
    let dots: [Dot]
    let newDotID: UUID
}
