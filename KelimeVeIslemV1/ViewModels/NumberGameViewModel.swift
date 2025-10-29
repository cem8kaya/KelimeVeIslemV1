//
//  NumberGameViewModel.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  NumberGameViewModel.swift
//  KelimeVeIslem
//

import Foundation
import Combine
import UIKit

@MainActor
class NumberGameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var game: NumberGame?
    @Published var currentSolution: String = ""
    @Published var timeRemaining: Int = 0
    @Published var gameState: GameState = .ready
    @Published var resultMessage: String = ""
    @Published var showHint: Bool = false
    @Published var hintSolution: [Operation]?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    
    // MARK: - Dependencies
    
    private let numberGenerator = NumberGenerator()
    private let audioService = AudioService.shared
    private let persistenceService = PersistenceService.shared
    
    private var timer: DispatchSourceTimer?
    private var settings: GameSettings
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(settings: GameSettings = PersistenceService.shared.loadSettings()) {
        self.settings = settings
    }
    
    // MARK: - Game States
    
    enum GameState {
        case ready
        case playing
        case paused
        case finished
    }
    
    // MARK: - Game Actions
    
    func startNewGame() {
        let (numbers, target) = numberGenerator.generateGame(difficulty: settings.difficultyLevel)
        
        game = NumberGame(numbers: numbers, targetNumber: target)
        currentSolution = ""
        timeRemaining = settings.numberTimerDuration
        gameState = .playing
        resultMessage = ""
        showHint = false
        hintSolution = nil
        error = nil
        isLoading = false
        
        audioService.playSound(.gameStart)
        startTimer()
    }
    
    func updateSolution(_ solution: String) {
        currentSolution = solution
        game?.updateSolution(solution)
    }
    
    func submitSolution() {
        guard var game = game else { return }
        
        stopTimer()
        gameState = .finished
        
        do {
            try game.evaluateAndScore()
            self.game = game
            
            if let result = game.playerResult {
                let difference = abs(game.targetNumber - result)
                
                if difference == 0 {
                    resultMessage = NSLocalizedString("success.perfect_match",
                        comment: "Perfect match!")
                    audioService.playSound(.success)
                    audioService.playSuccessHaptic()
                } else if difference <= 5 {
                    resultMessage = String(format: NSLocalizedString("success.close_match",
                        comment: "Close! Off by %d"), difference)
                    audioService.playSound(.success)
                    audioService.playHaptic(style: .medium)
                } else {
                    resultMessage = String(format: NSLocalizedString("info.result",
                        comment: "Result: %d (target: %d)"), result, game.targetNumber)
                    audioService.playSound(.buttonTap)
                }
            } else {
                resultMessage = NSLocalizedString("error.invalid_expression",
                    comment: "Invalid expression")
                audioService.playSound(.failure)
                audioService.playErrorHaptic()
            }
            
            saveResult()
        } catch {
            self.error = .expressionEvaluationFailed
            audioService.playSound(.failure)
            audioService.playErrorHaptic()
        }
    }
    
    func requestHint() {
        guard let game = game else { return }
        
        isLoading = true
        
        // Run solver in background
        Task.detached(priority: .userInitiated) {
            let solution = self.numberGenerator.findSolution(
                numbers: game.numbers,
                target: game.targetNumber
            )
            
            await MainActor.run {
                self.isLoading = false
                
                if let solution = solution {
                    self.hintSolution = solution
                    self.showHint = true
                } else if let (_, ops) = self.numberGenerator.findClosestSolution(
                    numbers: game.numbers,
                    target: game.targetNumber
                ) {
                    self.hintSolution = ops
                    self.showHint = true
                } else {
                    self.error = .invalidInput("No solution found")
                }
                
                self.audioService.playHaptic()
            }
        }
    }
    
    func addToSolution(_ text: String) {
        currentSolution += text
        updateSolution(currentSolution)
        audioService.playSound(.buttonTap)
    }
    
    func deleteLast() {
        if !currentSolution.isEmpty {
            currentSolution.removeLast()
            updateSolution(currentSolution)
            audioService.playSound(.buttonTap)
        }
    }
    
    func clearSolution() {
        currentSolution = ""
        updateSolution(currentSolution)
        audioService.playSound(.buttonTap)
    }
    
    func pauseGame() {
        guard gameState == .playing else { return }
        stopTimer()
        gameState = .paused
    }
    
    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        startTimer()
    }
    
    func resetGame() {
        stopTimer()
        game = nil
        currentSolution = ""
        timeRemaining = 0
        gameState = .ready
        resultMessage = ""
        showHint = false
        hintSolution = nil
        error = nil
        isLoading = false
    }
    
    // MARK: - Timer Management (DispatchSource)
    
    private func startTimer() {
        // Cancel existing timer
        stopTimer()
        
        // Create dispatch timer on global queue
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: 1.0)
        
        timer.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    
                    // Play tick sound in last 10 seconds
                    if self.timeRemaining <= 10 {
                        self.audioService.playSound(.tick)
                    }
                    
                    // Warning at 10 seconds
                    if self.timeRemaining == 10 {
                        self.audioService.playSound(.timeWarning)
                    }
                } else {
                    // Time's up
                    self.stopTimer()
                    self.submitSolution()
                }
            }
        }
        
        timer.resume()
        self.timer = timer
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    // MARK: - Persistence
    
    private func saveResult() {
        guard let game = game else { return }
        
        let timeTaken = settings.numberTimerDuration - timeRemaining
        let details = GameResult.ResultDetails.numbers(
            target: game.targetNumber,
            result: game.playerResult,
            solution: game.playerSolution,
            numbers: game.numbers
        )
        
        let result = GameResult(
            mode: .numbers,
            score: game.score,
            duration: timeTaken,
            details: details
        )
        
        // Save on background thread to avoid blocking UI
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                try self?.persistenceService.saveResult(result)
                print("✅ Result saved successfully")
            } catch {
                DispatchQueue.main.async {
                    self?.error = .persistenceError("Failed to save result")
                }
                print("⚠️ Failed to save result: \(error)")
            }
        }
    }
    
    // MARK: - Helpers
    
    func getAvailableNumbersString() -> String {
        guard let game = game else { return "" }
        return game.numbers.map { String($0) }.joined(separator: " ")
    }
    
    deinit {
        // Clean up timer
        timer?.cancel()
        timer = nil
        cancellables.removeAll()
    }
}
