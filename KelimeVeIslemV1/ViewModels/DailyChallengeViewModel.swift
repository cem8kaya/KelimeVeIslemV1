//
//  DailyChallengeViewModel.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/7/25.
//


import Foundation
import Combine

@MainActor
class DailyChallengeViewModel: ObservableObject {
    @Published var todayChallenge: DailyChallenge
    @Published var stats: DailyChallengeStats
    @Published var leaderboard: [DailyChallengeResult]
    @Published var showChallengeGame = false
    @Published var todayResult: DailyChallengeResult?

    private let persistenceService = PersistenceService.shared

    var isTodayChallengeCompleted: Bool {
        todayResult != nil
    }

    init() {
        self.todayChallenge = DailyChallenge.today()
        self.stats = persistenceService.loadDailyChallengeStats()
        self.leaderboard = persistenceService.loadDailyChallengeLeaderboard()
        self.todayResult = persistenceService.loadTodayChallengeResult()
    }

    func startChallenge() {
        showChallengeGame = true
    }

    func completeChallenge(with result: DailyChallengeResult) {
        // Save result
        todayResult = result
        persistenceService.saveTodayChallengeResult(result)

        // Update stats
        stats.update(with: result)
        persistenceService.saveDailyChallengeStats(stats)

        // Add to leaderboard
        leaderboard.insert(result, at: 0)
        persistenceService.saveDailyChallengeLeaderboard(leaderboard)

        showChallengeGame = false
    }

    func refresh() {
        stats = persistenceService.loadDailyChallengeStats()
        leaderboard = persistenceService.loadDailyChallengeLeaderboard()
        todayResult = persistenceService.loadTodayChallengeResult()

        // Check if we need to generate a new challenge for today
        if let lastResult = todayResult {
            if !todayChallenge.isSameDay(as: lastResult.challengeDate) {
                todayResult = nil
                todayChallenge = DailyChallenge.today()
            }
        }
    }
}
