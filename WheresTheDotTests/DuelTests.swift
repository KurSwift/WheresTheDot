//
//  DuelTests.swift
//  WheresTheDotTests
//

import CoreGraphics
import Foundation
import Testing
@testable import WheresTheDot

private struct SystemRNG: RandomNumberGenerating {
    func nextInt(in range: ClosedRange<Int>) -> Int { Int.random(in: range) }
}

private func makeDuel() -> (StartGameUseCase, ResolveDuelTapUseCase) {
    let repo = InMemoryGameSessionRepository(initial: GameSnapshot(
        roundIndex: 0, dots: [], newDotID: nil, isGameOver: false, radius: 18, minDistance: 44))
    let layout = SimpleNewDotLayoutGenerator(rng: SystemRNG())
    let addDot = AddDotIfCorrectUseCase(repo: repo, layout: layout)
    return (StartGameUseCase(repo: repo, layout: layout), ResolveDuelTapUseCase(repo: repo, addDot: addDot))
}

struct DuelTests {
    let area = CGRect(x: 0, y: 0, width: 400, height: 400)

    @Test func correctTapScoresAndGrowsBoard() throws {
        let (start, resolve) = makeDuel()
        let first = start(in: area)

        let result = try #require(resolve(tapped: first.newDotID, by: .two, score: DuelScore(target: 5), in: area))

        #expect(result.scorer == .two && result.wasCorrect)
        #expect(result.score.points(for: .two) == 1)
        let next = try #require(result.nextRound)
        #expect(next.dots.count == 2 && next.newDotID != first.newDotID)
    }

    @Test func wrongTapScoresForRivalAndBoardStillGrows() throws {
        let (start, resolve) = makeDuel()
        let first = start(in: area)
        let second = try #require(resolve(tapped: first.newDotID, by: .one, score: DuelScore(target: 5), in: area))

        // Player one taps the old dot instead of the new one
        let result = try #require(resolve(tapped: first.newDotID, by: .one, score: second.score, in: area))

        #expect(result.scorer == .two && !result.wasCorrect)
        #expect(result.correctDotID == second.nextRound?.newDotID)
        #expect(result.score.points(for: .one) == 1 && result.score.points(for: .two) == 1)
        #expect(result.nextRound?.dots.count == 3)
    }

    @Test func reachingTargetEndsMatch() throws {
        let (start, resolve) = makeDuel()
        let first = start(in: area)

        let result = try #require(resolve(tapped: first.newDotID, by: .one, score: DuelScore(target: 1), in: area))

        #expect(result.score.winner == .one)
        #expect(result.nextRound == nil)
        #expect(resolve(tapped: first.newDotID, by: .two, score: result.score, in: area) == nil)
    }

    @Test func layoutSplitsAlongFoldOrLongSide() {
        let tall = DuelBoardLayout(size: CGSize(width: 400, height: 800))
        #expect(!tall.sideBySide)
        #expect(tall.player(at: CGPoint(x: 200, y: 100)) == .one)
        #expect(tall.player(at: CGPoint(x: 200, y: 700)) == .two)
        #expect(tall.playerOneArea.maxY < 400)

        let wide = DuelBoardLayout(size: CGSize(width: 800, height: 400))
        #expect(wide.sideBySide)
        #expect(wide.player(at: CGPoint(x: 700, y: 200)) == .two)
        #expect(wide.playerOneArea.maxX < 400)

        // A vertical fold on a near-square display decides the split, not the aspect ratio
        let folded = DuelBoardLayout(size: CGSize(width: 700, height: 720), fold: CGRect(x: 345, y: 0, width: 10, height: 720))
        #expect(folded.sideBySide)

        let camera = CGRect(x: 10, y: 20, width: 30, height: 40)
        #expect(tall.blocked([camera]) == [camera, CGRect(x: 360, y: 740, width: 30, height: 40)])
    }
}
