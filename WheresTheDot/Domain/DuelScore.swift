//
//  DuelScore.swift
//  WheresTheDot
//

import Foundation

/// The two players of a same-device duel. Player one sits at the bottom (or left) edge.
enum DuelPlayer: Int, Equatable {
    case one = 1, two = 2

    var rival: DuelPlayer { self == .one ? .two : .one }
}

/// First-to-`target` scoreboard for a duel.
struct DuelScore: Equatable {
    let target: Int
    private(set) var one = 0
    private(set) var two = 0

    init(target: Int) {
        self.target = max(1, target)
    }

    func points(for player: DuelPlayer) -> Int {
        player == .one ? one : two
    }

    var winner: DuelPlayer? {
        if one >= target { return .one }
        if two >= target { return .two }
        return nil
    }

    mutating func award(_ player: DuelPlayer) {
        guard winner == nil else { return }
        if player == .one { one += 1 } else { two += 1 }
    }
}
