//
//  NumberGenerator.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  NumberGenerator.swift
//  KelimeVeIslem
//

import Foundation

class NumberGenerator {
    
    private let smallNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    private let largeNumbers = [25, 50, 75, 100]
    
    func generateNumbers(smallCount: Int = 4, largeCount: Int = 2) -> [Int] {
        var numbers: [Int] = []
        
        // Add small numbers (with possible repetition)
        for _ in 0..<smallCount {
            if let number = smallNumbers.randomElement() {
                numbers.append(number)
            }
        }
        
        // Add large numbers (no repetition)
        var availableLarge = largeNumbers
        for _ in 0..<largeCount {
            if let number = availableLarge.randomElement() {
                numbers.append(number)
                availableLarge.removeAll { $0 == number }
            }
        }
        
        return numbers.shuffled()
    }
    
    func generateTarget() -> Int {
        return Int.random(in: 101...999)
    }
    
    func generateGame(difficulty: GameSettings.DifficultyLevel) -> (numbers: [Int], target: Int) {
        let config = difficulty.numberConfig
        let numbers = generateNumbers(smallCount: config.small, largeCount: config.large)
        let target = generateTarget()
        return (numbers, target)
    }
    
    // MARK: - Solver (Helper to find solutions)
    
    func findSolution(numbers: [Int], target: Int, maxDepth: Int = 4) -> [Operation]? {
        return solve(available: numbers, target: target, operations: [], depth: 0, maxDepth: maxDepth)
    }
    
    private func solve(available: [Int], target: Int, operations: [Operation], depth: Int, maxDepth: Int) -> [Operation]? {
        // Base case: found exact match
        if available.contains(target) {
            return operations
        }
        
        // Depth limit
        if depth >= maxDepth || available.count < 2 {
            return nil
        }
        
        // Try all pairs of numbers
        for i in 0..<available.count {
            for j in (i+1)..<available.count {
                let a = available[i]
                let b = available[j]
                
                // Try all operations
                var possibleResults: [(result: Int, op: String)] = [
                    (a + b, "+"),
                    (abs(a - b), "−"),
                    (a * b, "×"),
                ]
                
                // Division (if valid)
                if b != 0 && a % b == 0 {
                    possibleResults.append((a / b, "÷"))
                }
                if a != 0 && b % a == 0 {
                    possibleResults.append((b / a, "÷"))
                }
                
                for (result, op) in possibleResults {
                    // Create new available list
                    var newAvailable = available
                    newAvailable.remove(at: j)
                    newAvailable.remove(at: i)
                    newAvailable.append(result)
                    
                    // Create operation record
                    let operation = Operation(
                        operand1: max(a, b),
                        operand2: min(a, b),
                        operation: op,
                        result: result
                    )
                    
                    // Recurse
                    if let solution = solve(
                        available: newAvailable,
                        target: target,
                        operations: operations + [operation],
                        depth: depth + 1,
                        maxDepth: maxDepth
                    ) {
                        return solution
                    }
                }
            }
        }
        
        return nil
    }
    
    func findClosestSolution(numbers: [Int], target: Int) -> (closest: Int, operations: [Operation])? {
        var bestDiff = Int.max
        var bestResult: (Int, [Operation])? = nil
        
        // Try to find solutions at different depths
        for depth in 1...4 {
            if let solution = findClosestAtDepth(
                available: numbers,
                target: target,
                operations: [],
                depth: 0,
                maxDepth: depth,
                bestDiff: &bestDiff,
                bestResult: &bestResult
            ) {
                return solution
            }
        }
        
        return bestResult
    }
    
    private func findClosestAtDepth(
        available: [Int],
        target: Int,
        operations: [Operation],
        depth: Int,
        maxDepth: Int,
        bestDiff: inout Int,
        bestResult: inout (Int, [Operation])?
    ) -> (Int, [Operation])? {
        
        // Check current numbers for closest match
        for num in available {
            let diff = abs(target - num)
            if diff < bestDiff {
                bestDiff = diff
                bestResult = (num, operations)
                if diff == 0 {
                    return bestResult
                }
            }
        }
        
        if depth >= maxDepth || available.count < 2 {
            return nil
        }
        
        // Continue searching...
        for i in 0..<available.count {
            for j in (i+1)..<available.count {
                let a = available[i]
                let b = available[j]
                
                let possibleResults: [(result: Int, op: String)] = [
                    (a + b, "+"),
                    (abs(a - b), "−"),
                    (a * b, "×"),
                ]
                
                for (result, op) in possibleResults {
                    var newAvailable = available
                    newAvailable.remove(at: j)
                    newAvailable.remove(at: i)
                    newAvailable.append(result)
                    
                    let operation = Operation(
                        operand1: max(a, b),
                        operand2: min(a, b),
                        operation: op,
                        result: result
                    )
                    
                    _ = findClosestAtDepth(
                        available: newAvailable,
                        target: target,
                        operations: operations + [operation],
                        depth: depth + 1,
                        maxDepth: maxDepth,
                        bestDiff: &bestDiff,
                        bestResult: &bestResult
                    )
                }
            }
        }
        
        return bestResult
    }
}

