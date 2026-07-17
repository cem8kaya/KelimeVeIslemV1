//
//  PersistenceService.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  PersistenceService.swift
//  KelimeVeIslem
//

import Foundation

class PersistenceService {

    static let shared = PersistenceService()

    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.kelimeveislem.persistence", qos: .userInitiated)

    // Keys
    private let settingsKey = "gameSettings"
    private let statisticsKey = "gameStatistics"
    private let resultsKey = "gameResults"
    private let dailyChallengeStatsKey = "dailyChallengeStats"
    private let dailyChallengeLeaderboardKey = "dailyChallengeLeaderboard"
    private let todayChallengeResultKey = "todayChallengeResult"
    private let achievementProgressKey = "achievementProgress"
    private let savedGameStateKey = "savedGameState"
    private let maxStoredResults = 100
    private let maxLeaderboardEntries = 50

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Locked primitives (must only be called from inside `queue`)
    //
    // Every public API below wraps exactly one queue.sync/queue.async block and
    // delegates to these helpers. Never call a public API from inside another
    // public API's queue block — that nests sync on a serial queue and deadlocks.

    private func loadSettingsLocked() -> GameSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    private func saveSettingsLocked(_ settings: GameSettings) throws {
        do {
            let encoded = try JSONEncoder().encode(settings)
            defaults.set(encoded, forKey: settingsKey)
        } catch {
            throw AppError.persistenceError("Failed to save settings: \(error.localizedDescription)")
        }
    }

    private func loadStatisticsLocked() -> GameStatistics {
        guard let data = defaults.data(forKey: statisticsKey) else {
            return GameStatistics()
        }

        do {
            return try JSONDecoder().decode(GameStatistics.self, from: data)
        } catch {
            print("⚠️ Failed to decode statistics: \(error)")
            print("🗑️ Clearing corrupted statistics...")
            defaults.removeObject(forKey: statisticsKey)
            return GameStatistics()
        }
    }

    private func saveStatisticsLocked(_ statistics: GameStatistics) throws {
        do {
            let encoded = try JSONEncoder().encode(statistics)
            defaults.set(encoded, forKey: statisticsKey)
        } catch {
            throw AppError.persistenceError("Failed to save statistics: \(error.localizedDescription)")
        }
    }

    private func loadResultsLocked() -> [GameResult] {
        guard let data = defaults.data(forKey: resultsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([GameResult].self, from: data)
        } catch {
            print("⚠️ Failed to decode results: \(error)")
            print("🗑️ Clearing corrupted data...")
            defaults.removeObject(forKey: resultsKey)
            return []
        }
    }

    private func saveResultsLocked(_ results: [GameResult]) throws {
        do {
            let encoded = try JSONEncoder().encode(results)
            defaults.set(encoded, forKey: resultsKey)
        } catch {
            throw AppError.persistenceError("Failed to save results: \(error.localizedDescription)")
        }
    }

    // MARK: - Settings

    func saveSettings(_ settings: GameSettings) throws {
        try queue.sync {
            try saveSettingsLocked(settings)
        }
    }

    func loadSettings() -> GameSettings {
        return queue.sync {
            loadSettingsLocked()
        }
    }

    // MARK: - Saved Game State

    func saveGameState(_ gameState: SavedGameState) throws {
        try queue.sync {
            do {
                let encoded = try JSONEncoder().encode(gameState)
                defaults.set(encoded, forKey: savedGameStateKey)
            } catch {
                throw AppError.persistenceError("Failed to save game state: \(error.localizedDescription)")
            }
        }
    }

    func loadGameState() -> SavedGameState? {
        return queue.sync {
            guard let data = defaults.data(forKey: savedGameStateKey),
                  let gameState = try? JSONDecoder().decode(SavedGameState.self, from: data),
                  gameState.isValid() else {
                // Remove invalid or expired game state
                defaults.removeObject(forKey: savedGameStateKey)
                return nil
            }
            return gameState
        }
    }

    func clearGameState() {
        queue.sync {
            defaults.removeObject(forKey: savedGameStateKey)
        }
    }

    // MARK: - Statistics

    func saveStatistics(_ statistics: GameStatistics) throws {
        try queue.sync {
            try saveStatisticsLocked(statistics)
        }
    }

    func loadStatistics() -> GameStatistics {
        return queue.sync {
            loadStatisticsLocked()
        }
    }

    // MARK: - Game Results

    func saveResult(_ result: GameResult) throws -> Level? {
        return try queue.sync {
            var results = loadResultsLocked()
            results.insert(result, at: 0)

            // Keep only the most recent results
            if results.count > maxStoredResults {
                results = Array(results.prefix(maxStoredResults))
            }

            try saveResultsLocked(results)

            // Update statistics and get level-up info
            let levelUp = try updateStatisticsLocked(with: result)

            // Check achievements
            checkAchievementsLocked(for: result)

            return levelUp
        }
    }

    private func checkAchievementsLocked(for result: GameResult) {
        let statistics = loadStatisticsLocked()

        // Run achievement check asynchronously; AchievementTracker re-enters the
        // public persistence API, so it must not run inside the queue.
        DispatchQueue.global(qos: .background).async {
            let _ = AchievementTracker.shared.checkAchievements(after: result, with: statistics)
        }
    }

    private func updateStatisticsLocked(with result: GameResult) throws -> Level? {
        var stats = loadStatisticsLocked()
        let levelUp = stats.update(with: result)
        try saveStatisticsLocked(stats)

        if let newLevel = levelUp {
            print("🎉 LEVEL UP! Reached level \(newLevel.levelNumber)")
        }

        return levelUp
    }

    func loadResults() -> [GameResult] {
        return queue.sync {
            loadResultsLocked()
        }
    }

    func clearResults() throws {
        queue.sync {
            defaults.removeObject(forKey: resultsKey)
        }
    }

    func clearAllData() throws {
        queue.sync {
            defaults.removeObject(forKey: settingsKey)
            defaults.removeObject(forKey: statisticsKey)
            defaults.removeObject(forKey: resultsKey)
        }
    }

    // Force clear all data without throwing (for recovery)
    func forceResetAllData() {
        queue.async {
            self.defaults.removeObject(forKey: self.settingsKey)
            self.defaults.removeObject(forKey: self.statisticsKey)
            self.defaults.removeObject(forKey: self.resultsKey)
            print("🔄 All data has been reset")
        }
    }

    // MARK: - Quick Access Helpers

    func getRecentResults(limit: Int = 10) -> [GameResult] {
        let results = loadResults()
        return Array(results.prefix(limit))
    }

    func getResultsByMode(_ mode: GameMode) -> [GameResult] {
        return loadResults().filter { $0.mode == mode }
    }

    func getTopScores(mode: GameMode, limit: Int = 10) -> [GameResult] {
        let results = getResultsByMode(mode)
        return Array(results.sorted { $0.score > $1.score }.prefix(limit))
    }

    // MARK: - Backup & Restore

    func exportData() throws -> Data {
        return try queue.sync {
            let backup = BackupData(
                results: loadResultsLocked(),
                statistics: loadStatisticsLocked(),
                settings: loadSettingsLocked(),
                version: "2.0",
                exportDate: Date()
            )

            do {
                return try JSONEncoder().encode(backup)
            } catch {
                throw AppError.persistenceError("Failed to export data: \(error.localizedDescription)")
            }
        }
    }

    func importData(from data: Data) throws {
        try queue.sync {
            do {
                let backup = try JSONDecoder().decode(BackupData.self, from: data)

                try saveResultsLocked(backup.results)
                try saveStatisticsLocked(backup.statistics)
                try saveSettingsLocked(backup.settings)
            } catch {
                throw AppError.persistenceError("Failed to import data: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Daily Challenge

    func saveDailyChallengeStats(_ stats: DailyChallengeStats) {
        queue.async {
            do {
                let encoded = try JSONEncoder().encode(stats)
                self.defaults.set(encoded, forKey: self.dailyChallengeStatsKey)
            } catch {
                print("⚠️ Failed to save daily challenge stats: \(error)")
            }
        }
    }

    func loadDailyChallengeStats() -> DailyChallengeStats {
        return queue.sync {
            guard let data = defaults.data(forKey: dailyChallengeStatsKey) else {
                return DailyChallengeStats()
            }

            do {
                return try JSONDecoder().decode(DailyChallengeStats.self, from: data)
            } catch {
                print("⚠️ Failed to decode daily challenge stats: \(error)")
                return DailyChallengeStats()
            }
        }
    }

    func saveDailyChallengeLeaderboard(_ results: [DailyChallengeResult]) {
        queue.async {
            // Keep only the most recent entries
            let limitedResults = Array(results.prefix(self.maxLeaderboardEntries))

            do {
                let encoded = try JSONEncoder().encode(limitedResults)
                self.defaults.set(encoded, forKey: self.dailyChallengeLeaderboardKey)
            } catch {
                print("⚠️ Failed to save daily challenge leaderboard: \(error)")
            }
        }
    }

    func loadDailyChallengeLeaderboard() -> [DailyChallengeResult] {
        return queue.sync {
            guard let data = defaults.data(forKey: dailyChallengeLeaderboardKey) else {
                return []
            }

            do {
                return try JSONDecoder().decode([DailyChallengeResult].self, from: data)
            } catch {
                print("⚠️ Failed to decode daily challenge leaderboard: \(error)")
                return []
            }
        }
    }

    func saveTodayChallengeResult(_ result: DailyChallengeResult) {
        queue.async {
            do {
                let encoded = try JSONEncoder().encode(result)
                self.defaults.set(encoded, forKey: self.todayChallengeResultKey)
            } catch {
                print("⚠️ Failed to save today's challenge result: \(error)")
            }
        }
    }

    func loadTodayChallengeResult() -> DailyChallengeResult? {
        return queue.sync {
            guard let data = defaults.data(forKey: todayChallengeResultKey) else {
                return nil
            }

            do {
                let result = try JSONDecoder().decode(DailyChallengeResult.self, from: data)

                // Check if it's still today's result
                let calendar = Calendar.current
                if calendar.isDateInToday(result.challengeDate) {
                    return result
                } else {
                    // Clear old result
                    defaults.removeObject(forKey: todayChallengeResultKey)
                    return nil
                }
            } catch {
                print("⚠️ Failed to decode today's challenge result: \(error)")
                return nil
            }
        }
    }

    // MARK: - Achievements

    func saveAchievementProgress(_ progress: AchievementProgress) {
        queue.async {
            do {
                let encoded = try JSONEncoder().encode(progress)
                self.defaults.set(encoded, forKey: self.achievementProgressKey)
            } catch {
                print("⚠️ Failed to save achievement progress: \(error)")
            }
        }
    }

    func loadAchievementProgress() -> AchievementProgress {
        return queue.sync {
            guard let data = defaults.data(forKey: achievementProgressKey) else {
                return AchievementProgress()
            }

            do {
                return try JSONDecoder().decode(AchievementProgress.self, from: data)
            } catch {
                print("⚠️ Failed to decode achievement progress: \(error)")
                return AchievementProgress()
            }
        }
    }
}

// MARK: - Backup Data Structure

struct BackupData: Codable {
    let results: [GameResult]
    let statistics: GameStatistics
    let settings: GameSettings
    let version: String
    let exportDate: Date
}
