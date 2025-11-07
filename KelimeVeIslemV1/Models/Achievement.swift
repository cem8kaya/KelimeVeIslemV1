//
//  Achievement.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/7/25.
//


import Foundation
import SwiftUI

// MARK: - Achievement Model

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let requirement: AchievementRequirement
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var progress: Int = 0

    enum AchievementCategory: String, Codable {
        case general
        case letters
        case numbers
        case speed
        case combo
        case daily
        case mastery
    }

    enum AchievementRequirement: Codable {
        case gamesPlayed(Int)
        case totalScore(Int)
        case validWords(Int)
        case perfectMatches(Int)
        case wordLength(Int)
        case speedInSeconds(Int)
        case comboReached(Int)
        case dailyChallengesCompleted(Int)
        case consecutiveDays(Int)
        case highScore(mode: GameMode, score: Int)
        case useAllLetters
        case custom(String)
    }

    var targetValue: Int {
        switch requirement {
        case .gamesPlayed(let count): return count
        case .totalScore(let score): return score
        case .validWords(let count): return count
        case .perfectMatches(let count): return count
        case .wordLength(let length): return length
        case .speedInSeconds(let seconds): return seconds
        case .comboReached(let combo): return combo
        case .dailyChallengesCompleted(let count): return count
        case .consecutiveDays(let days): return days
        case .highScore(_, let score): return score
        case .useAllLetters: return 1
        case .custom: return 1
        }
    }

    var progressPercentage: Double {
        guard targetValue > 0 else { return isUnlocked ? 1.0 : 0.0 }
        return min(1.0, Double(progress) / Double(targetValue))
    }

    mutating func updateProgress(_ newProgress: Int) {
        progress = min(newProgress, targetValue)
        if progress >= targetValue && !isUnlocked {
            unlock()
        }
    }

    mutating func unlock() {
        isUnlocked = true
        unlockedAt = Date()
        progress = targetValue
    }
}

// MARK: - Predefined Achievements

extension Achievement {
    static let allAchievements: [Achievement] = [
        // General Achievements
        Achievement(
            id: "first_game",
            title: "İlk Adım",
            description: "İlk oyununu tamamla",
            iconName: "star.fill",
            category: .general,
            requirement: .gamesPlayed(1)
        ),
        Achievement(
            id: "games_10",
            title: "Yolculuk Başlasın",
            description: "10 oyun tamamla",
            iconName: "flag.fill",
            category: .general,
            requirement: .gamesPlayed(10)
        ),
        Achievement(
            id: "games_50",
            title: "Deneyimli Oyuncu",
            description: "50 oyun tamamla",
            iconName: "medal.fill",
            category: .general,
            requirement: .gamesPlayed(50)
        ),
        Achievement(
            id: "games_100",
            title: "Efsane",
            description: "100 oyun tamamla",
            iconName: "crown.fill",
            category: .general,
            requirement: .gamesPlayed(100)
        ),

        // Letter Game Achievements
        Achievement(
            id: "first_valid_word",
            title: "İlk Kelime",
            description: "İlk geçerli kelimeni oluştur",
            iconName: "text.bubble.fill",
            category: .letters,
            requirement: .validWords(1)
        ),
        Achievement(
            id: "words_100",
            title: "Kelime Ustası",
            description: "100 geçerli kelime oluştur",
            iconName: "book.fill",
            category: .letters,
            requirement: .validWords(100)
        ),
        Achievement(
            id: "long_word",
            title: "Uzun Kelime Ustası",
            description: "9 harfli veya daha uzun kelime oluştur",
            iconName: "text.alignleft",
            category: .letters,
            requirement: .wordLength(9)
        ),
        Achievement(
            id: "use_all_letters",
            title: "Tüm Harfleri Kullan",
            description: "Tüm harfleri kullanarak kelime oluştur",
            iconName: "checklist",
            category: .letters,
            requirement: .useAllLetters
        ),

        // Number Game Achievements
        Achievement(
            id: "first_perfect",
            title: "İlk Mükemmel Eşleşme",
            description: "Hedef sayıyı tam olarak bul",
            iconName: "target",
            category: .numbers,
            requirement: .perfectMatches(1)
        ),
        Achievement(
            id: "perfect_10",
            title: "Hassasiyet Ustası",
            description: "10 mükemmel eşleşme yap",
            iconName: "scope",
            category: .numbers,
            requirement: .perfectMatches(10)
        ),

        // Speed Achievements
        Achievement(
            id: "speed_demon",
            title: "Hız Şeytanı",
            description: "30 saniye içinde oyunu tamamla",
            iconName: "hare.fill",
            category: .speed,
            requirement: .speedInSeconds(30)
        ),

        // Combo Achievements
        Achievement(
            id: "combo_5",
            title: "Kombo Ustası",
            description: "5 kombo yap",
            iconName: "flame.fill",
            category: .combo,
            requirement: .comboReached(5)
        ),
        Achievement(
            id: "combo_10",
            title: "Ateş Topu",
            description: "10 kombo yap",
            iconName: "sparkles",
            category: .combo,
            requirement: .comboReached(10)
        ),

        // Daily Challenge Achievements
        Achievement(
            id: "daily_first",
            title: "Günlük Zorluk",
            description: "İlk günlük meydan okumayı tamamla",
            iconName: "calendar.badge.checkmark",
            category: .daily,
            requirement: .dailyChallengesCompleted(1)
        ),
        Achievement(
            id: "daily_streak_7",
            title: "Haftalık Seri",
            description: "7 gün üst üste günlük meydan okuma tamamla",
            iconName: "calendar.badge.clock",
            category: .daily,
            requirement: .consecutiveDays(7)
        ),

        // Mastery Achievement
        Achievement(
            id: "high_score",
            title: "Yüksek Skor",
            description: "Tek oyunda 200+ puan kazan",
            iconName: "rosette",
            category: .mastery,
            requirement: .highScore(mode: .letters, score: 200)
        )
    ]

    static func getAchievement(byId id: String) -> Achievement? {
        return allAchievements.first { $0.id == id }
    }
}

// MARK: - Achievement Progress

struct AchievementProgress: Codable {
    var achievements: [String: Achievement] = [:]
    var totalUnlocked: Int {
        achievements.values.filter { $0.isUnlocked }.count
    }

    init() {
        // Initialize with all achievements
        Achievement.allAchievements.forEach { achievement in
            achievements[achievement.id] = achievement
        }
    }

    mutating func updateAchievement(_ id: String, progress: Int) {
        guard var achievement = achievements[id] else { return }
        let wasUnlocked = achievement.isUnlocked
        achievement.updateProgress(progress)
        achievements[id] = achievement

        // Return whether a new achievement was unlocked
        if !wasUnlocked && achievement.isUnlocked {
            print("🏆 Achievement unlocked: \(achievement.title)")
        }
    }

    mutating func unlockAchievement(_ id: String) {
        guard var achievement = achievements[id], !achievement.isUnlocked else { return }
        achievement.unlock()
        achievements[id] = achievement
        print("🏆 Achievement unlocked: \(achievement.title)")
    }

    func getUnlockedAchievements() -> [Achievement] {
        return achievements.values.filter { $0.isUnlocked }.sorted {
            $0.unlockedAt ?? Date.distantPast > $1.unlockedAt ?? Date.distantPast
        }
    }

    func getLockedAchievements() -> [Achievement] {
        return achievements.values.filter { !$0.isUnlocked }.sorted {
            $0.progressPercentage > $1.progressPercentage
        }
    }

    func getAchievementsByCategory(_ category: Achievement.AchievementCategory) -> [Achievement] {
        return achievements.values.filter { $0.category == category }.sorted {
            if $0.isUnlocked != $1.isUnlocked {
                return $0.isUnlocked
            }
            return $0.progressPercentage > $1.progressPercentage
        }
    }
}

// MARK: - Achievement Tracker

class AchievementTracker {
    static let shared = AchievementTracker()
    private let persistenceService = PersistenceService.shared

    private init() {}

    func checkAchievements(after result: GameResult, with statistics: GameStatistics) -> [Achievement] {
        var progress = loadProgress()
        var newlyUnlocked: [Achievement] = []

        // General achievements
        progress.updateAchievement("first_game", progress: statistics.totalGamesPlayed)
        if progress.achievements["first_game"]?.isUnlocked == true && statistics.totalGamesPlayed == 1 {
            newlyUnlocked.append(progress.achievements["first_game"]!)
        }

        progress.updateAchievement("games_10", progress: statistics.totalGamesPlayed)
        if progress.achievements["games_10"]?.isUnlocked == true && statistics.totalGamesPlayed == 10 {
            newlyUnlocked.append(progress.achievements["games_10"]!)
        }

        progress.updateAchievement("games_50", progress: statistics.totalGamesPlayed)
        if progress.achievements["games_50"]?.isUnlocked == true && statistics.totalGamesPlayed == 50 {
            newlyUnlocked.append(progress.achievements["games_50"]!)
        }

        progress.updateAchievement("games_100", progress: statistics.totalGamesPlayed)
        if progress.achievements["games_100"]?.isUnlocked == true && statistics.totalGamesPlayed == 100 {
            newlyUnlocked.append(progress.achievements["games_100"]!)
        }

        // Letter game achievements
        if case .letters(let word, _, let isValid) = result.details {
            if isValid {
                let validWordsCount = statistics.letterGamesPlayed // Simplified tracking
                progress.updateAchievement("first_valid_word", progress: validWordsCount)
                if progress.achievements["first_valid_word"]?.isUnlocked == true && validWordsCount == 1 {
                    newlyUnlocked.append(progress.achievements["first_valid_word"]!)
                }

                progress.updateAchievement("words_100", progress: validWordsCount)
                if progress.achievements["words_100"]?.isUnlocked == true && validWordsCount == 100 {
                    newlyUnlocked.append(progress.achievements["words_100"]!)
                }

                // Long word achievement
                if word.count >= 9 {
                    progress.unlockAchievement("long_word")
                    if progress.achievements["long_word"]?.isUnlocked == true {
                        newlyUnlocked.append(progress.achievements["long_word"]!)
                    }
                }
            }
        }

        // Number game achievements
        if case .numbers(let target, let playerResult, _, _) = result.details {
            if let playerResult = playerResult, playerResult == target {
                progress.updateAchievement("first_perfect", progress: statistics.perfectNumberMatches)
                if progress.achievements["first_perfect"]?.isUnlocked == true && statistics.perfectNumberMatches == 1 {
                    newlyUnlocked.append(progress.achievements["first_perfect"]!)
                }

                progress.updateAchievement("perfect_10", progress: statistics.perfectNumberMatches)
                if progress.achievements["perfect_10"]?.isUnlocked == true && statistics.perfectNumberMatches == 10 {
                    newlyUnlocked.append(progress.achievements["perfect_10"]!)
                }
            }
        }

        // Speed achievement
        if result.duration <= 30 && result.isSuccess {
            progress.unlockAchievement("speed_demon")
            if progress.achievements["speed_demon"]?.isUnlocked == true {
                newlyUnlocked.append(progress.achievements["speed_demon"]!)
            }
        }

        // High score achievement
        if result.score >= 200 {
            progress.unlockAchievement("high_score")
            if progress.achievements["high_score"]?.isUnlocked == true {
                newlyUnlocked.append(progress.achievements["high_score"]!)
            }
        }

        saveProgress(progress)
        return newlyUnlocked
    }

    func checkComboAchievement(_ comboCount: Int) -> [Achievement] {
        var progress = loadProgress()
        var newlyUnlocked: [Achievement] = []

        if comboCount >= 5 && !(progress.achievements["combo_5"]?.isUnlocked ?? false) {
            progress.unlockAchievement("combo_5")
            newlyUnlocked.append(progress.achievements["combo_5"]!)
        }

        if comboCount >= 10 && !(progress.achievements["combo_10"]?.isUnlocked ?? false) {
            progress.unlockAchievement("combo_10")
            newlyUnlocked.append(progress.achievements["combo_10"]!)
        }

        if !newlyUnlocked.isEmpty {
            saveProgress(progress)
        }
        return newlyUnlocked
    }

    func checkDailyChallengeAchievements(stats: DailyChallengeStats) -> [Achievement] {
        var progress = loadProgress()
        var newlyUnlocked: [Achievement] = []

        progress.updateAchievement("daily_first", progress: stats.totalChallengesCompleted)
        if progress.achievements["daily_first"]?.isUnlocked == true && stats.totalChallengesCompleted == 1 {
            newlyUnlocked.append(progress.achievements["daily_first"]!)
        }

        progress.updateAchievement("daily_streak_7", progress: stats.currentStreak)
        if progress.achievements["daily_streak_7"]?.isUnlocked == true && stats.currentStreak == 7 {
            newlyUnlocked.append(progress.achievements["daily_streak_7"]!)
        }

        if !newlyUnlocked.isEmpty {
            saveProgress(progress)
        }
        return newlyUnlocked
    }

    private func saveProgress(_ progress: AchievementProgress) {
        persistenceService.saveAchievementProgress(progress)
    }

    private func loadProgress() -> AchievementProgress {
        return persistenceService.loadAchievementProgress()
    }

    func getProgress() -> AchievementProgress {
        return loadProgress()
    }
}
