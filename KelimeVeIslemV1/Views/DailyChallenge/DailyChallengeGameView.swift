//
//  DailyChallengeGameView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/7/25.
//


import SwiftUI

struct DailyChallengeGameView: View {
    let challenge: DailyChallenge
    let onComplete: (DailyChallengeResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startTime = Date()

    var body: some View {
        ZStack {
            // Delegate to appropriate game view based on mode
            switch challenge.challengeData {
            case .letters(let letters):
                DailyChallengeLetterGameView(
                    letters: letters,
                    startTime: startTime,
                    onComplete: { score, duration in
                        let result = DailyChallengeResult(
                            challengeDate: challenge.date,
                            score: score * 2, // 2x multiplier for daily challenge
                            duration: duration
                        )
                        onComplete(result)
                    },
                    onDismiss: { dismiss() }
                )

            case .numbers(let numbers, let target):
                DailyChallengeNumberGameView(
                    numbers: numbers,
                    target: target,
                    startTime: startTime,
                    onComplete: { score, duration in
                        let result = DailyChallengeResult(
                            challengeDate: challenge.date,
                            score: score * 2, // 2x multiplier for daily challenge
                            duration: duration
                        )
                        onComplete(result)
                    },
                    onDismiss: { dismiss() }
                )
            }
        }
        .onAppear {
            startTime = Date()
        }
    }
}

// MARK: - Daily Challenge Letter Game View

struct DailyChallengeLetterGameView: View {
    let letters: [String]
    let startTime: Date
    let onComplete: (Int, Int) -> Void
    let onDismiss: () -> Void

    @StateObject private var viewModel: LetterGameViewModel
    @State private var showResult = false
    @State private var finalScore = 0
    @State private var finalDuration = 0
    @State private var usedLetterIndices: Set<Int> = []

    init(letters: [String], startTime: Date, onComplete: @escaping (Int, Int) -> Void, onDismiss: @escaping () -> Void) {
        self.letters = letters
        self.startTime = startTime
        self.onComplete = onComplete
        self.onDismiss = onDismiss

        // Create a custom letter game with the provided letters, honouring the
        // player's real settings (language, timer durations) instead of defaults.
        let settings = PersistenceService.shared.loadSettings()
        let game = LetterGame(letters: letters.map { Character($0) }, language: settings.language)
        _viewModel = StateObject(wrappedValue: LetterGameViewModel(
            customGame: game,
            settings: settings,
            isDailyChallenge: true
        ))
    }

    var body: some View {
        ZStack {
            // Background with daily challenge theme
            LinearGradient(
                colors: [Color(hex: "#8B5CF6").opacity(0.9), Color(hex: "#EC4899").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Daily Challenge Badge
                    HStack(spacing: 5) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.headline)
                        Text("GÜNLÜK MEYDAN OKUMA")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.2))
                    )

                    Spacer()

                    TimerView(timeRemaining: viewModel.timeRemaining, mode: .letters)
                }
                .padding(.horizontal)

                // Score with 2x indicator
                HStack(spacing: 10) {
                    ScoreView(score: viewModel.score)

                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                        Text("2x")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange, lineWidth: 1.5)
                            )
                    )
                }

                // Combo View
                if viewModel.comboCount >= 2 {
                    ComboView(comboCount: viewModel.comboCount)
                }

                Spacer()

                // Current word
                Text(viewModel.currentWord.isEmpty ? "Kelime Oluştur" : viewModel.currentWord)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(height: 60)

                // Letter tiles
                if let game = viewModel.game {
                    DailyChallengeLetterTilesView(
                        letters: game.letters.map { String($0) },
                        usedIndices: usedLetterIndices,
                        onLetterTap: { index in
                            guard let currentGame = viewModel.game else { return }
                            usedLetterIndices.insert(index)
                            let letter = currentGame.letters[index]
                            let newWord = viewModel.currentWord + String(letter)
                            viewModel.updateWord(newWord)
                        }
                    )
                    .padding(.horizontal)
                }

                // Action buttons
                HStack(spacing: 15) {
                    Button(action: {
                        viewModel.updateWord("")
                        usedLetterIndices.removeAll()
                    }) {
                        Label("Temizle", systemImage: "arrow.uturn.backward")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(15)
                    }
                    .buttonStyle(GrowingButton())

                    Button(action: {
                        viewModel.shuffleLetters()
                        usedLetterIndices.removeAll()
                    }) {
                        Label("Karıştır", systemImage: "arrow.triangle.2.circlepath")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(15)
                    }
                    .buttonStyle(GrowingButton())
                }
                .padding(.horizontal)

                // Submit button
                Button(action: {
                    Task {
                        await viewModel.submitWord()
                    }
                }) {
                    Text("Gönder")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            viewModel.currentWord.count >= 2 ?
                            Color.green : Color.gray.opacity(0.5)
                        )
                        .cornerRadius(15)
                }
                .buttonStyle(GrowingButton())
                .disabled(viewModel.currentWord.count < 2)
                .padding(.horizontal)

                // Return to Menu button
                Button(action: onDismiss) {
                    HStack {
                        Image(systemName: "house.circle.fill")
                        Text("Ana Menüye Dön")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#EF4444"), Color(hex: "#DC2626")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 5)

                Spacer()
            }
            .padding(.top, 20)

            // Loading overlay
            if viewModel.isLoading {
                LoadingOverlay(message: "Kelime kontrol ediliyor...")
            }

            // Confetti
            ConfettiView(trigger: viewModel.showConfetti)
        }
        .onAppear {
            // The custom init leaves the game in .playing without a running
            // timer; start the countdown when the view actually appears.
            viewModel.startGameTimer()
        }
        .onChange(of: viewModel.gameState) { oldValue, newValue in
            if case .finished = newValue {
                let duration = Int(Date().timeIntervalSince(startTime))
                finalScore = viewModel.score
                finalDuration = duration
                showResult = true
            }
        }
        .sheet(isPresented: $showResult) {
            DailyChallengeResultSheet(
                score: finalScore,
                duration: finalDuration,
                multiplier: 2,
                onContinue: {
                    onComplete(finalScore, finalDuration)
                }
            )
        }
    }
}

// MARK: - Daily Challenge Number Game View

struct DailyChallengeNumberGameView: View {
    let numbers: [Int]
    let target: Int
    let startTime: Date
    let onComplete: (Int, Int) -> Void
    let onDismiss: () -> Void

    @StateObject private var viewModel: NumberGameViewModel
    @State private var showResult = false
    @State private var finalScore = 0
    @State private var finalDuration = 0
    @State private var usedNumberIndices: Set<Int> = []

    init(numbers: [Int], target: Int, startTime: Date, onComplete: @escaping (Int, Int) -> Void, onDismiss: @escaping () -> Void) {
        self.numbers = numbers
        self.target = target
        self.startTime = startTime
        self.onComplete = onComplete
        self.onDismiss = onDismiss

        // Create a custom number game with the provided numbers and target,
        // honouring the player's real settings instead of defaults.
        let settings = PersistenceService.shared.loadSettings()
        let game = NumberGame(numbers: numbers, targetNumber: target)
        _viewModel = StateObject(wrappedValue: NumberGameViewModel(
            customGame: game,
            settings: settings,
            isDailyChallenge: true
        ))
    }

    private func handleNumberTap(_ number: Int, at index: Int) {
        // Same rules as the main game: each tile once, no two numbers in a row.
        guard !usedNumberIndices.contains(index) else {
            AudioService.shared.playErrorHaptic()
            return
        }
        if viewModel.currentSolution.last?.isNumber == true {
            AudioService.shared.playErrorHaptic()
            return
        }
        viewModel.addToSolution("\(number)")
        usedNumberIndices.insert(index)
    }

    var body: some View {
        ZStack {
            // Background with daily challenge theme
            LinearGradient(
                colors: [Color(hex: "#8B5CF6").opacity(0.9), Color(hex: "#EC4899").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Daily Challenge Badge
                    HStack(spacing: 5) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.headline)
                        Text("GÜNLÜK MEYDAN OKUMA")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.2))
                    )

                    Spacer()

                    TimerView(timeRemaining: viewModel.timeRemaining, mode: .numbers)
                }
                .padding(.horizontal)

                // Score with 2x indicator
                HStack(spacing: 10) {
                    ScoreView(score: viewModel.score)

                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                        Text("2x")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange, lineWidth: 1.5)
                            )
                    )
                }

                // Combo View
                if viewModel.comboCount >= 2 {
                    ComboView(comboCount: viewModel.comboCount)
                }

                // Target number
                VStack(spacing: 8) {
                    Text("Hedef Sayı")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    Text("\(target)")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )

                // Available numbers — index-based so duplicate numbers get
                // distinct tiles and each tile can only be used once.
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(numbers.indices, id: \.self) { index in
                        let number = numbers[index]
                        let isUsed = usedNumberIndices.contains(index)
                        Button(action: {
                            handleNumberTap(number, at: index)
                        }) {
                            Text("\(number)")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(isUsed ? Color.gray.opacity(0.4) : Color.blue.opacity(0.7))
                                .cornerRadius(15)
                                .opacity(isUsed ? 0.5 : 1.0)
                        }
                        .buttonStyle(GrowingButton())
                        .disabled(isUsed)
                    }
                }
                .padding(.horizontal)

                // Solution input
                Text(viewModel.currentSolution.isEmpty ? "Çözümünüzü girin" : viewModel.currentSolution)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(height: 40)

                // Number pad (operators)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(["+", "-", "×", "÷"], id: \.self) { op in
                        Button(action: {
                            let actualOp = op == "×" ? "*" : op == "÷" ? "/" : op
                            viewModel.addToSolution(actualOp)
                        }) {
                            Text(op)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.orange.opacity(0.7))
                                .cornerRadius(12)
                        }
                        .buttonStyle(GrowingButton())
                    }
                }
                .padding(.horizontal)

                // Action buttons
                HStack(spacing: 15) {
                    Button(action: {
                        viewModel.clearSolution()
                        usedNumberIndices.removeAll()
                    }) {
                        Label("Temizle", systemImage: "arrow.uturn.backward")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(15)
                    }
                    .buttonStyle(GrowingButton())

                    Button(action: {
                        viewModel.submitSolution()
                    }) {
                        Label("Gönder", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.green)
                            .cornerRadius(15)
                    }
                    .buttonStyle(GrowingButton())
                    .disabled(viewModel.currentSolution.isEmpty)
                }
                .padding(.horizontal)

                // Return to Menu button
                Button(action: onDismiss) {
                    HStack {
                        Image(systemName: "house.circle.fill")
                        Text("Ana Menüye Dön")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#EF4444"), Color(hex: "#DC2626")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 5)

                Spacer()
            }
            .padding(.top, 20)

            // Confetti
            ConfettiView(trigger: viewModel.showConfetti)
        }
        .onAppear {
            // The custom init leaves the game in .playing without a running
            // timer; start the countdown when the view actually appears.
            viewModel.startGameTimer()
        }
        .onChange(of: viewModel.gameState) { oldValue, newValue in
            if case .finished = newValue {
                let duration = Int(Date().timeIntervalSince(startTime))
                finalScore = viewModel.score
                finalDuration = duration
                showResult = true
            }
        }
        .sheet(isPresented: $showResult) {
            DailyChallengeResultSheet(
                score: finalScore,
                duration: finalDuration,
                multiplier: 2,
                onContinue: {
                    onComplete(finalScore, finalDuration)
                }
            )
        }
    }
}

// MARK: - Daily Challenge Result Sheet

struct DailyChallengeResultSheet: View {
    let score: Int
    let duration: Int
    let multiplier: Int
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#10B981").opacity(0.9), Color(hex: "#059669").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Success Icon
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)

                // Title
                Text("Meydan Okuma Tamamlandı!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Stats
                VStack(spacing: 20) {
                    HStack {
                        Text("Temel Skor:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        Spacer()

                        Text("\(score / multiplier)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    HStack {
                        Text("Çarpan:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        Spacer()

                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(multiplier)x")
                                .font(.title2.bold())
                                .foregroundColor(.orange)
                        }
                    }

                    Divider()
                        .background(Color.white)

                    HStack {
                        Text("Toplam Skor:")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Spacer()

                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(score)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }

                    HStack {
                        Text("Süre:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        Spacer()

                        Text("\(duration)s")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
                .padding(.horizontal, 40)

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    Text("Devam Et")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(15)
                }
                .buttonStyle(GrowingButton())
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Daily Challenge Letter Tiles View

struct DailyChallengeLetterTilesView: View {
    let letters: [String]
    let usedIndices: Set<Int>
    let onLetterTap: (Int) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(letters.indices, id: \.self) { index in
                let letter = letters[index]
                Button(action: {
                    onLetterTap(index)
                }) {
                    Text(letter)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 90, height: 90)
                        .background(
                            usedIndices.contains(index) ?
                            Color.gray.opacity(0.5) : Color.cyan.opacity(0.7)
                        )
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                }
                .buttonStyle(GrowingButton())
                .disabled(usedIndices.contains(index))
            }
        }
    }
}
