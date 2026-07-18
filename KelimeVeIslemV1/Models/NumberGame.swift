//
//  NumberGame.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

import Foundation

struct NumberGame: Codable, Identifiable {
    let id: UUID
    let numbers: [Int]
    let targetNumber: Int
    var playerSolution: String
    var playerResult: Int?
    var timeRemaining: Int
    var score: Int
    let createdAt: Date
    
    init(numbers: [Int], targetNumber: Int) {
        self.id = UUID()
        self.numbers = numbers
        self.targetNumber = targetNumber
        self.playerSolution = ""
        self.playerResult = nil
        self.timeRemaining = 90
        self.score = 0
        self.createdAt = Date()
    }
    
    mutating func updateSolution(_ solution: String) {
        self.playerSolution = solution
    }
    
    mutating func evaluateAndScore() throws {
        // CRITICAL: Check if the expression uses only the available numbers
        guard usesOnlyAvailableNumbers(playerSolution) else {
            self.playerResult = nil
            self.score = 0
            throw AppError.invalidInput("Solution uses invalid or duplicate numbers")
        }

        // Try to evaluate the expression
        if let result = try? evaluateExpression(playerSolution) {
            self.playerResult = result
            self.score = calculateScore(result: result)
        } else {
            self.playerResult = nil
            self.score = 0
            throw AppError.expressionEvaluationFailed
        }
    }
    
    private func calculateScore(result: Int) -> Int {
        let difference = abs(targetNumber - result)
        
        if difference == 0 {
            return 100 // Perfect match
        } else if difference <= 5 {
            return max(80 - (difference * 10), 0)
        } else if difference <= 10 {
            return max(50 - (difference * 3), 0)
        } else if difference <= 20 {
            return max(20 - difference, 0)
        } else {
            return 0
        }
    }
    
    // Classic Countdown / "Bir Kelime Bir İşlem" rules: every intermediate
    // result must be a non-negative integer, and division must be exact.
    // Evaluation is pure Int arithmetic — no silent Double truncation.
    func evaluateExpression(_ expression: String) throws -> Int {
        // Remove whitespace
        let cleaned = expression.replacingOccurrences(of: " ", with: "")

        guard !cleaned.isEmpty else {
            throw AppError.invalidInput("Empty expression")
        }

        // Replace × and ÷ with * and /
        let normalized = cleaned
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "−", with: "-")

        // Validate characters
        let allowedCharacters = CharacterSet(charactersIn: "0123456789+-*/()")
        guard normalized.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            throw AppError.invalidInput("Invalid characters in expression")
        }

        let tokens = tokenize(expression: normalized)
        var index = 0
        let result = try parseExpression(tokens: tokens, index: &index)

        guard index == tokens.count else {
            throw AppError.invalidInput("Unexpected token: \(tokens[index])")
        }

        return result
    }

    private func tokenize(expression: String) -> [String] {
        var tokens: [String] = []
        var currentNumber = ""

        for char in expression {
            if char.isNumber {
                currentNumber.append(char)
            } else if "+-*/()".contains(char) {
                if !currentNumber.isEmpty {
                    tokens.append(currentNumber)
                    currentNumber = ""
                }
                tokens.append(String(char))
            }
        }

        if !currentNumber.isEmpty {
            tokens.append(currentNumber)
        }

        return tokens
    }

    private func parseExpression(tokens: [String], index: inout Int) throws -> Int {
        var result = try parseTerm(tokens: tokens, index: &index)

        while index < tokens.count && (tokens[index] == "+" || tokens[index] == "-") {
            let op = tokens[index]
            index += 1
            let right = try parseTerm(tokens: tokens, index: &index)

            if op == "+" {
                result += right
            } else {
                let difference = result - right
                guard difference >= 0 else {
                    throw AppError.invalidInput("Negatif ara sonuç: \(result) - \(right)")
                }
                result = difference
            }
        }

        return result
    }

    private func parseTerm(tokens: [String], index: inout Int) throws -> Int {
        var result = try parseFactor(tokens: tokens, index: &index)

        while index < tokens.count && (tokens[index] == "*" || tokens[index] == "/") {
            let op = tokens[index]
            index += 1
            let right = try parseFactor(tokens: tokens, index: &index)

            if op == "*" {
                result *= right
            } else {
                guard right != 0 else {
                    throw AppError.invalidInput("Division by zero")
                }
                guard result % right == 0 else {
                    throw AppError.invalidInput("\(result)/\(right) tam bölünmüyor")
                }
                result /= right
            }
        }

        return result
    }

    private func parseFactor(tokens: [String], index: inout Int) throws -> Int {
        guard index < tokens.count else {
            throw AppError.invalidInput("Unexpected end of expression")
        }

        let token = tokens[index]

        if token == "(" {
            index += 1
            let result = try parseExpression(tokens: tokens, index: &index)

            guard index < tokens.count && tokens[index] == ")" else {
                throw AppError.invalidInput("Missing closing parenthesis")
            }
            index += 1
            return result
        }

        guard let number = Int(token) else {
            throw AppError.invalidInput("Invalid number: \(token)")
        }

        index += 1
        return number
    }
    
    private func usesOnlyAvailableNumbers(_ expression: String) -> Bool {
        // Extract numbers from expression
        let pattern = "\\d+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        
        let nsExpression = expression as NSString
        let results = regex.matches(in: expression, range: NSRange(location: 0, length: nsExpression.length))
        
        let extractedNumbers = results.compactMap { result -> Int? in
            let match = nsExpression.substring(with: result.range)
            return Int(match)
        }
        
        var available = self.numbers
        
        for number in extractedNumbers {
            if let index = available.firstIndex(of: number) {
                available.remove(at: index)
            } else {
                return false
            }
        }
        
        return true
    }
}

// Operation for building solutions step by step
struct Operation: Identifiable, Equatable, Codable {
    var id = UUID()
    let operand1: Int
    let operand2: Int
    let operation: String // +, -, ×, ÷
    let result: Int
    
    var description: String {
        "\(operand1) \(operation) \(operand2) = \(result)"
    }
}
