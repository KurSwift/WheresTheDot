//
//  AdaptiveLayoutTests.swift
//  WheresTheDotTests
//

import CoreGraphics
import Foundation
import Testing
@testable import WheresTheDot

private struct SystemRNG: RandomNumberGenerating {
    func nextInt(in range: ClosedRange<Int>) -> Int { Int.random(in: range) }
}

private func snapshot(dots: [Dot], isGameOver: Bool = false) -> GameSnapshot {
    GameSnapshot(roundIndex: dots.count, dots: dots, newDotID: dots.last?.id,
                 isGameOver: isGameOver, radius: 18, minDistance: 44)
}

struct AdaptiveLayoutTests {

    @Test func generatorNeverPlacesDotsInBlockedRegions() {
        let generator = SimpleNewDotLayoutGenerator(rng: SystemRNG())
        let area = CGRect(x: 0, y: 0, width: 400, height: 800)
        let camera = CGRect(x: 150, y: 0, width: 100, height: 80)
        let fold = CGRect(x: 0, y: 390, width: 400, height: 20)
        let radius: CGFloat = 18

        for _ in 0..<500 {
            let p = generator.generateNewPosition(existing: [], in: area, radius: radius,
                                                  minDistance: 44, avoiding: [camera, fold])
            let point = try! #require(p)
            #expect(!camera.insetBy(dx: -radius, dy: -radius).contains(point))
            #expect(!fold.insetBy(dx: -radius, dy: -radius).contains(point))
        }
    }

    @Test func relayoutKeepsRelativePositions() {
        let a = Dot(id: UUID(), position: CGPoint(x: 50, y: 100), radius: 18)
        let b = Dot(id: UUID(), position: CGPoint(x: 100, y: 200), radius: 18)
        let repo = InMemoryGameSessionRepository(initial: snapshot(dots: [a, b]))
        let relayout = RelayoutDotsUseCase(repo: repo, layout: SimpleNewDotLayoutGenerator(rng: SystemRNG()))

        let round = try! #require(relayout(from: CGRect(x: 0, y: 0, width: 100, height: 200),
                                           to: CGRect(x: 10, y: 0, width: 200, height: 100)))

        #expect(round.dots.map(\.id) == [a.id, b.id])
        #expect(round.newDotID == b.id)
        #expect(round.dots[0].position == CGPoint(x: 110, y: 50))
        #expect(round.dots[1].position == CGPoint(x: 210, y: 100))
        #expect(repo.load().dots == round.dots)
    }

    @Test func relayoutMovesDotsOutOfBlockedRegions() {
        let dot = Dot(id: UUID(), position: CGPoint(x: 200, y: 400), radius: 18)
        let repo = InMemoryGameSessionRepository(initial: snapshot(dots: [dot]))
        let relayout = RelayoutDotsUseCase(repo: repo, layout: SimpleNewDotLayoutGenerator(rng: SystemRNG()))
        let area = CGRect(x: 0, y: 0, width: 400, height: 800)
        let fold = CGRect(x: 0, y: 380, width: 400, height: 40)

        let round = try! #require(relayout(from: area, to: area, avoiding: [fold]))

        #expect(!fold.insetBy(dx: -18, dy: -18).contains(round.dots[0].position))
    }

    @Test func relayoutIgnoresFinishedGames() {
        let dot = Dot(id: UUID(), position: CGPoint(x: 20, y: 20), radius: 18)
        let repo = InMemoryGameSessionRepository(initial: snapshot(dots: [dot], isGameOver: true))
        let relayout = RelayoutDotsUseCase(repo: repo, layout: SimpleNewDotLayoutGenerator(rng: SystemRNG()))

        #expect(relayout(from: CGRect(x: 0, y: 0, width: 100, height: 100),
                         to: CGRect(x: 0, y: 0, width: 50, height: 50)) == nil)
    }
}
