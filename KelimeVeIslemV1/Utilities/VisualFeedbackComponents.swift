//
//  VisualFeedbackComponents.swift
//  KelimeVeIslemV1
//
//  Enhanced visual feedback components for better user experience
//

import SwiftUI

// MARK: - Letter Frequency Indicator

struct LetterFrequencyIndicator: View {
    let letter: Character
    let isRare: Bool
    let theme: ThemeColors

    private static let rareLetters: Set<Character> = ["Ç", "Ğ", "Ş", "İ", "Ö", "Ü", "J", "Q", "X", "Z", "ç", "ğ", "ş", "ı", "ö", "ü", "j", "q", "x", "z"]

    static func isRareLetter(_ letter: Character) -> Bool {
        return rareLetters.contains(letter)
    }

    var body: some View {
        if isRare {
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(theme.rareLetterHighlight)

                Text("Nadir")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(theme.rareLetterHighlight)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(theme.rareLetterHighlight.opacity(0.2))
            )
        }
    }
}

// MARK: - Letter Pool Visualization

struct LetterPoolView: View {
    let letters: [Character]
    let usedLetters: [Character]
    let theme: ThemeColors

    var letterCounts: [(letter: Character, count: Int, available: Int)] {
        let allLetters = Set(letters)
        return allLetters.map { letter in
            let total = letters.filter { $0 == letter }.count
            let used = usedLetters.filter { $0 == letter }.count
            return (letter: letter, count: total, available: total - used)
        }.sorted { $0.letter < $1.letter }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Harf Havuzu")
                .font(.caption.bold())
                .foregroundColor(theme.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(letterCounts, id: \.letter) { item in
                        LetterPoolItem(
                            letter: item.letter,
                            total: item.count,
                            available: item.available,
                            theme: theme
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
    }
}

struct LetterPoolItem: View {
    let letter: Character
    let total: Int
    let available: Int
    let theme: ThemeColors

    var isRare: Bool {
        LetterFrequencyIndicator.isRareLetter(letter)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(String(letter).uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(available > 0 ? theme.primaryText : theme.secondaryText.opacity(0.5))

            HStack(spacing: 2) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < available ? (isRare ? theme.rareLetterHighlight : theme.primaryText) : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isRare ? theme.rareLetterHighlight.opacity(0.2) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isRare ? theme.rareLetterHighlight.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Achievement Progress Bar

struct AchievementProgressBar: View {
    let progress: Double
    let theme: ThemeColors

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [theme.successColor, theme.primaryButton],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)

                // Shine effect
                if progress > 0 && progress < 1 {
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 12, height: 12)
                        .offset(x: geometry.size.width * min(progress, 1.0) - 6)
                        .blur(radius: 2)
                }
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Word Length Indicator

struct WordLengthIndicator: View {
    let currentLength: Int
    let theme: ThemeColors

    var bonusInfo: (hasBon: Bool, message: String, color: Color) {
        if currentLength >= 9 {
            return (true, "+50 Bonus!", theme.successColor)
        } else if currentLength >= 7 {
            return (true, "+20 Bonus!", theme.warningColor)
        } else if currentLength >= 5 {
            return (false, "2 harf daha!", theme.primaryText)
        } else {
            return (false, "", theme.secondaryText)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Length indicator
            HStack(spacing: 4) {
                Image(systemName: "textformat.size")
                    .font(.caption)

                Text("\(currentLength) harf")
                    .font(.caption.bold())
            }
            .foregroundColor(theme.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
            )

            // Bonus indicator
            if !bonusInfo.message.isEmpty {
                Text(bonusInfo.message)
                    .font(.caption.bold())
                    .foregroundColor(bonusInfo.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(bonusInfo.color.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(bonusInfo.color, lineWidth: 1)
                            )
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentLength)
    }
}

// MARK: - Number Proximity Indicator

struct NumberProximityIndicator: View {
    let targetNumber: Int
    let currentResult: Int?
    let theme: ThemeColors

    var proximityInfo: (message: String, color: Color, icon: String) {
        guard let result = currentResult else {
            return ("Bir çözüm deneyin", theme.secondaryText, "questionmark.circle")
        }

        let difference = abs(targetNumber - result)

        if difference == 0 {
            return ("Mükemmel! 🎯", theme.successColor, "checkmark.circle.fill")
        } else if difference <= 5 {
            return ("\(difference) uzakta", theme.warningColor, "target")
        } else if difference <= 10 {
            return ("\(difference) uzakta", theme.errorColor.opacity(0.7), "arrow.up.and.down")
        } else {
            return ("Çok uzak", theme.errorColor, "xmark.circle")
        }
    }

    var body: some View {
        if currentResult != nil {
            HStack(spacing: 8) {
                Image(systemName: proximityInfo.icon)
                    .font(.caption)

                Text(proximityInfo.message)
                    .font(.caption.bold())
            }
            .foregroundColor(proximityInfo.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(proximityInfo.color.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(proximityInfo.color.opacity(0.5), lineWidth: 1)
                    )
            )
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentResult)
        }
    }
}

// MARK: - Streak Indicator

struct StreakIndicator: View {
    let streakCount: Int
    let theme: ThemeColors

    var body: some View {
        if streakCount > 0 {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streakCount) Gün")
                        .font(.caption.bold())
                        .foregroundColor(theme.primaryText)

                    Text("Seri")
                        .font(.system(size: 10))
                        .foregroundColor(theme.secondaryText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Enhanced Timer View with Pulsing

struct EnhancedTimerView: View {
    let timeRemaining: Int
    let totalDuration: Int
    let theme: ThemeColors

    private var progress: Double {
        guard totalDuration > 0 else { return 1.0 }
        return max(0, Double(timeRemaining) / Double(totalDuration))
    }

    private var progressColor: Color {
        if timeRemaining <= 10 {
            return theme.timerCritical
        } else if timeRemaining <= 20 {
            return theme.timerWarning
        } else {
            return theme.timerNormal
        }
    }

    private var shouldPulse: Bool {
        timeRemaining <= 10
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 5)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)

            VStack {
                Image(systemName: "clock.fill")
                    .font(.caption)

                Text("\(timeRemaining)s")
                    .font(.headline.bold())
                    .monospacedDigit()
            }
            .foregroundColor(progressColor)
        }
        .frame(width: 60, height: 60)
        .padding(.vertical, 8)
        .pulsing(isActive: shouldPulse, color: progressColor)
        .accessibilityLabel("Time remaining: \(timeRemaining) seconds")
    }
}
