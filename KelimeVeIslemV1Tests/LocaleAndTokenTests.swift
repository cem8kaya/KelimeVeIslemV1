//
//  LocaleAndTokenTests.swift
//  KelimeVeIslemV1Tests
//

import XCTest
@testable import KelimeVeIslemV1

final class LocaleTests: XCTestCase {

    // MARK: - Turkish case conversion

    func testTurkishDottedIUppercases() {
        XCTAssertEqual("istanbul".gameUppercased(for: .turkish), "İSTANBUL")
        XCTAssertEqual("kedi".gameUppercased(for: .turkish), "KEDİ")
    }

    func testTurkishDotlessIUppercases() {
        XCTAssertEqual("ılık".gameUppercased(for: .turkish), "ILIK")
    }

    func testTurkishLowercasing() {
        XCTAssertEqual("İSTANBUL".gameLowercased(for: .turkish), "istanbul")
        XCTAssertEqual("ILIK".gameLowercased(for: .turkish), "ılık")
    }

    func testEnglishCaseConversionIsStandard() {
        XCTAssertEqual("ice".gameUppercased(for: .english), "ICE")
        XCTAssertEqual("ICE".gameLowercased(for: .english), "ice")
    }

    // MARK: - Locale-aware game flows

    func testLowercaseTurkishInputMatchesTiles() {
        let game = LetterGame(letters: ["K", "E", "D", "İ"], language: .turkish)
        // With plain uppercased() "kedi" became "KEDI" and failed to match "İ".
        XCTAssertTrue(game.canUseLetters("kedi"))
    }

    func testUpdateWordUsesTurkishLocale() {
        var game = LetterGame(letters: ["K", "E", "D", "İ"], language: .turkish)
        game.updateWord("kedi")
        XCTAssertEqual(game.playerWord, "KEDİ")
    }
}

final class SolutionTokenTests: XCTestCase {

    private func makeViewModel(numbers: [Int] = [100, 10, 5, 5], target: Int = 250) -> NumberGameViewModel {
        NumberGameViewModel(
            customGame: NumberGame(numbers: numbers, targetNumber: target),
            settings: .default
        )
    }

    func testTokensRenderToSolutionString() {
        let vm = makeViewModel()
        vm.appendToken(.number(value: 100, tileIndex: 0))
        vm.appendToken(.op("+"))
        vm.appendToken(.number(value: 10, tileIndex: 1))
        XCTAssertEqual(vm.currentSolution, "100+10")
        XCTAssertEqual(vm.usedNumberIndices, [0, 1])
    }

    func testDeleteRemovesWholeNumberAndFreesTile() {
        let vm = makeViewModel()
        vm.appendToken(.number(value: 100, tileIndex: 0))
        vm.appendToken(.op("+"))
        vm.appendToken(.number(value: 10, tileIndex: 1))

        // Regression: character-based delete turned "100" into "10" and
        // corrupted tile bookkeeping. Token delete removes the whole number.
        vm.deleteLastToken()
        XCTAssertEqual(vm.currentSolution, "100+")
        XCTAssertEqual(vm.usedNumberIndices, [0])

        vm.deleteLastToken() // removes "+"
        vm.deleteLastToken() // removes "100", frees tile 0
        XCTAssertEqual(vm.currentSolution, "")
        XCTAssertTrue(vm.usedNumberIndices.isEmpty)
    }

    func testDuplicateNumbersKeepDistinctTiles() {
        let vm = makeViewModel(numbers: [5, 5, 2])
        vm.appendToken(.number(value: 5, tileIndex: 0))
        vm.appendToken(.op("*"))
        vm.appendToken(.number(value: 5, tileIndex: 1))
        XCTAssertEqual(vm.usedNumberIndices, [0, 1])

        vm.removeLastToken()
        XCTAssertEqual(vm.usedNumberIndices, [0], "removing the second 5 must free tile 1, not tile 0")
    }

    func testTokenizeRebuildsMultiDigitNumbers() {
        let vm = makeViewModel(numbers: [100, 10, 5, 5])
        let tokens = vm.tokenize(solution: "100+10*5", numbers: [100, 10, 5, 5])
        XCTAssertEqual(tokens.map(\.text).joined(), "100+10*5")
        // 100 -> tile 0, 10 -> tile 1, first 5 -> tile 2
        XCTAssertEqual(
            tokens.compactMap { if case .number(_, let idx) = $0 { return idx } else { return nil } },
            [0, 1, 2]
        )
    }

    func testTokenizeAssignsDuplicateTilesGreedily() {
        let vm = makeViewModel(numbers: [5, 5, 2])
        let tokens = vm.tokenize(solution: "5*5", numbers: [5, 5, 2])
        XCTAssertEqual(
            tokens.compactMap { if case .number(_, let idx) = $0 { return idx } else { return nil } },
            [0, 1]
        )
    }

    func testClearSolutionFreesAllTiles() {
        let vm = makeViewModel()
        vm.appendToken(.number(value: 100, tileIndex: 0))
        vm.appendToken(.op("+"))
        vm.appendToken(.number(value: 10, tileIndex: 1))
        vm.clearSolution()
        XCTAssertEqual(vm.currentSolution, "")
        XCTAssertTrue(vm.usedNumberIndices.isEmpty)
    }
}
