//
//  RecordBestScoreUseCaseTests.swift
//  WheresTheDotTests
//

import Testing
@testable import WheresTheDot

private final class FakeScoreRepository: ScoreRepository {
    var bests: [String: Int] = [:]

    func bestScore(for mode: GameMode) -> Int { bests["\(mode)"] ?? 0 }
    func setBestScore(_ score: Int, for mode: GameMode) { bests["\(mode)"] = score }
}

struct RecordBestScoreUseCaseTests {

    @Test func firstGameSetsBestWithoutPreviousRecord() {
        let repo = FakeScoreRepository()
        let result = RecordBestScoreUseCase(repo: repo)(score: 7, mode: .classic)

        #expect(result == BestScoreResult(best: 7, previousBest: 0))
        #expect(result.isNewBest)
        #expect(repo.bestScore(for: .classic) == 7)
    }

    @Test func higherScoreReplacesBest() {
        let repo = FakeScoreRepository()
        repo.setBestScore(10, for: .classic)
        let result = RecordBestScoreUseCase(repo: repo)(score: 12, mode: .classic)

        #expect(result.isNewBest)
        #expect(result.previousBest == 10)
        #expect(repo.bestScore(for: .classic) == 12)
    }

    @Test func lowerOrEqualScoreKeepsBest() {
        let repo = FakeScoreRepository()
        repo.setBestScore(10, for: .classic)
        let useCase = RecordBestScoreUseCase(repo: repo)

        #expect(!useCase(score: 4, mode: .classic).isNewBest)
        #expect(!useCase(score: 10, mode: .classic).isNewBest)
        #expect(repo.bestScore(for: .classic) == 10)
    }

    @Test func modesKeepSeparateBests() {
        let repo = FakeScoreRepository()
        let useCase = RecordBestScoreUseCase(repo: repo)
        _ = useCase(score: 20, mode: .classic)
        let arcade = useCase(score: 5, mode: .arcade)

        #expect(arcade.isNewBest)
        #expect(arcade.best == 5)
        #expect(repo.bestScore(for: .classic) == 20)
    }
}
