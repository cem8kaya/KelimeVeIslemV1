//
//  PersistenceServiceTests.swift
//  KelimeVeIslemV1Tests
//

import XCTest
@testable import KelimeVeIslemV1

final class PersistenceServiceTests: XCTestCase {

    private var defaults: UserDefaults!
    private var service: PersistenceService!
    private let suiteName = "com.kelimeveislem.tests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        service = PersistenceService(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        service = nil
        super.tearDown()
    }

    private func makeResult(score: Int = 50) -> GameResult {
        GameResult(
            mode: .letters,
            score: score,
            duration: 30,
            details: .letters(word: "MASA", letters: ["M", "A", "S", "A"], isValid: true)
        )
    }

    // MARK: - Settings

    func testSettingsRoundtrip() throws {
        var settings = GameSettings.default
        settings.letterCount = 11
        try service.saveSettings(settings)
        XCTAssertEqual(service.loadSettings().letterCount, 11)
    }

    func testLoadSettingsFallsBackToDefault() {
        XCTAssertEqual(service.loadSettings().letterCount, GameSettings.default.letterCount)
    }

    // MARK: - Results & statistics

    func testSaveResultStoresResultAndUpdatesStatistics() throws {
        _ = try service.saveResult(makeResult(score: 70))

        let results = service.loadResults()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.score, 70)

        let stats = service.loadStatistics()
        XCTAssertEqual(stats.totalGamesPlayed, 1)
        XCTAssertEqual(stats.totalScore, 70)
    }

    func testResultsAreCappedAtMaximum() throws {
        for i in 0..<105 {
            _ = try service.saveResult(makeResult(score: i))
        }
        XCTAssertEqual(service.loadResults().count, 100)
        // newest first
        XCTAssertEqual(service.loadResults().first?.score, 104)
    }

    // MARK: - Export / import (deadlock regression)

    func testExportDataCompletesWithoutDeadlock() throws {
        // Regression: exportData used to nest queue.sync inside queue.sync and hung forever.
        _ = try service.saveResult(makeResult())

        let expectation = expectation(description: "export completes")
        DispatchQueue.global().async {
            _ = try? self.service.exportData()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    func testExportImportRoundtrip() throws {
        _ = try service.saveResult(makeResult(score: 42))
        var settings = GameSettings.default
        settings.letterCount = 12
        try service.saveSettings(settings)

        let data = try service.exportData()

        // Import into a fresh suite
        let otherSuite = "com.kelimeveislem.tests.import"
        let otherDefaults = UserDefaults(suiteName: otherSuite)!
        otherDefaults.removePersistentDomain(forName: otherSuite)
        defer { otherDefaults.removePersistentDomain(forName: otherSuite) }

        let otherService = PersistenceService(defaults: otherDefaults)
        try otherService.importData(from: data)

        XCTAssertEqual(otherService.loadResults().count, 1)
        XCTAssertEqual(otherService.loadResults().first?.score, 42)
        XCTAssertEqual(otherService.loadSettings().letterCount, 12)
    }

    // MARK: - Saved game state

    func testExpiredGameStateIsCleared() throws {
        let letterGame = LetterGame(letters: ["A", "B", "C"], language: .turkish)
        let state = SavedGameState(
            letterGame: letterGame,
            currentWord: "AB",
            timeRemaining: 30,
            score: 0,
            comboCount: 0
        )
        try service.saveGameState(state)
        XCTAssertNotNil(service.loadGameState())

        service.clearGameState()
        XCTAssertNil(service.loadGameState())
    }
}
