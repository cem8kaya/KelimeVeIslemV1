//
//  LetterGameViewModel.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  LetterGameViewModel.swift
//  KelimeVeIslem
//

import Foundation
import Combine
import UIKit

@MainActor
class LetterGameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var game: LetterGame?
    @Published var currentWord: String = ""
    @Published var timeRemaining: Int = 0
    @Published var gameState: GameState = .ready
    @Published var validationMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    // NEW: Expose letter count and suggested words for the View
    @Published var letterCount: Int // Expose for GameReadyView
    @Published var suggestedWords: [String] = [] // NEW: For displaying results
    @Published var comboCount: Int = 0 // Combo counter for consecutive valid submissions
    @Published var showConfetti: Bool = false // Trigger for confetti animation
    
    // MARK: - Dependencies
    
    private let letterGenerator = LetterGenerator()
    private let dictionaryService = DictionaryService.shared
    private let audioService = AudioService.shared
    private let persistenceService = PersistenceService.shared
    
    private var timer: DispatchSourceTimer?
    public var settings: GameSettings // Changed from private to public for read access
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization

    init(settings: GameSettings = PersistenceService.shared.loadSettings()) {
        self.settings = settings
        // Initialize published properties from settings
        self.letterCount = settings.letterCount
    }

    // Custom initializer for daily challenges with pre-generated letters
    init(customGame: LetterGame) {
        self.settings = PersistenceService.shared.loadSettings()
        self.letterCount = customGame.letters.count
        self.game = customGame
        self.timeRemaining = settings.letterTimerDuration
        self.gameState = .playing
        self.currentWord = ""
        self.validationMessage = ""
        self.suggestedWords = []
        self.comboCount = 0

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
        do {
            let letters = letterGenerator.generateLetters(
                count: settings.letterCount,
                language: settings.language
            )
            
            game = LetterGame(letters: letters, language: settings.language)
            currentWord = ""
            timeRemaining = settings.letterTimerDuration
            gameState = .playing
            validationMessage = ""
            error = nil
            suggestedWords = [] // Reset suggestions
            comboCount = 0 // Reset combo counter

            audioService.playSound(.gameStart)
            startTimer()
        } catch {
            self.error = .invalidInput("Failed to generate letters")
            gameState = .ready
        }
    }
    
    func updateWord(_ word: String) {
        currentWord = word.uppercased()
        game?.updateWord(currentWord)
        validationMessage = ""
    }
    
    func submitWord() async {
        guard var game = game else { return }
        
        stopTimer()
        gameState = .finished
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        // Validate word uses only available letters
        guard game.canUseLetters(currentWord) else {
            validationMessage = NSLocalizedString("error.invalid_letters",
                comment: "Uses unavailable letters")
            game.validateAndScore(isValid: false)
            self.game = game
            audioService.playSound(.failure)
            audioService.playErrorHaptic()
            saveResult()
            // No dictionary check needed if letters are invalid
            return
        }
        
        // Validate word in dictionary with timeout
        do {
            let isValid = try await withTimeout(seconds: 10) {
                await self.dictionaryService.validateWord(
                    self.currentWord,
                    language: self.settings.language,
                    useOnline: self.settings.useOnlineDictionary
                )
            }
            
            game.validateAndScore(isValid: isValid)
            self.game = game

            if isValid {
                comboCount += 1 // Increment combo on valid submission
                // Trigger confetti for 7+ letter words
                if currentWord.count >= 7 {
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showConfetti = false
                    }
                }
                validationMessage = NSLocalizedString("success.valid_word",
                    comment: "Valid word!")
                audioService.playSound(.success)
                audioService.playSuccessHaptic()
            } else {
                comboCount = 0 // Reset combo on invalid submission
                validationMessage = NSLocalizedString("error.not_in_dictionary",
                    comment: "Word not found in dictionary. Keep trying!")
                audioService.playSound(.failure)
                audioService.playErrorHaptic()

                // NEW: Find suggestions if the word is invalid
                await findSuggestedWords()
            }
            
            saveResult()
        } catch {
            self.error = .wordValidationFailed
            game.validateAndScore(isValid: false)
            self.game = game
            audioService.playSound(.failure)
            saveResult()
        }
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
        currentWord = ""
        timeRemaining = 0
        gameState = .ready
        validationMessage = ""
        error = nil
        isLoading = false
        suggestedWords = []
        comboCount = 0
        showConfetti = false
    }
    
    func shuffleLetters() {
        guard var game = game else { return }
        
        // Shuffle the letters array
        let shuffledLetters = game.letters.shuffled()
        
        // Create a new game instance with shuffled letters while preserving other properties
        var newGame = LetterGame(letters: shuffledLetters, language: game.language)
        newGame.playerWord = game.playerWord
        newGame.timeRemaining = game.timeRemaining
        newGame.score = game.score
        newGame.isValid = game.isValid
        
        self.game = newGame
        
        // Play haptic and sound feedback
        audioService.playSound(.buttonTap)
        audioService.playHaptic(style: .light)
    }
    
    // MARK: - Word Suggestions
    
    private func findSuggestedWords() async {
        guard let game = game else { return }
        
        let allLetters = game.letters.map { String($0) }
        
        // Run dictionary search on background thread to prevent UI lag
        let suggestions = await dictionaryService.findWords(
            using: allLetters,
            language: settings.language,
            maxCount: 5
        )
        
        // Update published property on main thread
        await MainActor.run {
            self.suggestedWords = suggestions
        }
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
                    await self.submitWord()
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

        let timeTaken = settings.letterTimerDuration - timeRemaining
        let details = GameResult.ResultDetails.letters(
            word: game.playerWord,
            letters: game.letters.map { String($0) },
            isValid: game.isValid ?? false
        )

        // Apply combo multiplier to final score
        let finalScore = score

        let result = GameResult(
            mode: .letters,
            score: finalScore,
            duration: timeTaken,
            details: details
        )
        
        // Save on background thread to avoid blocking UI
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                try self?.persistenceService.saveResult(result)
                print("âœ… Result saved successfully")
            } catch {
                DispatchQueue.main.async {
                    self?.error = .persistenceError("Failed to save result")
                }
                print("âš ï¸ Failed to save result: \(error)")
            }
        }
    }
    
    // MARK: - Helpers

    func getAvailableLettersString() -> String {
        guard let game = game else { return "" }
        return game.letters.map { String($0) }.joined(separator: " ")
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
        cancellables.removeAll()
    }
}

// MARK: - Timeout Helper

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw AppError.networkError("Operation timed out")
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
