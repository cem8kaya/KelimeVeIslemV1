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

/// One element of the player's solution. Numbers carry the index of the tile
/// they came from so duplicate numbers in the pool stay distinguishable and
/// deletion always removes a whole number, never a single digit.
enum SolutionToken: Equatable {
    case number(value: Int, tileIndex: Int)
    case op(String) // "+", "-", "*", "/", "(", ")"

    var text: String {
        switch self {
        case .number(let value, _): return String(value)
        case .op(let symbol): return symbol
        }
    }

    var isNumber: Bool {
        if case .number = self { return true }
        return false
    }
}

@MainActor
class NumberGameViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var game: NumberGame?
    @Published private(set) var currentSolution: String = ""
    @Published private(set) var solutionTokens: [SolutionToken] = []
    @Published var timeRemaining: Int = 0
    @Published var gameState: GameState = .ready
    @Published var resultMessage: String = ""
    @Published var showHint: Bool = false
    @Published var hintSolution: [Operation]?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var comboCount: Int = 0 // Streak of successful games; persists across games
    @Published var showConfetti: Bool = false // Trigger for confetti animation
    @Published var levelUpInfo: Level? = nil // Level-up notification
    @Published var showLevelUp: Bool = false // Trigger for level-up screen
    @Published var newAchievements: [Achievement] = [] // Freshly unlocked, awaiting display
    @Published private(set) var isTimeUnlimited: Bool = false // Practice mode: no countdown
    @Published private(set) var timerTotalDuration: Int = 90 // Full duration of the running timer
    @Published private(set) var allowedOperations: [String] = ["+", "-", "*", "/"]

    // MARK: - Undo/Redo System
    @Published var commandHistory = CommandHistory()

    // MARK: - Dependencies
    
    private let numberGenerator = NumberGenerator()
    private let audioService = AudioService.shared
    private let persistenceService = PersistenceService.shared
    
    private var timer: DispatchSourceTimer?
    private var settings: GameSettings

    // Set for daily-challenge games; doubles the XP earned from the result.
    private let isDailyChallenge: Bool

    // Wall-clock start of the current game; used for the real duration in results.
    private var gameStartDate: Date?

    // MARK: - Initialization

    init(settings: GameSettings? = nil) {
        self.isDailyChallenge = false
        // Load settings synchronously so the first game can't race a deferred load
        self.settings = settings ?? PersistenceService.shared.loadSettings()
        self.comboCount = PersistenceService.shared.loadComboCount()
    }

    // Custom initializer for daily challenges with pre-generated numbers
    init(customGame: NumberGame, settings: GameSettings, isDailyChallenge: Bool = false) {
        self.isDailyChallenge = isDailyChallenge
        self.settings = settings
        self.game = customGame
        self.timeRemaining = settings.numberTimerDuration
        self.timerTotalDuration = settings.numberTimerDuration
        self.gameState = .playing
        self.currentSolution = ""
        self.resultMessage = ""
        self.showHint = false
        self.hintSolution = nil
        self.comboCount = PersistenceService.shared.loadComboCount()
    }

    // Start the game timer (call this after custom init)
    func startGameTimer() {
        guard gameState == .playing, timer == nil else { return }
        gameStartDate = Date()
        audioService.playSound(.gameStart)
        startTimer()
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
        // Get current level from statistics
        let statistics = persistenceService.loadStatistics()
        let currentLevel = statistics.level
        let difficulty = currentLevel.difficulty

        // Single difficulty source: the level system decides target range,
        // pool composition and allowed operations. The user's difficultyLevel
        // setting only applies in practice mode.
        let target: Int
        let numbers: [Int]
        if settings.practiceMode {
            let (generated, _) = numberGenerator.generateGame(difficulty: settings.difficultyLevel)
            numbers = generated
            target = Int.random(in: 10...100)
            allowedOperations = ["+", "-", "*", "/"]
        } else {
            numbers = numberGenerator.generateNumbers(
                smallCount: difficulty.smallNumberCount,
                largeCount: difficulty.largeNumberCount
            )
            target = Int.random(in: difficulty.targetNumberRange)
            allowedOperations = difficulty.allowedOperations
        }

        game = NumberGame(numbers: numbers, targetNumber: target)
        solutionTokens = []
        currentSolution = ""

        // Timer: the level's time budget applies unless the player explicitly
        // customized the duration in Settings. Practice mode has no timer at all.
        isTimeUnlimited = settings.practiceMode
        let timerDuration = settings.usesCustomTimers
            ? settings.numberTimerDuration
            : difficulty.numberTimeSeconds
        timerTotalDuration = timerDuration
        timeRemaining = settings.practiceMode ? 0 : timerDuration
        gameStartDate = Date()
        gameState = .playing
        resultMessage = ""
        showHint = false
        hintSolution = nil
        error = nil
        isLoading = false
        // The combo streak carries across games; only a failed submission resets it
        comboCount = persistenceService.loadComboCount()

        audioService.playSound(.gameStart)
        // Only start timer if not in practice mode
        if !settings.practiceMode {
            startTimer()
        }
    }
    
    // MARK: - Token-based solution editing

    /// Tile indices currently consumed by the solution, derived from the tokens.
    var usedNumberIndices: [Int] {
        solutionTokens.compactMap {
            if case .number(_, let tileIndex) = $0 { return tileIndex }
            return nil
        }
    }

    var lastTokenIsNumber: Bool {
        solutionTokens.last?.isNumber == true
    }

    private func syncSolutionFromTokens() {
        currentSolution = solutionTokens.map(\.text).joined()
        game?.updateSolution(currentSolution)
    }

    func appendToken(_ token: SolutionToken) {
        solutionTokens.append(token)
        syncSolutionFromTokens()
    }

    func removeLastToken() {
        guard !solutionTokens.isEmpty else { return }
        solutionTokens.removeLast()
        syncSolutionFromTokens()
    }

    func restoreTokens(_ tokens: [SolutionToken]) {
        solutionTokens = tokens
        syncSolutionFromTokens()
    }

    /// Rebuilds tokens from a plain string (used when restoring a saved game).
    /// Number tile indices are re-assigned greedily against the game's pool.
    func tokenize(solution: String, numbers: [Int]) -> [SolutionToken] {
        var tokens: [SolutionToken] = []
        var usedIndices: Set<Int> = []
        var digits = ""

        func flushNumber() {
            guard let value = Int(digits), !digits.isEmpty else { digits = ""; return }
            let tileIndex = numbers.indices.first { numbers[$0] == value && !usedIndices.contains($0) } ?? -1
            if tileIndex >= 0 { usedIndices.insert(tileIndex) }
            tokens.append(.number(value: value, tileIndex: tileIndex))
            digits = ""
        }

        for char in solution {
            if char.isNumber {
                digits.append(char)
            } else if "+-*/()".contains(char) {
                flushNumber()
                tokens.append(.op(String(char)))
            }
        }
        flushNumber()
        return tokens
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
                    comboCount += 1 // Extend the streak on perfect match
                    persistCombo()
                    checkComboAchievements()
                    // Trigger confetti for perfect score (100 points)
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showConfetti = false
                    }
                    resultMessage = NSLocalizedString("success.perfect_match",
                        comment: "Perfect match!")
                    audioService.playSound(.success)
                    audioService.playSuccessHaptic()
                } else if difference <= 5 {
                    comboCount += 1 // Extend the streak on close match
                    persistCombo()
                    checkComboAchievements()
                    resultMessage = String(format: NSLocalizedString("success.close_match",
                        comment: "Close! Off by %d"), difference)
                    audioService.playSound(.success)
                    audioService.playHaptic(style: .medium)
                } else {
                    comboCount = 0 // Reset the streak on far miss
                    persistCombo()
                    resultMessage = String(format: NSLocalizedString("info.result",
                        comment: "Result: %d (target: %d)"), result, game.targetNumber)
                    audioService.playSound(.buttonTap)
                }
            } else {
                comboCount = 0 // Reset the streak on invalid expression
                persistCombo()
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
        Task.detached(priority: .userInitiated) { [numberGenerator = self.numberGenerator] in
            let solution = numberGenerator.findSolution(
                numbers: game.numbers,
                target: game.targetNumber
            )
            
            await MainActor.run {
                self.isLoading = false
                
                if let solution = solution {
                    self.hintSolution = solution
                    self.showHint = true
                } else if let (_, ops) = numberGenerator.findClosestSolution(
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
    
    /// Deletes the last token: a whole number (freeing its tile) or one operator.
    func deleteLastToken() {
        guard !solutionTokens.isEmpty else { return }
        removeLastToken()
        audioService.playSound(.buttonTap)
    }

    func clearSolution() {
        solutionTokens = []
        syncSolutionFromTokens()
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
        solutionTokens = []
        currentSolution = ""
        timeRemaining = 0
        gameState = .ready
        resultMessage = ""
        showHint = false
        hintSolution = nil
        error = nil
        isLoading = false
        comboCount = persistenceService.loadComboCount()
        showConfetti = false
        commandHistory.clear()
    }

    // MARK: - Combo Persistence

    private func persistCombo() {
        guard !settings.practiceMode else { return }
        persistenceService.saveComboCount(comboCount)
    }

    private func checkComboAchievements() {
        guard !settings.practiceMode else { return }
        let unlocked = AchievementTracker.shared.checkComboAchievement(comboCount)
        if !unlocked.isEmpty {
            newAchievements.append(contentsOf: unlocked)
        }
    }

    func dismissAchievement(_ achievement: Achievement) {
        newAchievements.removeAll { $0.id == achievement.id }
    }

    // MARK: - Undo/Redo Support Methods

    func selectNumber(_ number: Int, tileIndex: Int) {
        let command = AppendTokenCommand(
            token: .number(value: number, tileIndex: tileIndex),
            viewModel: self
        )
        commandHistory.executeCommand(command)
        audioService.playSound(.buttonTap)
        audioService.playHaptic(style: .light)
    }

    func selectOperator(_ operation: String) {
        // Level gating: ×/÷ unlock at higher levels (parentheses always allowed)
        if "+-*/".contains(operation), !allowedOperations.contains(operation) {
            audioService.playErrorHaptic()
            return
        }
        let command = AppendTokenCommand(token: .op(operation), viewModel: self)
        commandHistory.executeCommand(command)
        audioService.playSound(.buttonTap)
        audioService.playHaptic(style: .light)
    }

    func clearSolutionWithCommand() {
        let command = ClearSolutionCommand(previousTokens: solutionTokens, viewModel: self)
        commandHistory.executeCommand(command)
        audioService.playSound(.buttonTap)
    }

    func performUndo() {
        commandHistory.undo()
        audioService.playSound(.buttonTap)
        audioService.playHaptic(style: .light)
    }

    func performRedo() {
        commandHistory.redo()
        audioService.playSound(.buttonTap)
        audioService.playHaptic(style: .light)
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
    
    // MARK: - Game State Persistence

    func saveGameState() {
        guard let game = game, gameState == .playing else { return }

        let savedState = SavedGameState(
            numberGame: game,
            currentSolution: currentSolution,
            timeRemaining: timeRemaining,
            score: game.score,
            comboCount: comboCount
        )

        do {
            try persistenceService.saveGameState(savedState)
            AppLog.game.info("Game state saved successfully")
        } catch {
            AppLog.game.error("Failed to save game state: \(String(describing: error))")
        }
    }

    func restoreGameState(_ savedState: SavedGameState) {
        guard savedState.gameType == .numbers,
              let restoredGame = savedState.restoreNumberGame() else {
            return
        }

        self.game = restoredGame
        self.solutionTokens = tokenize(
            solution: savedState.currentSolution ?? "",
            numbers: restoredGame.numbers
        )
        syncSolutionFromTokens()
        self.timeRemaining = savedState.timeRemaining
        self.timerTotalDuration = max(savedState.timeRemaining, settings.numberTimerDuration)
        // Approximate the original start so result durations stay meaningful
        self.gameStartDate = Date().addingTimeInterval(
            -Double(max(0, timerTotalDuration - savedState.timeRemaining))
        )
        self.comboCount = savedState.comboCount
        self.gameState = .playing
        self.resultMessage = ""
        self.showHint = false
        self.hintSolution = nil
        self.error = nil

        startTimer()
    }

    func clearSavedGameState() {
        persistenceService.clearGameState()
    }

    // MARK: - Persistence

    private func saveResult() {
        guard let game = game else { return }

        // Don't save results in practice mode
        if settings.practiceMode {
            AppLog.game.info("Practice mode: result not saved")
            return
        }

        // Real elapsed time, robust against restored games and custom timers
        let timeTaken = max(0, Int(Date().timeIntervalSince(gameStartDate ?? Date())))
        let details = GameResult.ResultDetails.numbers(
            target: game.targetNumber,
            result: game.playerResult,
            solution: game.playerSolution,
            numbers: game.numbers
        )

        // Apply combo multiplier to final score
        let finalScore = score

        let result = GameResult(
            mode: .numbers,
            score: finalScore,
            duration: timeTaken,
            details: details,
            combo: comboCount,
            isDailyChallenge: isDailyChallenge
        )
        
        // Save on background thread to avoid blocking UI
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                guard let outcome = try self?.persistenceService.saveResult(result) else { return }
                AppLog.game.info("Result saved successfully")

                DispatchQueue.main.async {
                    if let newLevel = outcome.levelUp {
                        self?.levelUpInfo = newLevel
                        self?.showLevelUp = true
                        self?.audioService.playSound(.levelUp)
                    }
                    if !outcome.newAchievements.isEmpty {
                        self?.newAchievements.append(contentsOf: outcome.newAchievements)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.error = .persistenceError("Failed to save result")
                }
                AppLog.game.error("Failed to save result: \(String(describing: error))")
            }
        }
    }
    
    // MARK: - Helpers

    func getAvailableNumbersString() -> String {
        guard let game = game else { return "" }
        return game.numbers.map { String($0) }.joined(separator: " ")
    }

    // MARK: - Combo System

    var comboMultiplier: Int {
        if comboCount >= 10 { return 5 }
        if comboCount >= 5 { return 3 }
        if comboCount >= 3 { return 2 }
        return 1
    }

    var score: Int {
        guard let game = game else { return 0 }
        return game.score * comboMultiplier
    }

    deinit {
        // Clean up timer
        timer?.cancel()
        timer = nil
    }
}
