//
//  GameResult.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//


import Foundation

struct GameResult: Codable, Identifiable {
    let id: UUID
    let mode: GameMode
    let score: Int
    let date: Date
    let duration: Int // seconds taken
    let details: ResultDetails
    
    init(mode: GameMode, score: Int, duration: Int, details: ResultDetails) {
        self.id = UUID()
        self.mode = mode
        self.score = score
        self.date = Date()
        self.duration = duration
        self.details = details
    }
    
    enum ResultDetails: Codable {
        case letters(word: String, letters: [String], isValid: Bool)
        case numbers(target: Int, result: Int?, solution: String, numbers: [Int])
    }
    
    var isSuccess: Bool {
        switch details {
        case .letters(_, _, let isValid):
            return isValid
        case .numbers(let target, let result, _, _):
            guard let result = result else { return false }
            return abs(target - result) <= 10
        }
    }
}

// Statistics aggregation
struct GameStatistics: Codable {
    var totalGamesPlayed: Int = 0
    var totalScore: Int = 0
    var letterGamesPlayed: Int = 0
    var numberGamesPlayed: Int = 0
    var bestLetterScore: Int = 0
    var bestNumberScore: Int = 0
    var longestWord: String = ""
    var perfectNumberMatches: Int = 0
    var lastPlayedDate: Date?
    
    var averageScore: Double {
        guard totalGamesPlayed > 0 else { return 0 }
        return Double(totalScore) / Double(totalGamesPlayed)
    }
    
    mutating func update(with result: GameResult) {
        totalGamesPlayed += 1
        totalScore += result.score
        lastPlayedDate = result.date
        
        switch result.details {
        case .letters(let word, _, let isValid):
            letterGamesPlayed += 1
            if isValid && result.score > bestLetterScore {
                bestLetterScore = result.score
            }
            if word.count > longestWord.count {
                longestWord = word
            }
            
        case .numbers(let target, let playerResult, _, _):
            numberGamesPlayed += 1
            if result.score > bestNumberScore {
                bestNumberScore = result.score
            }
            if let playerResult = playerResult, playerResult == target {
                perfectNumberMatches += 1
            }
        }
    }
    
    func reset() -> GameStatistics {
        return GameStatistics()
    }
}
