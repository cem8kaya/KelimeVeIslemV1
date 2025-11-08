//
//  SavedGameState.swift
//  KelimeVeIslemV1
//
//  Model for persisting game state when app backgrounds
//

import Foundation

struct SavedGameState: Codable {
    let gameType: GameMode
    let timestamp: Date
    let timeRemaining: Int
    let score: Int
    let comboCount: Int

    // Letter game specific
    let letters: [String]?
    let currentWord: String?

    // Number game specific
    let numbers: [Int]?
    let targetNumber: Int?
    let currentSolution: String?

    // Shared settings
    let language: GameLanguage?

    init(letterGame: LetterGame, currentWord: String, timeRemaining: Int, score: Int, comboCount: Int) {
        self.gameType = .letters
        self.timestamp = Date()
        self.timeRemaining = timeRemaining
        self.score = score
        self.comboCount = comboCount
        self.letters = letterGame.letters.map { String($0) }
        self.currentWord = currentWord
        self.language = letterGame.language
        self.numbers = nil
        self.targetNumber = nil
        self.currentSolution = nil
    }

    init(numberGame: NumberGame, currentSolution: String, timeRemaining: Int, score: Int, comboCount: Int) {
        self.gameType = .numbers
        self.timestamp = Date()
        self.timeRemaining = timeRemaining
        self.score = score
        self.comboCount = comboCount
        self.numbers = numberGame.numbers
        self.targetNumber = numberGame.targetNumber
        self.currentSolution = currentSolution
        self.letters = nil
        self.currentWord = nil
        self.language = nil
    }

    // Check if saved state is still valid (not too old)
    func isValid() -> Bool {
        let hoursSinceLastSave = Date().timeIntervalSince(timestamp) / 3600
        return hoursSinceLastSave < 24 // Valid for 24 hours
    }

    // Restore LetterGame from saved state
    func restoreLetterGame() -> LetterGame? {
        guard gameType == .letters,
              let letters = letters,
              let language = language else {
            return nil
        }

        var game = LetterGame(
            letters: letters.compactMap { $0.first },
            language: language
        )
        game.playerWord = currentWord ?? ""
        game.score = score
        game.timeRemaining = timeRemaining
        return game
    }

    // Restore NumberGame from saved state
    func restoreNumberGame() -> NumberGame? {
        guard gameType == .numbers,
              let numbers = numbers,
              let targetNumber = targetNumber else {
            return nil
        }

        var game = NumberGame(
            numbers: numbers,
            targetNumber: targetNumber
        )
        game.playerSolution = currentSolution ?? ""
        game.score = score
        return game
    }
}
