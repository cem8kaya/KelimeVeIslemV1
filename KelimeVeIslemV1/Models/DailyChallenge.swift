//
//  DailyChallenge.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/7/25.
//


import Foundation

struct DailyChallenge: Codable, Identifiable {
    let id: UUID
    let date: Date
    let mode: GameMode
    let seed: Int
    let challengeData: ChallengeData

    init(date: Date, mode: GameMode) {
        self.id = UUID()
        self.date = date
        self.mode = mode

        // Create seed based on date for consistent daily generation
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.seed = (components.year ?? 0) * 10000 + (components.month ?? 0) * 100 + (components.day ?? 0)

        // Generate challenge data based on mode and seed
        self.challengeData = DailyChallenge.generateChallenge(for: mode, seed: seed)
    }

    enum ChallengeData: Codable {
        case letters([String])
        case numbers(numbers: [Int], target: Int)
    }

    static func generateChallenge(for mode: GameMode, seed: Int) -> ChallengeData {
        var generator = SeededRandomGenerator(seed: seed)

        switch mode {
        case .letters:
            // Generate 9 letters with proper vowel/consonant distribution
            let turkishVowels = ["A", "E", "I", "İ", "O", "Ö", "U", "Ü"]
            let turkishConsonants = ["B", "C", "Ç", "D", "F", "G", "Ğ", "H", "J", "K", "L", "M", "N", "P", "R", "S", "Ş", "T", "V", "Y", "Z"]

            var letters: [String] = []

            // Add 3-4 vowels
            let vowelCount = 3 + generator.next() % 2
            for _ in 0..<vowelCount {
                let randomIndex = generator.next() % turkishVowels.count
                letters.append(turkishVowels[randomIndex])
            }

            // Fill remaining with consonants
            let consonantCount = 9 - vowelCount
            for _ in 0..<consonantCount {
                let randomIndex = generator.next() % turkishConsonants.count
                letters.append(turkishConsonants[randomIndex])
            }

            // Shuffle letters
            letters = generator.shuffle(letters)

            return .letters(letters)

        case .numbers:
            // Generate 6 numbers: 4-5 small (1-10), 1-2 large (25, 50, 75, 100)
            let smallNumbers = Array(1...10)
            let largeNumbers = [25, 50, 75, 100]

            var numbers: [Int] = []

            // Add large numbers
            let largeCount = 1 + generator.next() % 2
            for _ in 0..<largeCount {
                let randomIndex = generator.next() % largeNumbers.count
                numbers.append(largeNumbers[randomIndex])
            }

            // Add small numbers (with possible duplicates)
            let smallCount = 6 - largeCount
            for _ in 0..<smallCount {
                let randomIndex = generator.next() % smallNumbers.count
                numbers.append(smallNumbers[randomIndex])
            }

            // Generate target number (101-999)
            let target = 101 + generator.next() % 899

            return .numbers(numbers: numbers, target: target)
        }
    }

    static func today() -> DailyChallenge {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Alternate between letters and numbers based on day
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        let mode: GameMode = dayOfYear % 2 == 0 ? .letters : .numbers

        return DailyChallenge(date: today, mode: mode)
    }

    func isSameDay(as date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self.date, inSameDayAs: date)
    }
}

// Daily Challenge Result for leaderboard
struct DailyChallengeResult: Codable, Identifiable {
    let id: UUID
    let challengeDate: Date
    let playerName: String
    let score: Int
    let duration: Int
    let completedAt: Date

    init(challengeDate: Date, playerName: String = "Sen", score: Int, duration: Int) {
        self.id = UUID()
        self.challengeDate = challengeDate
        self.playerName = playerName
        self.score = score
        self.duration = duration
        self.completedAt = Date()
    }
}

// Daily Challenge Statistics
struct DailyChallengeStats: Codable {
    var totalChallengesCompleted: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCompletedDate: Date?
    var bestScore: Int = 0
    var averageScore: Double = 0

    mutating func update(with result: DailyChallengeResult) {
        totalChallengesCompleted += 1

        // Update streak
        let calendar = Calendar.current
        if let lastDate = lastCompletedDate {
            let daysDifference = calendar.dateComponents([.day], from: lastDate, to: result.challengeDate).day ?? 0
            if daysDifference == 1 {
                currentStreak += 1
            } else if daysDifference > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastCompletedDate = result.challengeDate

        // Update best score
        if result.score > bestScore {
            bestScore = result.score
        }

        // Update average score
        let totalScore = (averageScore * Double(totalChallengesCompleted - 1)) + Double(result.score)
        averageScore = totalScore / Double(totalChallengesCompleted)
    }
}

// Seeded random number generator for consistent daily challenges
struct SeededRandomGenerator {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(seed)
    }

    mutating func next() -> Int {
        // Linear Congruential Generator
        state = (state &* 1103515245 &+ 12345) & 0x7fffffff
        return Int(state)
    }

    mutating func shuffle<T>(_ array: [T]) -> [T] {
        var shuffled = array
        for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
            let j = next() % (i + 1)
            shuffled.swapAt(i, j)
        }
        return shuffled
    }
}
