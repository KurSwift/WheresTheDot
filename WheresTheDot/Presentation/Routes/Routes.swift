//
//  Routes.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation

enum AppRoute: Equatable {
    case mainMenu
    case arcadeBoard(world: Int)
    case game(GameMode)
    case settings
}

enum GameMode: Equatable, Hashable {
    case classic
    case timed
    case arcade(world: Int, level: Int)
    case daily(seed: UInt64)
}

struct LevelState: Equatable {
    var level: Int
    var nextLevelScore: Int
}
