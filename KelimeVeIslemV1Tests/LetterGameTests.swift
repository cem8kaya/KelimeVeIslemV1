//
//  LetterGameTests.swift
//  KelimeVeIslemV1Tests
//

import XCTest
@testable import KelimeVeIslemV1

@MainActor
final class LetterGameTests: XCTestCase {

    // MARK: - canUseLetters

    func testWordUsingAvailableLettersIsAccepted() {
        let game = LetterGame(letters: ["M", "A", "S", "A", "K"], language: .turkish)
        XCTAssertTrue(game.canUseLetters("MASA"))
    }

    func testWordUsingAbsentLetterIsRejected() {
        let game = LetterGame(letters: ["M", "A", "S", "A", "K"], language: .turkish)
        XCTAssertFalse(game.canUseLetters("MASAL"))
    }

    func testLetterCannotBeUsedMoreOftenThanAvailable() {
        let game = LetterGame(letters: ["K", "A", "S"], language: .turkish)
        XCTAssertFalse(game.canUseLetters("KAAS"))
    }

    // MARK: - updateWord sanitization

    func testUpdateWordStripsWhitespaceAndNonLetters() {
        var game = LetterGame(letters: ["A", "B", "C"], language: .english)
        game.updateWord(" ab1c ")
        XCTAssertEqual(game.playerWord, "ABC")
    }

    // MARK: - Scoring

    func testValidFourLetterWordScoresBase() {
        var game = LetterGame(letters: ["M", "A", "S", "A"], language: .turkish)
        game.updateWord("MASA")
        game.validateAndScore(isValid: true)
        XCTAssertEqual(game.score, 40) // 4 letters * 10
    }

    func testRareLetterBonus() {
        var game = LetterGame(letters: ["Ş", "A", "K", "A"], language: .turkish)
        game.updateWord("ŞAKA")
        game.validateAndScore(isValid: true)
        XCTAssertEqual(game.score, 45) // 40 + 5 rare letter (Ş)
    }

    func testSevenLetterBonus() {
        var game = LetterGame(letters: ["K", "A", "L", "E", "M", "L", "E", "R"], language: .turkish)
        game.updateWord("KALEMLER")
        game.validateAndScore(isValid: true)
        // 8*10 + 20 (>=7 bonus) = 100
        XCTAssertEqual(game.score, 100)
    }

    func testInvalidWordScoresZero() {
        var game = LetterGame(letters: ["M", "A", "S", "A"], language: .turkish)
        game.updateWord("MASA")
        game.validateAndScore(isValid: false)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.isValid, false)
    }

    // MARK: - validate()

    func testValidateEmptyWord() {
        let game = LetterGame(letters: ["A", "B"], language: .english)
        XCTAssertEqual(game.validate(), LetterGame.ValidationResult.empty)
    }

    // MARK: - Codable roundtrip

    func testCodableRoundtripPreservesLetters() throws {
        var game = LetterGame(letters: ["K", "E", "D", "İ"], language: .turkish)
        game.updateWord("KEDİ")
        let data = try JSONEncoder().encode(game)
        let decoded = try JSONDecoder().decode(LetterGame.self, from: data)
        XCTAssertEqual(decoded.letters, game.letters)
        XCTAssertEqual(decoded.playerWord, "KEDİ")
    }

    // MARK: - LetterGenerator difficulty

    private let turkishVowels: Set<Character> = ["A", "E", "I", "İ", "O", "Ö", "U", "Ü"]

    func testHarderCombosProducesFewerVowels() {
        let generator = LetterGenerator()

        // count 10: normal -> Int(10*0.35)=3 vowels, harder -> Int(10*0.28)=2 vowels.
        let normal = generator.generateLetters(count: 10, language: .turkish, harderCombos: false)
        let harder = generator.generateLetters(count: 10, language: .turkish, harderCombos: true)

        XCTAssertEqual(normal.count, 10)
        XCTAssertEqual(harder.count, 10)
        XCTAssertEqual(normal.filter { turkishVowels.contains($0) }.count, 3)
        XCTAssertEqual(harder.filter { turkishVowels.contains($0) }.count, 2)
    }

    func testGeneratorAlwaysKeepsAtLeastTwoVowels() {
        let generator = LetterGenerator()
        // Even the hardest 6-letter set keeps the minimum of 2 vowels playable.
        let harder = generator.generateLetters(count: 6, language: .turkish, harderCombos: true)
        XCTAssertGreaterThanOrEqual(harder.filter { turkishVowels.contains($0) }.count, 2)
    }

    func testInvalidLetterCountReturnsEmpty() {
        let generator = LetterGenerator()
        XCTAssertTrue(generator.generateLetters(count: 5, language: .turkish).isEmpty)
        XCTAssertTrue(generator.generateLetters(count: 13, language: .turkish).isEmpty)
    }
}
