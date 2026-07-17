//
//  Achievement.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/7/25.
//


import Foundation
import SwiftUI

// MARK: - Achievement Model

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let requirement: AchievementRequirement
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var progress: Int = 0

    enum AchievementCategory: String, Codable, Equatable {
        case general
        case letters
        case numbers
        case speed
        case combo
        case daily
        case mastery
    }

    enum AchievementRequirement: Codable, Equatable {
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

struct AchievementProgress: Codable, Sendable {
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
            AppLog.game.info("Achievement unlocked: \(achievement.title)")
        }
    }

    mutating func unlockAchievement(_ id: String) {
        guard var achievement = achievements[id], !achievement.isUnlocked else { return }
        achievement.unlock()
        achievements[id] = achievement
        AppLog.game.info("Achievement unlocked: \(achievement.title)")
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

    // MARK: - Pure evaluation
    //
    // The evaluation is a pure function over (result, statistics, progress) so
    // it can run inside PersistenceService's queue without re-entering it, and
    // "newly unlocked" is computed by diffing the unlocked set — a progress
    // update that jumps over a threshold can no longer miss its notification.

    static func evaluate(
        result: GameResult,
        statistics: GameStatistics,
        progress: inout AchievementProgress
    ) -> [Achievement] {
        let unlockedBefore = Set(progress.achievements.values.filter { $0.isUnlocked }.map { $0.id })

        // Progress-counter achievements: (id, current value)
        var updates: [(id: String, value: Int)] = [
            ("first_game", statistics.totalGamesPlayed),
            ("games_10", statistics.totalGamesPlayed),
            ("games_50", statistics.totalGamesPlayed),
            ("games_100", statistics.totalGamesPlayed),
        ]

        if case .letters(let word, let letters, let isValid) = result.details, isValid {
            updates.append(("first_valid_word", statistics.validWordsCount))
            updates.append(("words_100", statistics.validWordsCount))

            if word.count >= 9 {
                progress.unlockAchievement("long_word")
            }
            if !letters.isEmpty && word.count == letters.count {
                progress.unlockAchievement("use_all_letters")
            }
        }

        if case .numbers(let target, let playerResult, _, _) = result.details,
           playerResult == target {
            updates.append(("first_perfect", statistics.perfectNumberMatches))
            updates.append(("perfect_10", statistics.perfectNumberMatches))
        }

        for (id, value) in updates {
            progress.updateAchievement(id, progress: value)
        }

        // One-shot achievements
        if result.duration <= 30 && result.isSuccess {
            progress.unlockAchievement("speed_demon")
        }
        if result.score >= 200 {
            progress.unlockAchievement("high_score")
        }

        return newlyUnlocked(in: progress, comparedTo: unlockedBefore)
    }

    static func evaluateCombo(_ comboCount: Int, progress: inout AchievementProgress) -> [Achievement] {
        let unlockedBefore = Set(progress.achievements.values.filter { $0.isUnlocked }.map { $0.id })

        if comboCount >= 5 { progress.unlockAchievement("combo_5") }
        if comboCount >= 10 { progress.unlockAchievement("combo_10") }

        return newlyUnlocked(in: progress, comparedTo: unlockedBefore)
    }

    static func evaluateDailyChallenge(stats: DailyChallengeStats, progress: inout AchievementProgress) -> [Achievement] {
        let unlockedBefore = Set(progress.achievements.values.filter { $0.isUnlocked }.map { $0.id })

        progress.updateAchievement("daily_first", progress: stats.totalChallengesCompleted)
        progress.updateAchievement("daily_streak_7", progress: stats.currentStreak)

        return newlyUnlocked(in: progress, comparedTo: unlockedBefore)
    }

    private static func newlyUnlocked(
        in progress: AchievementProgress,
        comparedTo unlockedBefore: Set<String>
    ) -> [Achievement] {
        return progress.achievements.values
            .filter { $0.isUnlocked && !unlockedBefore.contains($0.id) }
            .sorted { $0.id < $1.id }
    }

    // MARK: - Persistence-backed entry points (must NOT be called from inside
    // PersistenceService's queue — they re-enter the public persistence API)

    func checkAchievements(after result: GameResult, with statistics: GameStatistics) -> [Achievement] {
        var progress = persistenceService.loadAchievementProgress()
        let newly = AchievementTracker.evaluate(result: result, statistics: statistics, progress: &progress)
        persistenceService.saveAchievementProgress(progress)
        return newly
    }

    func checkComboAchievement(_ comboCount: Int) -> [Achievement] {
        var progress = persistenceService.loadAchievementProgress()
        let newly = AchievementTracker.evaluateCombo(comboCount, progress: &progress)
        if !newly.isEmpty {
            persistenceService.saveAchievementProgress(progress)
        }
        return newly
    }

    func checkDailyChallengeAchievements(stats: DailyChallengeStats) -> [Achievement] {
        var progress = persistenceService.loadAchievementProgress()
        let newly = AchievementTracker.evaluateDailyChallenge(stats: stats, progress: &progress)
        if !newly.isEmpty {
            persistenceService.saveAchievementProgress(progress)
        }
        return newly
    }

    func getProgress() -> AchievementProgress {
        return persistenceService.loadAchievementProgress()
    }
}

// MARK: - Achievement Toast

/// Compact banner shown at the top of a game screen when an achievement
/// unlocks. Auto-dismisses after a few seconds or on tap.
struct AchievementToastView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Başarım Kazanıldı!")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
                Text(achievement.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(achievement.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "xmark")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .onTapGesture(perform: onDismiss)
        .task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            onDismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Başarım kazanıldı: \(achievement.title)")
    }
}
