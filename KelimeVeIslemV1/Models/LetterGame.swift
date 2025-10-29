//
//  LetterGame.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//


import Foundation

struct LetterGame: Codable, Identifiable {
    let id: UUID
    let letters: [Character]
    var playerWord: String
    var timeRemaining: Int
    var score: Int
    var isValid: Bool?
    let language: GameLanguage
    let createdAt: Date
    
    init(letters: [Character], language: GameLanguage = .turkish) {
        self.id = UUID()
        self.letters = letters
        self.playerWord = ""
        self.timeRemaining = 60
        self.score = 0
        self.isValid = nil
        self.language = language
        self.createdAt = Date()
    }
    
    // Custom Codable implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        // Safe decoding of letters
        if let letterStrings = try? container.decode([String].self, forKey: .letters) {
            letters = letterStrings.compactMap { $0.first }
        } else {
            letters = []
        }
        
        playerWord = try container.decode(String.self, forKey: .playerWord)
        timeRemaining = try container.decode(Int.self, forKey: .timeRemaining)
        score = try container.decode(Int.self, forKey: .score)
        isValid = try container.decodeIfPresent(Bool.self, forKey: .isValid)
        language = try container.decode(GameLanguage.self, forKey: .language)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        
        // Safe encoding of letters
        let letterStrings = letters.map { String($0) }
        try container.encode(letterStrings, forKey: .letters)
        
        try container.encode(playerWord, forKey: .playerWord)
        try container.encode(timeRemaining, forKey: .timeRemaining)
        try container.encode(score, forKey: .score)
        try container.encodeIfPresent(isValid, forKey: .isValid)
        try container.encode(language, forKey: .language)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, letters, playerWord, timeRemaining, score, isValid, language, createdAt
    }
    
    mutating func updateWord(_ word: String) {
        // Sanitize input
        let sanitized = word
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isLetter }
        
        self.playerWord = sanitized
    }
    
    mutating func validateAndScore(isValid: Bool) {
        self.isValid = isValid
        if isValid {
            self.score = calculateScore()
        } else {
            self.score = 0
        }
    }
    
    private func calculateScore() -> Int {
        guard !playerWord.isEmpty else { return 0 }
        
        // Base score: word length
        var score = playerWord.count * 10
        
        // Bonus for rare letters
        let rareLetters: Set<Character> = ["Ç", "Ğ", "Ş", "İ", "Ö", "Ü", "J", "Q", "X", "Z"]
        let rareCount = playerWord.filter { rareLetters.contains($0) }.count
        score += rareCount * 5
        
        // Length bonuses
        if playerWord.count >= 7 {
            score += 20
        }
        if playerWord.count >= 9 {
            score += 50
        }
        
        return score
    }
    
    func canUseLetters(_ word: String) -> Bool {
        var availableLetters = letters
        
        for char in word.uppercased() {
            if let index = availableLetters.firstIndex(of: char) {
                availableLetters.remove(at: index)
            } else {
                return false
            }
        }
        return true
    }
    
    func getLetterUsageCount(_ letter: Character) -> Int {
        return letters.filter { $0 == letter }.count
    }
    
    func validate() -> ValidationResult {
        if playerWord.isEmpty {
            return .empty
        }
        
        if playerWord.count < 2 {
            return .tooShort
        }
        
        if !canUseLetters(playerWord) {
            return .invalidLetters
        }
        
        return .valid
    }
    
    enum ValidationResult {
        case valid
        case empty
        case tooShort
        case invalidLetters
        
        var message: String {
            switch self {
            case .valid:
                return ""
            case .empty:
                return NSLocalizedString("error.empty_word", comment: "Please enter a word")
            case .tooShort:
                return NSLocalizedString("error.too_short", comment: "Word must be at least 2 letters")
            case .invalidLetters:
                return NSLocalizedString("error.invalid_letters", comment: "Uses unavailable letters")
            }
        }
    }
}

enum GameLanguage: String, Codable, CaseIterable {
    case turkish = "tr"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .turkish:
            return "Türkçe"
        case .english:
            return "English"
        }
    }
    
    var code: String {
        return rawValue
    }
}

