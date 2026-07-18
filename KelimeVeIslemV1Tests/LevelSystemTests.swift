//
//  LevelSystemTests.swift
//  KelimeVeIslemV1Tests
//

import XCTest
@testable import KelimeVeIslemV1

@MainActor
final class LevelSystemTests: XCTestCase {

    private let system = LevelSystem.shared

    func testLevelOneRequiresZeroXP() {
        XCTAssertEqual(Level.allLevels.first?.xpRequired, 0)
        XCTAssertEqual(system.getLevel(for: 0).id, 1)
    }

    func testXPRequirementsAreStrictlyIncreasing() {
        let levels = Level.allLevels
        for i in 1..<levels.count {
            XCTAssertGreaterThan(levels[i].xpRequired, levels[i - 1].xpRequired,
                                 "level \(levels[i].id) must require more XP than level \(levels[i - 1].id)")
        }
    }

    func testGetLevelAtExactBoundary() {
        let level2 = Level.allLevels[1]
        XCTAssertEqual(system.getLevel(for: level2.xpRequired).id, 2)
        XCTAssertEqual(system.getLevel(for: level2.xpRequired - 1).id, 1)
    }

    func testCheckLevelUpDetectsCrossing() {
        let level2 = Level.allLevels[1]
        XCTAssertEqual(system.checkLevelUp(oldXP: 0, newXP: level2.xpRequired)?.id, 2)
        XCTAssertNil(system.checkLevelUp(oldXP: 0, newXP: level2.xpRequired - 1))
    }

    func testProgressToNextLevelIsBetweenZeroAndOne() {
        let level = system.getLevel(for: 150)
        let progress = system.progressToNextLevel(currentXP: 150, currentLevel: level)
        XCTAssertGreaterThanOrEqual(progress, 0)
        XCTAssertLessThanOrEqual(progress, 1)
    }

    // MARK: - XP calculation

    func testMinimumXPGuarantee() {
        XCTAssertEqual(system.calculateXP(score: 0, combo: 0, gameMode: .letters), 10)
    }

    func testDailyChallengeDoublesXP() {
        let base = system.calculateXP(score: 100, combo: 1, gameMode: .letters)
        let daily = system.calculateXP(score: 100, combo: 1, gameMode: .letters, isDailyChallenge: true)
        XCTAssertEqual(daily, base * 2)
    }

    func testComboAddsBonus() {
        let noCombo = system.calculateXP(score: 100, combo: 1, gameMode: .letters)
        let combo = system.calculateXP(score: 100, combo: 5, gameMode: .letters)
        XCTAssertEqual(combo - noCombo, 4 * 5) // (combo-1) * 5
    }

    // MARK: - GameStatistics integration

    func testStatisticsUpdateAccumulatesXPAndDetectsLevelUp() {
        var stats = GameStatistics()
        let details = GameResult.ResultDetails.letters(word: "KELIME", letters: ["K", "E", "L", "I", "M", "E"], isValid: true)

        var leveledUp: Level?
        // 100 XP per game minimum; level 2 requires 100 XP.
        for _ in 0..<3 {
            let result = GameResult(mode: .letters, score: 60, duration: 30, details: details)
            if let level = stats.update(with: result) {
                leveledUp = level
            }
        }

        XCTAssertEqual(stats.totalGamesPlayed, 3)
        XCTAssertGreaterThan(stats.totalXP, 0)
        XCTAssertNotNil(leveledUp, "180 XP should cross the 100 XP boundary for level 2")
    }
}
