//
//  NumberGameTests.swift
//  KelimeVeIslemV1Tests
//

import XCTest
@testable import KelimeVeIslemV1

@MainActor
final class NumberGameTests: XCTestCase {

    private func makeGame(numbers: [Int] = [1, 2, 3, 4, 25, 50], target: Int = 100) -> NumberGame {
        NumberGame(numbers: numbers, targetNumber: target)
    }

    // MARK: - Expression evaluation

    func testSimpleAddition() throws {
        let game = makeGame()
        XCTAssertEqual(try game.evaluateExpression("2+3"), 5)
    }

    func testOperatorPrecedence() throws {
        let game = makeGame()
        XCTAssertEqual(try game.evaluateExpression("2+3*4"), 14)
    }

    func testParentheses() throws {
        let game = makeGame()
        XCTAssertEqual(try game.evaluateExpression("(2+3)*4"), 20)
    }

    func testUnicodeOperatorsAreNormalized() throws {
        let game = makeGame()
        XCTAssertEqual(try game.evaluateExpression("3×4"), 12)
        XCTAssertEqual(try game.evaluateExpression("12÷4"), 3)
        XCTAssertEqual(try game.evaluateExpression("9−4"), 5)
    }

    func testExactDivision() throws {
        let game = makeGame()
        XCTAssertEqual(try game.evaluateExpression("100/4"), 25)
    }

    func testDivisionByZeroThrows() {
        let game = makeGame()
        XCTAssertThrowsError(try game.evaluateExpression("5/0"))
    }

    // MARK: - Classic Countdown rules (integer arithmetic)

    func testNonExactDivisionThrows() {
        let game = makeGame()
        // 7/2 = 3.5 used to be silently truncated to 3; now it's invalid.
        XCTAssertThrowsError(try game.evaluateExpression("7/2"))
        XCTAssertThrowsError(try game.evaluateExpression("7/2*4"))
    }

    func testNegativeIntermediateResultThrows() {
        let game = makeGame()
        XCTAssertThrowsError(try game.evaluateExpression("3-5"))
        XCTAssertThrowsError(try game.evaluateExpression("(3-5)+10"))
    }

    func testNonNegativeSubtractionIsAllowed() throws {
        let game = makeGame()
        XCTAssertEqual(try game.evaluateExpression("5-3+1"), 3)
        XCTAssertEqual(try game.evaluateExpression("5-5"), 0)
    }

    func testUnaryMinusIsRejected() {
        let game = makeGame()
        XCTAssertThrowsError(try game.evaluateExpression("-5+10"))
    }

    func testEmptyExpressionThrows() {
        let game = makeGame()
        XCTAssertThrowsError(try game.evaluateExpression(""))
    }

    func testInvalidCharactersThrow() {
        let game = makeGame()
        XCTAssertThrowsError(try game.evaluateExpression("2+abc"))
    }

    func testMissingClosingParenthesisThrows() {
        let game = makeGame()
        XCTAssertThrowsError(try game.evaluateExpression("(2+3"))
    }

    // MARK: - Number availability

    func testSolutionUsingAvailableNumbersScores() throws {
        var game = makeGame(numbers: [4, 25], target: 100)
        game.updateSolution("4*25")
        try game.evaluateAndScore()
        XCTAssertEqual(game.playerResult, 100)
        XCTAssertEqual(game.score, 100) // perfect match
    }

    func testSolutionUsingUnavailableNumberThrows() {
        var game = makeGame(numbers: [4, 25], target: 100)
        game.updateSolution("10*10")
        XCTAssertThrowsError(try game.evaluateAndScore())
    }

    func testNumberCannotBeReused() {
        var game = makeGame(numbers: [4, 25], target: 100)
        game.updateSolution("4*4*25")
        XCTAssertThrowsError(try game.evaluateAndScore())
    }

    func testDuplicatePoolNumbersCanEachBeUsedOnce() throws {
        var game = makeGame(numbers: [5, 5, 2], target: 27)
        game.updateSolution("5*5+2")
        try game.evaluateAndScore()
        XCTAssertEqual(game.playerResult, 27)
    }

    // MARK: - Scoring bands

    func testScoreBands() throws {
        // difference 0 -> 100
        var exact = makeGame(numbers: [10, 10], target: 100)
        exact.updateSolution("10*10")
        try exact.evaluateAndScore()
        XCTAssertEqual(exact.score, 100)

        // difference 2 -> 80 - 2*10 = 60
        var close = makeGame(numbers: [10, 10], target: 102)
        close.updateSolution("10*10")
        try close.evaluateAndScore()
        XCTAssertEqual(close.score, 60)

        // difference 8 -> 50 - 8*3 = 26
        var medium = makeGame(numbers: [10, 10], target: 108)
        medium.updateSolution("10*10")
        try medium.evaluateAndScore()
        XCTAssertEqual(medium.score, 26)

        // difference 30 -> 0
        var far = makeGame(numbers: [10, 10], target: 130)
        far.updateSolution("10*10")
        try far.evaluateAndScore()
        XCTAssertEqual(far.score, 0)
    }
}
