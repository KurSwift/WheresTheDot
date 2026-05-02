//
//  Routes.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation

enum AppRoute: Equatable {
    case mainMenu
    case game(GameMode)
    case settings
    case themes
    case store
    case admin
}

enum GameMode: Equatable, Hashable {
    case classic
    case arcade
    case daily(seed: UInt64)
}

struct LevelState: Equatable {
    var level: Int
    var nextLevelScore: Int
}
