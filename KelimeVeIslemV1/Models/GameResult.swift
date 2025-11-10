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
    let combo: Int // Combo multiplier at end of game
    let xpEarned: Int // XP earned from this game

    init(mode: GameMode, score: Int, duration: Int, details: ResultDetails, combo: Int = 1, isDailyChallenge: Bool = false) {
        self.id = UUID()
        self.mode = mode
        self.score = score
        self.date = Date()
        self.duration = duration
        self.details = details
        self.combo = combo

        // Calculate XP using LevelSystem
        self.xpEarned = LevelSystem.shared.calculateXP(
            score: score,
            combo: combo,
            gameMode: mode,
            isDailyChallenge: isDailyChallenge
        )
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

    // Level progression
    var totalXP: Int = 0
    var currentLevel: Int = 1

    var averageScore: Double {
        guard totalGamesPlayed > 0 else { return 0 }
        return Double(totalScore) / Double(totalGamesPlayed)
    }

    var level: Level {
        return LevelSystem.shared.getLevel(for: totalXP)
    }

    var xpForNextLevel: Int {
        return LevelSystem.shared.xpForNextLevel(currentXP: totalXP, currentLevel: level)
    }

    var progressToNextLevel: Double {
        return LevelSystem.shared.progressToNextLevel(currentXP: totalXP, currentLevel: level)
    }

    mutating func update(with result: GameResult) -> Level? {
        let oldXP = totalXP

        totalGamesPlayed += 1
        totalScore += result.score
        lastPlayedDate = result.date

        // Add XP from result
        totalXP += result.xpEarned

        // Update current level
        let newLevel = LevelSystem.shared.getLevel(for: totalXP)
        currentLevel = newLevel.id

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

        // Check if player leveled up
        return LevelSystem.shared.checkLevelUp(oldXP: oldXP, newXP: totalXP)
    }

    func reset() -> GameStatistics {
        return GameStatistics()
    }
}
