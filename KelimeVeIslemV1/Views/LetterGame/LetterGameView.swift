//
//  LetterGameView.swift
//  KelimeVeIslem
//

import SwiftUI

struct LetterGameView: View {

    let savedGameState: SavedGameState?

    @StateObject private var viewModel = LetterGameViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showResult = false
    @State private var showError = false
    @State private var showExitConfirmation = false
    @State private var showParticles = false
    @FocusState private var isTextFieldFocused: Bool

    init(savedGameState: SavedGameState? = nil) {
        self.savedGameState = savedGameState
    }
    
    var body: some View {
        mainContent
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showResult) {
                resultSheet
            }
            .alert("Hata", isPresented: $showError, presenting: viewModel.error) { error in
                Button("Tamam") {
                    showError = false
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .confirmationDialog(
                "Oyundan Çıkılsın mı?",
                isPresented: $showExitConfirmation,
                titleVisibility: .visible
            ) {
                Button("Oyundan Çık", role: .destructive) {
                    viewModel.resetGame()
                    dismiss()
                }
                Button("Devam Et", role: .cancel) {
                    showExitConfirmation = false
                }
            } message: {
                Text("Mevcut ilerlemeniz kaybolacak.")
            }
            .onChange(of: viewModel.error != nil) { oldValue, hasError in
                showError = hasError
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                // Save game state when app goes to background
                if viewModel.gameState == .playing {
                    viewModel.saveGameState()
                }
            }
            .onAppear {
                // Restore saved game state if available
                if let savedState = savedGameState {
                    viewModel.restoreGameState(savedState)
                }
            }
    }
    
    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 20) {
                headerView

                Spacer()

                gameContentView

                Spacer()
            }

            // Confetti animation overlay
            ConfettiView(trigger: viewModel.showConfetti)

            // Level-up overlay
            if viewModel.showLevelUp, let newLevel = viewModel.levelUpInfo {
                LevelUpView(newLevel: newLevel) {
                    viewModel.showLevelUp = false
                    viewModel.levelUpInfo = nil
                }
            }
        }
        .enhancedScorePopup(
            score: Binding(
                get: { viewModel.game?.score ?? 0 },
                set: { _ in }
            ),
            comboCount: viewModel.comboCount
        )
        .particleEffect(trigger: $showParticles)
        .onChange(of: viewModel.validationMessage) { oldValue, newValue in
            if newValue.contains("Geçerli") {
                showParticles = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showParticles = false
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                themeManager.colors.letterGameGradientStart.opacity(0.8),
                themeManager.colors.letterGameGradientEnd.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                let settings = PersistenceService.shared.loadSettings()
                EnhancedTimerView(
                    timeRemaining: viewModel.timeRemaining,
                    totalDuration: settings.letterTimerDuration,
                    theme: themeManager.colors
                )
                .accessibilityLabel("Time remaining: \(viewModel.timeRemaining) seconds")

                Spacer()

                if let game = viewModel.game {
                    ScoreView(score: game.score)
                        .accessibilityLabel("Current score: \(game.score) points")
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)

            // Combo counter
            ComboView(comboCount: viewModel.comboCount)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Game Content
    
    @ViewBuilder
    private var gameContentView: some View {
        ZStack {
            if viewModel.gameState == .ready {
                GameReadyView(
                    title: "Oynamaya Hazır mısınız?",
                    subtitle: "\(viewModel.letterCount) harf alacaksınız.\nYapabileceğiniz en uzun kelimeyi oluşturun!",
                    actionTitle: "Oyunu Başlat",
                    color: Color(hex: "#10B981"), // Emerald Green
                    onStart: { viewModel.startNewGame() }
                )
            } else if viewModel.gameState == .finished {
                Color.clear
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showResult = true
                        }
                    }
            } else {
                PlayingView(
                    letters: viewModel.game?.letters ?? [],
                    currentWord: viewModel.currentWord,
                    isTextFieldFocused: $isTextFieldFocused,
                    viewModel: viewModel,
                    theme: themeManager.colors,
                    onWordChange: { word in
                        viewModel.updateWord(word)
                    },
                    onSubmit: {
                        isTextFieldFocused = false
                        Task {
                            await viewModel.submitWord()
                        }
                    },
                    onGiveUp: {
                        showExitConfirmation = true
                    }
                )
            }

            if viewModel.isLoading {
                LoadingOverlay(message: "Kelime doğrulanıyor...")
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                // Logic: Confirm exit if playing, otherwise dismiss immediately
                if viewModel.gameState == .playing {
                    showExitConfirmation = true
                } else {
                    viewModel.resetGame()
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Close game")
        }
        
        ToolbarItem(placement: .principal) {
            Text("Harfler Oyunu")
                .font(.headline)
                .foregroundColor(.white)
        }
        
        // FIX: Ensure the trailing button is always present when playing
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.gameState == .playing {
                Button {
                    showExitConfirmation = true
                } label: {
                    Text("Çık")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Oyundan çık")
            }
        }
    }
    
    // MARK: - Result Sheet
    
    @ViewBuilder
    private var resultSheet: some View {
        if let game = viewModel.game {
            // FIX 2: Argument 'suggestedWords' is correct, no change needed here,
            // the fix was mostly in the ViewModel exposing it correctly.
            LetterResultView(
                game: game,
                message: viewModel.validationMessage,
                suggestedWords: viewModel.suggestedWords,
                onPlayAgain: {
                    showResult = false
                    viewModel.startNewGame()
                },
                onExit: {
                    viewModel.resetGame()
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Playing View

struct PlayingView: View {
    let letters: [Character]
    @State private var usedLetterIndices: [Int] = []
    @State private var shuffleRotation: Double = 0

    let currentWord: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    let viewModel: LetterGameViewModel
    let theme: ThemeColors
    let onWordChange: (String) -> Void
    let onSubmit: () -> Void
    let onGiveUp: () -> Void

    private var usedLetters: [Character] {
        usedLetterIndices.map { letters[$0] }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Letter Pool Visualization
            LetterPoolView(
                letters: letters,
                usedLetters: usedLetters,
                theme: theme
            )
            .padding(.horizontal)

            // Word Length Indicator
            if !currentWord.isEmpty {
                WordLengthIndicator(currentLength: currentWord.count, theme: theme)
                    .transition(.scale.combined(with: .opacity))
            }

            // Available letters
            Text("Mevcut Harfler")
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.primaryButton.opacity(0.6))
                )
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                .accessibilityAddTraits(.isHeader)

            LetterTilesView(
                letters: letters,
                usedIndices: usedLetterIndices,
                theme: theme
            ) { letter, index in
                // Add letter using command pattern
                usedLetterIndices.append(index)
                viewModel.selectLetter(letter)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Available letters: \(letters.map { String($0) }.joined(separator: ", "))")
            
            // Current word input
            VStack(spacing: 12) {
                HStack {
                    Text("Kelimeniz")
                        .font(.headline)
                        .foregroundColor(theme.primaryText.opacity(0.9))
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    if !currentWord.isEmpty {
                        Button {
                            // Clear word using command pattern
                            usedLetterIndices = []
                            viewModel.clearWordWithCommand()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(theme.errorColor)
                        }
                        .accessibilityLabel("Kelimeyi temizle")
                    }
                }
                .padding(.horizontal, 40)

                // Read-only word display
                HStack {
                    Text(currentWord.isEmpty ? "Yukarıdaki harflere dokunun..." : currentWord)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(theme.letterTileBackground.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.primaryText.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)

                // Undo/Redo buttons
                HStack(spacing: 12) {
                    Button {
                        viewModel.performUndo()
                        if !currentWord.isEmpty {
                            usedLetterIndices.removeLast()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Geri Al")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(viewModel.commandHistory.canUndo ? theme.primaryText : theme.primaryText.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewModel.commandHistory.canUndo ? theme.primaryText.opacity(0.15) : theme.primaryText.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.commandHistory.canUndo)
                    .accessibilityLabel("Geri al")

                    Button {
                        let previousLength = currentWord.count
                        viewModel.performRedo()
                        if currentWord.count > previousLength, let lastChar = currentWord.last {
                            // Find the first available index for this letter
                            if let index = letters.firstIndex(where: { $0 == lastChar && !usedLetterIndices.contains(letters.firstIndex(of: $0) ?? -1) }) {
                                usedLetterIndices.append(index)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.uturn.forward")
                            Text("İleri Al")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(viewModel.commandHistory.canRedo ? theme.primaryText : theme.primaryText.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewModel.commandHistory.canRedo ? theme.primaryText.opacity(0.15) : theme.primaryText.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.commandHistory.canRedo)
                    .accessibilityLabel("İleri al")
                }
                .padding(.horizontal, 40)
            }

            // Submit button
            Button(action: onSubmit) {
                Text("Kelimeyi Gönder")
                    .font(.title3.bold())
                    .foregroundColor(theme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(currentWord.isEmpty ? Color.gray : theme.successColor)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }
            .buttonStyle(GrowingButton())
            .disabled(currentWord.isEmpty)
            .padding(.horizontal, 40)

            // Give Up button
            Button(action: onGiveUp) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Pes Et")
                }
                .font(.subheadline.bold())
                .foregroundColor(theme.primaryText.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(theme.errorColor.opacity(0.6))
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 5)
            
            // Reset button to deselect letters
            HStack(spacing: 12) {
                // Deselect All button
                Button(action: {
                    usedLetterIndices = []
                    onWordChange("")
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Tümünü Kaldır")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(theme.primaryText.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 15)
                    .background(theme.primaryText.opacity(0.1))
                    .cornerRadius(10)
                }
                .accessibilityLabel("Seçilen tüm harfleri kaldır")

                // Shuffle Letters button
                Button(action: {
                    // Trigger rotation animation
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        shuffleRotation += 360
                    }
                    viewModel.shuffleLetters()
                    // Also clear selected letters when shuffling
                    usedLetterIndices = []
                    onWordChange("")
                }) {
                    HStack {
                        Image(systemName: "shuffle")
                            .rotationEffect(.degrees(shuffleRotation))
                        Text("Harfleri Karıştır")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(theme.primaryText.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 15)
                    .background(theme.letterGameGradientStart.opacity(0.6))
                    .cornerRadius(10)
                }
                .accessibilityLabel("Harfleri yeni bir düzene göre karıştır")
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Letter Tiles View

struct LetterTilesView: View {
    let letters: [Character]
    let usedIndices: [Int]
    let theme: ThemeColors
    var onLetterTap: ((Character, Int) -> Void)? = nil

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(letters.indices, id: \.self) { index in
                let letter = letters[index]
                let isUsed = usedIndices.contains(index)
                let isRare = LetterFrequencyIndicator.isRareLetter(letter)

                Button {
                    guard !isUsed else { return }
                    onLetterTap?(letter, index)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    VStack(spacing: 2) {
                        Text(String(letter).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(theme.letterTileText)

                        // Rare letter indicator
                        if isRare && !isUsed {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(theme.rareLetterHighlight)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isUsed ? theme.letterTileBackground.opacity(0.3) : theme.letterTileBackground)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isRare && !isUsed ? theme.rareLetterHighlight : theme.letterTileText.opacity(0.3),
                                lineWidth: isRare && !isUsed ? 2 : 1
                            )
                    )
                    .opacity(isUsed ? 0.5 : 1.0)
                }
                .buttonStyle(SpringTileButtonStyle(isSelected: false, theme: theme))
                .disabled(isUsed)
                .accessibilityLabel(String(letter))
                .accessibilityHint(isUsed ? "Letter already used" : "Add letter to word")
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        LetterGameView()
    }
}
