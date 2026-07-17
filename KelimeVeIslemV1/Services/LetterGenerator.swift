//
//  LetterGenerator.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  LetterGenerator.swift
//  KelimeVeIslem
//

import Foundation

class LetterGenerator {
    
    // Turkish letter frequency (normalized)
    private let turkishVowels: [(letter: Character, weight: Int)] = [
        ("A", 12), ("E", 9), ("I", 8), ("İ", 8), ("O", 3), ("Ö", 1), ("U", 3), ("Ü", 2)
    ]
    
    private let turkishConsonants: [(letter: Character, weight: Int)] = [
        ("B", 3), ("C", 1), ("Ç", 1), ("D", 5), ("F", 1),
        ("G", 2), ("Ğ", 1), ("H", 2), ("J", 1), ("K", 5),
        ("L", 6), ("M", 4), ("N", 7), ("P", 1), ("R", 7),
        ("S", 4), ("Ş", 2), ("T", 4), ("V", 1), ("Y", 3),
        ("Z", 2)
    ]
    
    // English letter frequency
    private let englishVowels: [(letter: Character, weight: Int)] = [
        ("A", 8), ("E", 13), ("I", 7), ("O", 8), ("U", 3)
    ]
    
    private let englishConsonants: [(letter: Character, weight: Int)] = [
        ("B", 2), ("C", 3), ("D", 4), ("F", 2), ("G", 2),
        ("H", 6), ("J", 1), ("K", 1), ("L", 4), ("M", 2),
        ("N", 7), ("P", 2), ("Q", 1), ("R", 6), ("S", 6),
        ("T", 9), ("V", 1), ("W", 2), ("X", 1), ("Y", 2),
        ("Z", 1)
    ]
    
    /// - Parameter harderCombos: when true (higher levels), the letter set is
    ///   made harder to build words from: fewer vowels and a flatter consonant
    ///   distribution so rarer, harder-to-place consonants appear more often.
    func generateLetters(count: Int, language: GameLanguage, harderCombos: Bool = false) -> [Character] {
        guard count >= 6 && count <= 12 else {
            return []
        }

        let vowels = language == .turkish ? turkishVowels : englishVowels
        let consonants = language == .turkish ? turkishConsonants : englishConsonants

        // Normal: ~35% vowels. Harder: ~28% vowels (fewer vowels = harder).
        let vowelRatio = harderCombos ? 0.28 : 0.35
        let vowelCount = max(2, Int(Double(count) * vowelRatio))
        let consonantCount = count - vowelCount

        var letters: [Character] = []

        // Generate vowels
        for _ in 0..<vowelCount {
            letters.append(weightedRandomLetter(from: vowels))
        }

        // Generate consonants (flattened weighting when harder)
        for _ in 0..<consonantCount {
            letters.append(weightedRandomLetter(from: consonants, flatten: harderCombos))
        }

        // Shuffle the result
        return letters.shuffled()
    }

    private func weightedRandomLetter(from letters: [(letter: Character, weight: Int)], flatten: Bool = false) -> Character {
        // Flattening adds a constant to every weight, pulling the distribution
        // toward uniform so rare (harder) letters become relatively more likely.
        let flattenBonus = flatten ? 3 : 0
        let totalWeight = letters.reduce(0) { $0 + $1.weight + flattenBonus }
        guard totalWeight > 0 else { return letters.last!.letter }
        var random = Int.random(in: 0..<totalWeight)

        for (letter, weight) in letters {
            let effectiveWeight = weight + flattenBonus
            if random < effectiveWeight {
                return letter
            }
            random -= effectiveWeight
        }

        return letters.last!.letter
    }
    
    // Utility: check if a set of letters is reasonable (has enough vowels)
    func isValidLetterSet(_ letters: [Character]) -> Bool {
        let vowelSet: Set<Character> = ["A", "E", "I", "İ", "O", "Ö", "U", "Ü"]
        let vowelCount = letters.filter { vowelSet.contains($0) }.count
        
        // At least 20% vowels
        return Double(vowelCount) / Double(letters.count) >= 0.2
    }
    
    func getLetterFrequency(_ letter: Character, language: GameLanguage) -> Int {
        let vowels = language == .turkish ? turkishVowels : englishVowels
        let consonants = language == .turkish ? turkishConsonants : englishConsonants
        
        if let vowel = vowels.first(where: { $0.letter == letter }) {
            return vowel.weight
        }
        
        if let consonant = consonants.first(where: { $0.letter == letter }) {
            return consonant.weight
        }
        
        return 0
    }
}

