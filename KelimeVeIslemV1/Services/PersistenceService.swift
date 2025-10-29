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
    
    private let defaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "com.kelimeveislem.persistence", qos: .userInitiated)
    
    // Keys
    private let settingsKey = "gameSettings"
    private let statisticsKey = "gameStatistics"
    private let resultsKey = "gameResults"
    private let maxStoredResults = 100
    
    private init() {}
    
    // MARK: - Settings
    
    func saveSettings(_ settings: GameSettings) throws {
        try queue.sync {
            do {
                let encoded = try JSONEncoder().encode(settings)
                defaults.set(encoded, forKey: settingsKey)
                defaults.synchronize()
            } catch {
                throw AppError.persistenceError("Failed to save settings: \(error.localizedDescription)")
            }
        }
    }
    
    func loadSettings() -> GameSettings {
        return queue.sync {
            guard let data = defaults.data(forKey: settingsKey),
                  let settings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
                return .default
            }
            return settings
        }
    }
    
    // MARK: - Statistics
    
    func saveStatistics(_ statistics: GameStatistics) throws {
        try queue.sync {
            do {
                let encoded = try JSONEncoder().encode(statistics)
                defaults.set(encoded, forKey: statisticsKey)
                defaults.synchronize()
            } catch {
                throw AppError.persistenceError("Failed to save statistics: \(error.localizedDescription)")
            }
        }
    }
    
    func loadStatistics() -> GameStatistics {
        return queue.sync {
            guard let data = defaults.data(forKey: statisticsKey) else {
                return GameStatistics()
            }
            
            do {
                let statistics = try JSONDecoder().decode(GameStatistics.self, from: data)
                return statistics
            } catch {
                print("⚠️ Failed to decode statistics: \(error)")
                print("🗑️ Clearing corrupted statistics...")
                
                // Clear corrupted data
                defaults.removeObject(forKey: statisticsKey)
                defaults.synchronize()
                
                return GameStatistics()
            }
        }
    }
    
    // MARK: - Game Results
    
    func saveResult(_ result: GameResult) throws {
        try queue.sync {
            // Load results internally (we're already on the queue)
            guard let data = defaults.data(forKey: resultsKey) else {
                // No existing results, create new array
                let results = [result]
                let encoded = try JSONEncoder().encode(results)
                defaults.set(encoded, forKey: resultsKey)
                defaults.synchronize()
                
                // Update statistics
                try updateStatisticsInternal(with: result)
                return
            }
            
            var results: [GameResult]
            do {
                results = try JSONDecoder().decode([GameResult].self, from: data)
            } catch {
                print("⚠️ Failed to decode existing results: \(error)")
                print("🗑️ Starting fresh with new result")
                // If decode fails, start fresh
                results = []
            }
            
            results.insert(result, at: 0)
            
            // Keep only the most recent results
            if results.count > maxStoredResults {
                results = Array(results.prefix(maxStoredResults))
            }
            
            do {
                let encoded = try JSONEncoder().encode(results)
                defaults.set(encoded, forKey: resultsKey)
                defaults.synchronize()
            } catch {
                throw AppError.persistenceError("Failed to save result: \(error.localizedDescription)")
            }
            
            // Update statistics
            try updateStatisticsInternal(with: result)
        }
    }
    
    private func updateStatisticsInternal(with result: GameResult) throws {
        // This is called from within queue.sync, so don't use queue again
        guard let data = defaults.data(forKey: statisticsKey) else {
            var newStats = GameStatistics()
            newStats.update(with: result)
            let encoded = try JSONEncoder().encode(newStats)
            defaults.set(encoded, forKey: statisticsKey)
            defaults.synchronize()
            return
        }
        
        var stats: GameStatistics
        do {
            stats = try JSONDecoder().decode(GameStatistics.self, from: data)
        } catch {
            print("⚠️ Failed to decode statistics: \(error)")
            stats = GameStatistics()
        }
        
        stats.update(with: result)
        let encoded = try JSONEncoder().encode(stats)
        defaults.set(encoded, forKey: statisticsKey)
        defaults.synchronize()
    }
    
    func loadResults() -> [GameResult] {
        return queue.sync {
            guard let data = defaults.data(forKey: resultsKey) else {
                return []
            }
            
            do {
                let results = try JSONDecoder().decode([GameResult].self, from: data)
                return results
            } catch {
                print("⚠️ Failed to decode results: \(error)")
                print("🗑️ Clearing corrupted data...")
                
                // Clear corrupted data
                defaults.removeObject(forKey: resultsKey)
                defaults.synchronize()
                
                return []
            }
        }
    }
    
    func clearResults() throws {
        try queue.sync {
            defaults.removeObject(forKey: resultsKey)
            defaults.synchronize()
        }
    }
    
    func clearAllData() throws {
        try queue.sync {
            defaults.removeObject(forKey: settingsKey)
            defaults.removeObject(forKey: statisticsKey)
            defaults.removeObject(forKey: resultsKey)
            defaults.synchronize()
        }
    }
    
    // Force clear all data without throwing (for recovery)
    func forceResetAllData() {
        queue.async {
            self.defaults.removeObject(forKey: self.settingsKey)
            self.defaults.removeObject(forKey: self.statisticsKey)
            self.defaults.removeObject(forKey: self.resultsKey)
            self.defaults.synchronize()
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
            let results = loadResults()
            let statistics = loadStatistics()
            let settings = loadSettings()
            
            let backup = BackupData(
                results: results,
                statistics: statistics,
                settings: settings,
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
                
                // Save imported data
                let encodedResults = try JSONEncoder().encode(backup.results)
                defaults.set(encodedResults, forKey: resultsKey)
                
                try saveStatistics(backup.statistics)
                try saveSettings(backup.settings)
                
                defaults.synchronize()
            } catch {
                throw AppError.persistenceError("Failed to import data: \(error.localizedDescription)")
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
