//
//  StatisticsViewModel.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  StatisticsViewModel.swift
//  KelimeVeIslem
//

import Foundation
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    
    @Published var statistics: GameStatistics
    @Published var recentResults: [GameResult] = []
    @Published var topLetterScores: [GameResult] = []
    @Published var topNumberScores: [GameResult] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    
    private let persistenceService = PersistenceService.shared
    
    init() {
        self.statistics = persistenceService.loadStatistics()
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        statistics = persistenceService.loadStatistics()
        recentResults = persistenceService.getRecentResults(limit: 20)
        topLetterScores = persistenceService.getTopScores(mode: .letters, limit: 10)
        topNumberScores = persistenceService.getTopScores(mode: .numbers, limit: 10)
        
        isLoading = false
    }
    
    func refresh() {
        loadData()
    }
    
    func clearAllResults() {
        do {
            try persistenceService.clearResults()
            loadData()
        } catch {
            self.error = .persistenceError("Failed to clear results")
        }
    }
    
    var hasPlayedGames: Bool {
        statistics.totalGamesPlayed > 0
    }
    
    var formattedAverageScore: String {
        String(format: "%.1f", statistics.averageScore)
    }
    
    var formattedLastPlayed: String {
        guard let lastDate = statistics.lastPlayedDate else {
            return NSLocalizedString("stats.never_played", comment: "Never")
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastDate, relativeTo: Date())
    }
    
    func formatResult(_ result: GameResult) -> String {
        switch result.details {
        case .letters(let word, _, let isValid):
            let status = isValid ? "✓" : "✗"
            return "\(status) \(word) - \(result.score) pts"
            
        case .numbers(let target, let playerResult, _, _):
            if let playerResult = playerResult {
                let diff = abs(target - playerResult)
                return "\(playerResult) / \(target) (±\(diff)) - \(result.score) pts"
            } else {
                return "\(target) - Invalid - 0 pts"
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
