//
//  DuelCoordinator.swift
//  WheresTheDot
//

import Foundation
import CoreGraphics
internal import Combine

@MainActor
final class DuelCoordinator: ObservableObject {
    @Published private(set) var score: DuelScore

    private let start: StartGameUseCase
    private let resolve: ResolveDuelTapUseCase
    private let relayout: RelayoutDotsUseCase
    private var startedAt: Date?
    private var rounds = 0

    init(target: Int, container: AppContainer) {
        score = DuelScore(target: target)
        start = container.startGame
        resolve = container.resolveDuelTap
        relayout = container.relayoutDots
    }

    func startMatch(in area: CGRect, avoiding blocked: [CGRect]) -> Round {
        score = DuelScore(target: score.target)
        rounds = 0
        startedAt = Date()
        var round = start(in: area, avoiding: blocked)
        #if DEBUG
        // Screenshots: a match already in progress, points split between the players
        for i in 1..<ScreenshotSetup.prefilledDots {
            guard let result = resolve(tapped: round.newDotID, by: i.isMultiple(of: 2) ? .one : .two,
                                       score: score, in: area, avoiding: blocked),
                  let next = result.nextRound else { break }
            score = result.score
            round = next
        }
        #endif
        return round
    }

    func handleTap(_ id: UUID, by player: DuelPlayer, in area: CGRect, avoiding blocked: [CGRect]) -> DuelTapResult? {
        guard let result = resolve(tapped: id, by: player, score: score, in: area, avoiding: blocked) else { return nil }
        score = result.score
        rounds += 1
        if score.winner != nil {
            let duration = startedAt.map { Date().timeIntervalSince($0) } ?? 0
            FirebaseEventsManager.logDuelEnded(score: score, rounds: rounds, duration: duration)
            startedAt = nil
        }
        return result
    }

    func relayoutBoard(from old: CGRect, to new: CGRect, avoiding blocked: [CGRect]) -> Round? {
        relayout(from: old, to: new, avoiding: blocked)
    }

    /// Logs a quit only for a match still in progress.
    func quit() {
        guard startedAt != nil, score.winner == nil else { return }
        FirebaseEventsManager.logDuelQuit(score: score, rounds: rounds)
    }
}
