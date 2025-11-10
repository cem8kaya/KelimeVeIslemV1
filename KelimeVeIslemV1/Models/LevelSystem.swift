//
//  LevelSystem.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/10/25.
//

import Foundation
import SwiftUI

// MARK: - Level Model

struct Level: Codable, Identifiable, Equatable {
    let id: Int // Level number
    let xpRequired: Int // Cumulative XP needed to reach this level
    let rewards: [LevelReward]
    let difficulty: DifficultyModifiers

    var levelNumber: Int { id }

    struct DifficultyModifiers: Codable, Equatable {
        // Letter game modifiers
        let letterTimeSeconds: Int
        let minLetterCount: Int
        let maxLetterCount: Int
        let harderLetterCombos: Bool // Use less common letters

        // Number game modifiers
        let numberTimeSeconds: Int
        let targetNumberRange: ClosedRange<Int>
        let allowedOperations: [String] // ["+", "-", "*", "/"]

        enum CodingKeys: String, CodingKey {
            case letterTimeSeconds, minLetterCount, maxLetterCount, harderLetterCombos
            case numberTimeSeconds, targetNumberRangeMin, targetNumberRangeMax, allowedOperations
        }

        init(
            letterTimeSeconds: Int,
            minLetterCount: Int,
            maxLetterCount: Int,
            harderLetterCombos: Bool,
            numberTimeSeconds: Int,
            targetNumberRange: ClosedRange<Int>,
            allowedOperations: [String]
        ) {
            self.letterTimeSeconds = letterTimeSeconds
            self.minLetterCount = minLetterCount
            self.maxLetterCount = maxLetterCount
            self.harderLetterCombos = harderLetterCombos
            self.numberTimeSeconds = numberTimeSeconds
            self.targetNumberRange = targetNumberRange
            self.allowedOperations = allowedOperations
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            letterTimeSeconds = try container.decode(Int.self, forKey: .letterTimeSeconds)
            minLetterCount = try container.decode(Int.self, forKey: .minLetterCount)
            maxLetterCount = try container.decode(Int.self, forKey: .maxLetterCount)
            harderLetterCombos = try container.decode(Bool.self, forKey: .harderLetterCombos)
            numberTimeSeconds = try container.decode(Int.self, forKey: .numberTimeSeconds)
            let min = try container.decode(Int.self, forKey: .targetNumberRangeMin)
            let max = try container.decode(Int.self, forKey: .targetNumberRangeMax)
            targetNumberRange = min...max
            allowedOperations = try container.decode([String].self, forKey: .allowedOperations)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(letterTimeSeconds, forKey: .letterTimeSeconds)
            try container.encode(minLetterCount, forKey: .minLetterCount)
            try container.encode(maxLetterCount, forKey: .maxLetterCount)
            try container.encode(harderLetterCombos, forKey: .harderLetterCombos)
            try container.encode(numberTimeSeconds, forKey: .numberTimeSeconds)
            try container.encode(targetNumberRange.lowerBound, forKey: .targetNumberRangeMin)
            try container.encode(targetNumberRange.upperBound, forKey: .targetNumberRangeMax)
            try container.encode(allowedOperations, forKey: .allowedOperations)
        }

        static func == (lhs: DifficultyModifiers, rhs: DifficultyModifiers) -> Bool {
            lhs.letterTimeSeconds == rhs.letterTimeSeconds &&
            lhs.minLetterCount == rhs.minLetterCount &&
            lhs.maxLetterCount == rhs.maxLetterCount &&
            lhs.harderLetterCombos == rhs.harderLetterCombos &&
            lhs.numberTimeSeconds == rhs.numberTimeSeconds &&
            lhs.targetNumberRange == rhs.targetNumberRange &&
            lhs.allowedOperations == rhs.allowedOperations
        }
    }
}

// MARK: - Level Rewards

enum LevelReward: Codable, Equatable {
    case theme(String) // Theme name
    case powerUp(PowerUpType)
    case extraHints(Int)
    case extraTime(Int) // Bonus seconds
    case xpBoost(Double) // Multiplier (e.g., 1.5 = 50% boost)

    enum PowerUpType: String, Codable {
        case letterShuffle = "Harf Karıştırma"
        case numberHint = "Sayı İpucu"
        case timeFreeze = "Zaman Dondurma"
        case doubleXP = "Çift XP"
        case skipQuestion = "Soru Atlama"
    }

    var displayName: String {
        switch self {
        case .theme(let name):
            return "Tema: \(name)"
        case .powerUp(let type):
            return "Güç: \(type.rawValue)"
        case .extraHints(let count):
            return "+\(count) İpucu"
        case .extraTime(let seconds):
            return "+\(seconds)sn Süre"
        case .xpBoost(let multiplier):
            let percent = Int((multiplier - 1.0) * 100)
            return "+%\(percent) XP Bonusu"
        }
    }

    var iconName: String {
        switch self {
        case .theme:
            return "paintpalette.fill"
        case .powerUp:
            return "bolt.fill"
        case .extraHints:
            return "lightbulb.fill"
        case .extraTime:
            return "clock.fill"
        case .xpBoost:
            return "star.fill"
        }
    }
}

// MARK: - Level System

class LevelSystem {
    static let shared = LevelSystem()

    private init() {}

    // XP Calculation
    func calculateXP(score: Int, combo: Int, gameMode: GameMode, isDailyChallenge: Bool = false) -> Int {
        var xp = score

        // Combo multiplier bonus
        let comboBonus = max(0, combo - 1) * 5
        xp += comboBonus

        // Daily challenge bonus
        if isDailyChallenge {
            xp = Int(Double(xp) * 2.0)
        }

        // Minimum XP guarantee
        return max(xp, 10)
    }

    // Get level for given total XP
    func getLevel(for totalXP: Int) -> Level {
        let levels = Level.allLevels

        // Find the highest level where totalXP >= xpRequired
        for level in levels.reversed() {
            if totalXP >= level.xpRequired {
                return level
            }
        }

        return levels[0] // Return level 1 if not enough XP
    }

    // Get XP needed for next level
    func xpForNextLevel(currentXP: Int, currentLevel: Level) -> Int {
        let levels = Level.allLevels

        if let currentIndex = levels.firstIndex(where: { $0.id == currentLevel.id }) {
            if currentIndex < levels.count - 1 {
                let nextLevel = levels[currentIndex + 1]
                return nextLevel.xpRequired - currentXP
            }
        }

        return 0 // Max level reached
    }

    // Get progress percentage to next level
    func progressToNextLevel(currentXP: Int, currentLevel: Level) -> Double {
        let levels = Level.allLevels

        if let currentIndex = levels.firstIndex(where: { $0.id == currentLevel.id }) {
            if currentIndex < levels.count - 1 {
                let nextLevel = levels[currentIndex + 1]
                let xpInCurrentLevel = currentXP - currentLevel.xpRequired
                let xpNeededForLevel = nextLevel.xpRequired - currentLevel.xpRequired

                return Double(xpInCurrentLevel) / Double(xpNeededForLevel)
            }
        }

        return 1.0 // Max level
    }

    // Check if leveled up
    func checkLevelUp(oldXP: Int, newXP: Int) -> Level? {
        let oldLevel = getLevel(for: oldXP)
        let newLevel = getLevel(for: newXP)

        if newLevel.id > oldLevel.id {
            return newLevel
        }

        return nil
    }
}

// MARK: - Predefined Levels

extension Level {
    static let allLevels: [Level] = {
        var levels: [Level] = []

        for i in 1...50 {
            let xpRequired = calculateXPRequirement(for: i)
            let rewards = getRewards(for: i)
            let difficulty = getDifficulty(for: i)

            levels.append(Level(
                id: i,
                xpRequired: xpRequired,
                rewards: rewards,
                difficulty: difficulty
            ))
        }

        return levels
    }()

    // XP requirement grows exponentially
    private static func calculateXPRequirement(for level: Int) -> Int {
        if level == 1 { return 0 }

        // Formula: base XP * (level - 1) * growth factor
        let baseXP = 100
        let growthFactor = 1.15

        var totalXP = 0
        for l in 2...level {
            let xpForLevel = Int(Double(baseXP) * pow(growthFactor, Double(l - 2)))
            totalXP += xpForLevel
        }

        return totalXP
    }

    // Rewards for specific levels
    private static func getRewards(for level: Int) -> [LevelReward] {
        var rewards: [LevelReward] = []

        switch level {
        case 2:
            rewards.append(.extraHints(1))
        case 5:
            rewards.append(.theme("Gece Modu"))
            rewards.append(.extraTime(5))
        case 10:
            rewards.append(.powerUp(.letterShuffle))
            rewards.append(.xpBoost(1.1))
        case 15:
            rewards.append(.theme("Deniz Mavisi"))
            rewards.append(.extraHints(2))
        case 20:
            rewards.append(.powerUp(.numberHint))
            rewards.append(.xpBoost(1.15))
        case 25:
            rewards.append(.theme("Gün Batımı"))
            rewards.append(.extraTime(10))
        case 30:
            rewards.append(.powerUp(.timeFreeze))
            rewards.append(.xpBoost(1.2))
        case 35:
            rewards.append(.theme("Orman Yeşili"))
            rewards.append(.extraHints(3))
        case 40:
            rewards.append(.powerUp(.doubleXP))
            rewards.append(.xpBoost(1.25))
        case 45:
            rewards.append(.theme("Kraliyet Moru"))
            rewards.append(.extraTime(15))
        case 50:
            rewards.append(.powerUp(.skipQuestion))
            rewards.append(.xpBoost(1.5))
            rewards.append(.theme("Altın"))
        default:
            // Every 5 levels, give a small reward
            if level % 5 == 0 {
                rewards.append(.extraHints(1))
            }
        }

        return rewards
    }

    // Difficulty increases with level
    private static func getDifficulty(for level: Int) -> DifficultyModifiers {
        // Letter game difficulty
        let baseLetterTime = 120
        let letterTimeReduction = min(40, (level - 1) * 2) // Max 40 seconds reduction
        let letterTime = max(60, baseLetterTime - letterTimeReduction)

        let minLetters = min(6, 4 + (level - 1) / 10)
        let maxLetters = min(9, 6 + (level - 1) / 5)
        let harderLetters = level >= 10

        // Number game difficulty
        let baseNumberTime = 90
        let numberTimeReduction = min(30, (level - 1) * 1) // Max 30 seconds reduction
        let numberTime = max(45, baseNumberTime - numberTimeReduction)

        let targetMin = 10 + (level - 1) * 5
        let targetMax = min(999, 50 + (level - 1) * 10)

        var operations = ["+", "-"]
        if level >= 5 {
            operations.append("*")
        }
        if level >= 15 {
            operations.append("/")
        }

        return DifficultyModifiers(
            letterTimeSeconds: letterTime,
            minLetterCount: minLetters,
            maxLetterCount: maxLetters,
            harderLetterCombos: harderLetters,
            numberTimeSeconds: numberTime,
            targetNumberRange: targetMin...targetMax,
            allowedOperations: operations
        )
    }
}

// MARK: - Helper Extensions

extension GameMode {
    var baseXPMultiplier: Double {
        switch self {
        case .letters: return 1.0
        case .numbers: return 1.2 // Numbers slightly more rewarding
        }
    }
}
