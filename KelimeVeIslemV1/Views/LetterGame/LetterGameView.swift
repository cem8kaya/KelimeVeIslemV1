//
//  LetterGameView.swift
//  KelimeVeIslem
//

import SwiftUI

struct LetterGameView: View {
    
    @StateObject private var viewModel = LetterGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showResult = false
    @State private var showError = false
    @State private var showExitConfirmation = false
    @FocusState private var isTextFieldFocused: Bool
    
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
            .alert("Error", isPresented: $showError, presenting: viewModel.error) { error in
                Button("OK") {
                    showError = false
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .confirmationDialog(
                "Exit Game?",
                isPresented: $showExitConfirmation,
                titleVisibility: .visible
            ) {
                Button("Exit Game", role: .destructive) {
                    viewModel.resetGame()
                    dismiss()
                }
                Button("Resume", role: .cancel) {
                    showExitConfirmation = false
                }
            } message: {
                Text("Your current progress will be lost.")
            }
            .onChange(of: viewModel.error != nil) { hasError in
                showError = hasError
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
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: "#2563EB").opacity(0.8), Color(hex: "#06B6D4").opacity(0.8)], // Blue to Cyan
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            // FIX 1: Add missing 'mode' argument
            TimerView(timeRemaining: viewModel.timeRemaining, mode: .letters)
                .accessibilityLabel("Time remaining: \(viewModel.timeRemaining) seconds")
            
            Spacer()
            
            if let game = viewModel.game {
                ScoreView(score: game.score)
                    .accessibilityLabel("Current score: \(game.score) points")
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Game Content
    
    @ViewBuilder
    private var gameContentView: some View {
        ZStack {
            Group {
                if viewModel.gameState == .ready {
                    GameReadyView(
                        title: "Ready to play?",
                        subtitle: "You'll get \(viewModel.letterCount) letters.\nMake the longest word you can!",
                        actionTitle: "Start Game",
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
                        onWordChange: { word in
                            viewModel.updateWord(word)
                        },
                        onSubmit: {
                            isTextFieldFocused = false
                            Task {
                                await viewModel.submitWord()
                            }
                        }
                    )
                }
            }
            
            if viewModel.isLoading {
                LoadingOverlay(message: "Validating Word...")
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
            Text("Letters Game")
                .font(.headline)
                .foregroundColor(.white)
        }
        
        // FIX: Ensure the trailing button is always present when playing
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.gameState == .playing {
                Button {
                    showExitConfirmation = true
                } label: {
                    Text("Exit") // You should localize this string
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Exit game")
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
    
    let currentWord: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    let onWordChange: (String) -> Void
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Available letters
            Text("Available Letters")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .accessibilityAddTraits(.isHeader)
            
            LetterTilesView(
                letters: letters,
                usedIndices: usedLetterIndices
            ) { letter, index in
                // Add letter and update state
                usedLetterIndices.append(index)
                let newWord = currentWord + String(letter)
                onWordChange(newWord)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Available letters: \(letters.map { String($0) }.joined(separator: ", "))")
            
            // Current word input
            VStack(spacing: 12) {
                HStack {
                    Text("Your Word")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    if !currentWord.isEmpty {
                        Button {
                            // Clear word
                            usedLetterIndices = []
                            onWordChange("")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#F87171")) // Red
                        }
                        .accessibilityLabel("Clear word")
                    }
                }
                .padding(.horizontal, 40)
                
                // Read-only word display
                HStack {
                    Text(currentWord.isEmpty ? "Tap letters above..." : currentWord)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)
            }
            
            // Submit button
            Button(action: onSubmit) {
                Text("Submit Word")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(currentWord.isEmpty ? Color(hex: "#6B7280") : Color(hex: "#10B981"))
                    .cornerRadius(12)
                    .buttonStyle(GrowingButton())
                    .shadow(radius: 5)
            }
            .disabled(currentWord.isEmpty)
            .padding(.horizontal, 40)
            
            // Reset button to deselect letters
            Button(action: {
                usedLetterIndices = []
                onWordChange("")
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                Text("Deselect All")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
            }
            .accessibilityLabel("Deselect all chosen letters")
        }
    }
}

// MARK: - Letter Tiles View

struct LetterTilesView: View {
    let letters: [Character]
    let usedIndices: [Int]
    var onLetterTap: ((Character, Int) -> Void)? = nil
    
    var body: some View {
        // FIX 4: Simplified the LazyVGrid to help the compiler with type-checking.
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                let isUsed = usedIndices.contains(index)
                
                Button {
                    // Only allow tapping if the letter hasn't been used
                    guard !isUsed else { return }
                    onLetterTap?(letter, index)
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    Text(String(letter))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isUsed ? Color.white.opacity(0.1) : Color.white.opacity(0.3))
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(isUsed ? 0.1 : 0.5), lineWidth: 1)
                        )
                        .opacity(isUsed ? 0.6 : 1.0)
                }
                .buttonStyle(LetterTileButtonStyle())
                .disabled(isUsed) // Disable the button visually and functionally
                .accessibilityLabel(String(letter))
                .accessibilityHint(isUsed ? "Letter already used" : "Add letter to word")
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Local Button Styles

// FIX 3: Define the missing ButtonStyle locally to resolve the "Cannot find" error.
struct LetterTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
