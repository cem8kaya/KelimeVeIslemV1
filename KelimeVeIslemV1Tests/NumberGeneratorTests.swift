//
//  NumberGeneratorTests.swift
//  KelimeVeIslemV1Tests
//

import XCTest
@testable import KelimeVeIslemV1

@MainActor
final class NumberGeneratorTests: XCTestCase {

    private let generator = NumberGenerator()

    func testGenerateNumbersCounts() {
        let numbers = generator.generateNumbers(smallCount: 4, largeCount: 2)
        XCTAssertEqual(numbers.count, 6)
        XCTAssertEqual(numbers.filter { $0 >= 25 }.count, 2)
        XCTAssertEqual(numbers.filter { $0 <= 10 }.count, 4)
    }

    func testLargeNumbersAreNotRepeated() {
        for _ in 0..<20 {
            let numbers = generator.generateNumbers(smallCount: 0, largeCount: 4)
            let large = numbers.filter { $0 >= 25 }
            XCTAssertEqual(Set(large).count, large.count, "large numbers must be unique")
        }
    }

    func testGenerateTargetRange() {
        for _ in 0..<50 {
            let target = generator.generateTarget()
            XCTAssertTrue((101...999).contains(target))
        }
    }

    func testFindSolutionForSolvableCase() throws {
        let numbers = [4, 25]
        let solution = try XCTUnwrap(generator.findSolution(numbers: numbers, target: 100))
        XCTAssertFalse(solution.isEmpty)
        verifyOperationsAreConsistent(solution)
        XCTAssertEqual(solution.last?.result, 100)
    }

    func testFindSolutionWhenTargetAlreadyInPool() {
        // target already available -> empty operation list is a valid "solution"
        let solution = generator.findSolution(numbers: [7, 100], target: 100)
        XCTAssertNotNil(solution)
        XCTAssertEqual(solution?.isEmpty, true)
    }

    func testIterativeDeepeningPrefersShortestSolution() throws {
        // 2*3 = 6 in a single operation; deeper detours must not win.
        let solution = try XCTUnwrap(generator.findSolution(numbers: [2, 3, 4], target: 6))
        XCTAssertEqual(solution.count, 1)
    }

    func testFindClosestSolutionReturnsSomething() throws {
        let (closest, ops) = try XCTUnwrap(
            generator.findClosestSolution(numbers: [1, 2, 3], target: 999)
        )
        verifyOperationsAreConsistent(ops)
        XCTAssertLessThanOrEqual(abs(999 - closest), 999)
    }

    // Each recorded operation must be internally consistent.
    // (Qualified type: Foundation.Operation shadows the game's Operation here.)
    private func verifyOperationsAreConsistent(_ operations: [KelimeVeIslemV1.Operation]) {
        for op in operations {
            let a = op.operand1
            let b = op.operand2
            let expected: Int?
            switch op.operation {
            case "+": expected = a + b
            case "−", "-": expected = abs(a - b)
            case "×", "*": expected = a * b
            case "÷", "/": expected = b != 0 && a % b == 0 ? a / b : nil
            default: expected = nil
            }
            XCTAssertEqual(expected, op.result, "inconsistent operation: \(op.description)")
        }
    }
}
