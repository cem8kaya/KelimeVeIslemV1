//
//  AchievementTests.swift
//  KelimeVeIslemV1Tests
//

import XCTest
@testable import KelimeVeIslemV1

@MainActor
final class AchievementTests: XCTestCase {

    private func letterResult(word: String, letters: [String], isValid: Bool, score: Int = 50, duration: Int = 45) -> GameResult {
        GameResult(
            mode: .letters,
            score: score,
            duration: duration,
            details: .letters(word: word, letters: letters, isValid: isValid)
        )
    }

    func testFirstGameUnlocksOnFirstResult() {
        var stats = GameStatistics()
        let result = letterResult(word: "MASA", letters: ["M", "A", "S", "A", "K"], isValid: true)
        _ = stats.update(with: result)

        var progress = AchievementProgress()
        let newly = AchievementTracker.evaluate(result: result, statistics: stats, progress: &progress)

        XCTAssertTrue(newly.contains { $0.id == "first_game" })
        XCTAssertTrue(newly.contains { $0.id == "first_valid_word" })
    }

    func testJumpingOverThresholdStillReportsUnlock() {
        // Regression: the old "== threshold" pattern missed unlocks when the
        // counter skipped past the exact threshold value.
        var stats = GameStatistics()
        stats.totalGamesPlayed = 60 // jumped straight past 1, 10 and 50

        let result = letterResult(word: "MASA", letters: ["M", "A", "S", "A"], isValid: false)
        var progress = AchievementProgress()
        let newly = AchievementTracker.evaluate(result: result, statistics: stats, progress: &progress)

        let ids = Set(newly.map { $0.id })
        XCTAssertTrue(ids.isSuperset(of: ["first_game", "games_10", "games_50"]))
        XCTAssertFalse(ids.contains("games_100"))
    }

    func testUseAllLettersUnlocks() {
        var stats = GameStatistics()
        let result = letterResult(word: "KALEM", letters: ["K", "A", "L", "E", "M"], isValid: true)
        _ = stats.update(with: result)

        var progress = AchievementProgress()
        let newly = AchievementTracker.evaluate(result: result, statistics: stats, progress: &progress)

        XCTAssertTrue(newly.contains { $0.id == "use_all_letters" })
    }

    func testInvalidWordDoesNotUnlockWordAchievements() {
        var stats = GameStatistics()
        let result = letterResult(word: "XYZQW", letters: ["X", "Y", "Z", "Q", "W"], isValid: false)
        _ = stats.update(with: result)

        var progress = AchievementProgress()
        let newly = AchievementTracker.evaluate(result: result, statistics: stats, progress: &progress)

        XCTAssertFalse(newly.contains { $0.id == "first_valid_word" })
        XCTAssertFalse(newly.contains { $0.id == "use_all_letters" })
    }

    func testComboAchievementsUnlockOnceAtThresholds() {
        var progress = AchievementProgress()

        XCTAssertTrue(AchievementTracker.evaluateCombo(5, progress: &progress).contains { $0.id == "combo_5" })
        // Already unlocked — must not report again
        XCTAssertTrue(AchievementTracker.evaluateCombo(6, progress: &progress).isEmpty)
        XCTAssertTrue(AchievementTracker.evaluateCombo(10, progress: &progress).contains { $0.id == "combo_10" })
    }

    func testDailyChallengeAchievements() {
        var stats = DailyChallengeStats()
        stats.totalChallengesCompleted = 1
        stats.currentStreak = 1

        var progress = AchievementProgress()
        let newly = AchievementTracker.evaluateDailyChallenge(stats: stats, progress: &progress)
        XCTAssertTrue(newly.contains { $0.id == "daily_first" })

        stats.currentStreak = 7
        let later = AchievementTracker.evaluateDailyChallenge(stats: stats, progress: &progress)
        XCTAssertTrue(later.contains { $0.id == "daily_streak_7" })
    }

    // MARK: - Statistics integrity

    func testInvalidWordDoesNotPolluteLongestWordOrValidCount() {
        var stats = GameStatistics()
        _ = stats.update(with: letterResult(word: "XYZQWERTYUIO", letters: [], isValid: false))

        XCTAssertEqual(stats.longestWord, "", "invalid words must not become the longest word")
        XCTAssertEqual(stats.validWordsCount, 0)
        XCTAssertEqual(stats.letterGamesPlayed, 1)
    }

    func testValidWordUpdatesLongestWordAndValidCount() {
        var stats = GameStatistics()
        _ = stats.update(with: letterResult(word: "KALEMLER", letters: [], isValid: true))

        XCTAssertEqual(stats.longestWord, "KALEMLER")
        XCTAssertEqual(stats.validWordsCount, 1)
    }

    func testSaveResultReturnsNewAchievements() throws {
        let suiteName = "com.kelimeveislem.tests.achievements"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = PersistenceService(defaults: defaults)
        let outcome = try service.saveResult(
            letterResult(word: "MASA", letters: ["M", "A", "S", "A", "K"], isValid: true)
        )

        XCTAssertTrue(outcome.newAchievements.contains { $0.id == "first_game" })
    }
}
