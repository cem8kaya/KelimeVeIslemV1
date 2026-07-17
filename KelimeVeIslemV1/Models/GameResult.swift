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
    var validWordsCount: Int = 0
    var bestLetterScore: Int = 0
    var bestNumberScore: Int = 0
    var longestWord: String = ""
    var perfectNumberMatches: Int = 0
    var lastPlayedDate: Date?

    // Level progression
    var totalXP: Int = 0
    var currentLevel: Int = 1

    init() {}

    // Tolerant decoding: missing keys fall back to defaults so adding fields
    // never wipes previously stored statistics. validWordsCount is migrated
    // from letterGamesPlayed for data recorded before it existed.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalGamesPlayed = try container.decodeIfPresent(Int.self, forKey: .totalGamesPlayed) ?? 0
        totalScore = try container.decodeIfPresent(Int.self, forKey: .totalScore) ?? 0
        letterGamesPlayed = try container.decodeIfPresent(Int.self, forKey: .letterGamesPlayed) ?? 0
        numberGamesPlayed = try container.decodeIfPresent(Int.self, forKey: .numberGamesPlayed) ?? 0
        validWordsCount = try container.decodeIfPresent(Int.self, forKey: .validWordsCount) ?? letterGamesPlayed
        bestLetterScore = try container.decodeIfPresent(Int.self, forKey: .bestLetterScore) ?? 0
        bestNumberScore = try container.decodeIfPresent(Int.self, forKey: .bestNumberScore) ?? 0
        longestWord = try container.decodeIfPresent(String.self, forKey: .longestWord) ?? ""
        perfectNumberMatches = try container.decodeIfPresent(Int.self, forKey: .perfectNumberMatches) ?? 0
        lastPlayedDate = try container.decodeIfPresent(Date.self, forKey: .lastPlayedDate)
        totalXP = try container.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
        currentLevel = try container.decodeIfPresent(Int.self, forKey: .currentLevel) ?? 1
    }

    private enum CodingKeys: String, CodingKey {
        case totalGamesPlayed, totalScore, letterGamesPlayed, numberGamesPlayed
        case validWordsCount, bestLetterScore, bestNumberScore, longestWord
        case perfectNumberMatches, lastPlayedDate, totalXP, currentLevel
    }

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
            if isValid {
                validWordsCount += 1
                if result.score > bestLetterScore {
                    bestLetterScore = result.score
                }
                // Only dictionary-valid words may become the longest word
                if word.count > longestWord.count {
                    longestWord = word
                }
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
