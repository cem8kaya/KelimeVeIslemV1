//
//  DailyChallengeTests.swift
//  KelimeVeIslemV1Tests
//

import XCTest
@testable import KelimeVeIslemV1

final class DailyChallengeTests: XCTestCase {

    // MARK: - SeededRandomGenerator

    func testSeededGeneratorIsDeterministic() {
        var a = SeededRandomGenerator(seed: 20260717)
        var b = SeededRandomGenerator(seed: 20260717)
        for _ in 0..<100 {
            XCTAssertEqual(a.next(), b.next())
        }
    }

    func testSeededShuffleIsDeterministic() {
        var a = SeededRandomGenerator(seed: 42)
        var b = SeededRandomGenerator(seed: 42)
        let input = Array(1...20)
        XCTAssertEqual(a.shuffle(input), b.shuffle(input))
    }

    func testDifferentSeedsProduceDifferentSequences() {
        var a = SeededRandomGenerator(seed: 1)
        var b = SeededRandomGenerator(seed: 2)
        let seqA = (0..<10).map { _ in a.next() }
        let seqB = (0..<10).map { _ in b.next() }
        XCTAssertNotEqual(seqA, seqB)
    }

    // MARK: - Challenge generation

    func testSameDateGeneratesSameChallenge() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let c1 = DailyChallenge(date: date, mode: .letters)
        let c2 = DailyChallenge(date: date, mode: .letters)

        guard case .letters(let l1) = c1.challengeData,
              case .letters(let l2) = c2.challengeData else {
            return XCTFail("expected letters challenge")
        }
        XCTAssertEqual(l1, l2, "same date must generate the same letters")
    }

    func testNumbersChallengeTargetInRange() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let challenge = DailyChallenge(date: date, mode: .numbers)
        guard case .numbers(let numbers, let target) = challenge.challengeData else {
            return XCTFail("expected numbers challenge")
        }
        XCTAssertEqual(numbers.count, 6)
        XCTAssertTrue((101...999).contains(target))
    }

    // MARK: - Streak logic

    private func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date()))!
    }

    private func result(on date: Date, score: Int = 50) -> DailyChallengeResult {
        DailyChallengeResult(challengeDate: date, score: score, duration: 30)
    }

    func testFirstCompletionStartsStreak() {
        var stats = DailyChallengeStats()
        stats.update(with: result(on: day(0)))
        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.longestStreak, 1)
        XCTAssertEqual(stats.totalChallengesCompleted, 1)
    }

    func testConsecutiveDaysExtendStreak() {
        var stats = DailyChallengeStats()
        stats.update(with: result(on: day(-2)))
        stats.update(with: result(on: day(-1)))
        stats.update(with: result(on: day(0)))
        XCTAssertEqual(stats.currentStreak, 3)
        XCTAssertEqual(stats.longestStreak, 3)
    }

    func testSkippedDayResetsStreak() {
        var stats = DailyChallengeStats()
        stats.update(with: result(on: day(-5)))
        stats.update(with: result(on: day(-4)))
        stats.update(with: result(on: day(0))) // gap
        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.longestStreak, 2)
    }

    func testBestAndAverageScore() {
        var stats = DailyChallengeStats()
        stats.update(with: result(on: day(-1), score: 40))
        stats.update(with: result(on: day(0), score: 100))
        XCTAssertEqual(stats.bestScore, 100)
        XCTAssertEqual(stats.averageScore, 70, accuracy: 0.001)
    }
}
