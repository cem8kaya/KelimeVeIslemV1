//
//  NumberGameView.swift
//  KelimeVeIslem
//

import SwiftUI
import UIKit // Needed for Haptics

struct NumberGameView: View {

    let savedGameState: SavedGameState?

    @StateObject private var viewModel = NumberGameViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showResult = false
    @State private var showExitConfirmation = false
    @State private var showParticles = false

    // Track which numbers were used in the current solution, by their index in the 'numbers' array
    @State private var usedNumberIndices: [Int] = []

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
            .sheet(isPresented: $viewModel.showHint) {
                if let solution = viewModel.hintSolution {
                    HintView(operations: solution)
                }
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
                Button("Devam Et", role: .cancel) {}
            } message: {
                Text("Mevcut ilerlemeniz kaybolacak.")
            }
            .onChange(of: viewModel.gameState) { oldValue, newValue in
                if newValue == .playing {
                    usedNumberIndices = []
                }
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

            if viewModel.isLoading {
                LoadingOverlay(message: "Çözüm hesaplanıyor...")
            }

            // Confetti animation overlay
            ConfettiView(trigger: viewModel.showConfetti)
        }
        .enhancedScorePopup(
            score: Binding(
                get: { viewModel.game?.score ?? 0 },
                set: { _ in }
            ),
            comboCount: viewModel.comboCount
        )
        .particleEffect(trigger: $showParticles)
        .onChange(of: viewModel.resultMessage) { oldValue, newValue in
            if newValue.contains("Mükemmel") || newValue.contains("Harika") {
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
                themeManager.colors.numberGameGradientStart.opacity(0.8),
                themeManager.colors.numberGameGradientEnd.opacity(0.8)
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
                    totalDuration: settings.numberTimerDuration,
                    theme: themeManager.colors
                )
                .frame(width: 80, height: 80)

                Spacer()

                if let game = viewModel.game {
                    ScoreView(score: game.score)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Combo counter
            ComboView(comboCount: viewModel.comboCount)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Game Content
    
    private var gameContentView: some View {
        Group {
            if viewModel.gameState == .ready {
                // Using the new shared GameReadyView
                GameReadyView(
                    title: "Sayılara Hazır mısınız?",
                    subtitle: "Hedef sayıya\nverilen sayıları kullanarak ulaşın!",
                    actionTitle: "Oyunu Başlat",
                    color: Color(hex: "#10B981"), // Emerald Green
                    onStart: { viewModel.startNewGame() }
                )
            } else if viewModel.gameState == .finished {
                Color.clear
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showResult = true
                        }
                    }
            } else {
                NumberPlayingView(
                    game: viewModel.game,
                    currentSolution: $viewModel.currentSolution,
                    usedNumberIndices: $usedNumberIndices,
                    theme: themeManager.colors,
                    viewModel: viewModel,
                    onNumberTap: handleNumberTap,
                    onOperatorTap: handleOperatorTap,
                    onDelete: handleDelete,
                    onClear: handleClear,
                    onUndo: handleUndo,
                    onRedo: handleRedo,
                    onSubmit: {
                        viewModel.submitSolution()
                    },
                    onHint: {
                        viewModel.requestHint()
                    },
                    onGiveUp: {
                        showExitConfirmation = true
                    }
                )
            }
        }
    }
    
    // MARK: - Interaction Handlers
    
    private func handleNumberTap(number: Int, index: Int) {
        let currentSolution = viewModel.currentSolution
        let lastChar = currentSolution.last

        // Prevent tapping numbers if the last character was a number or an index is already used
        if lastChar?.isNumber == true {
            AudioService.shared.playErrorHaptic()
            return
        }

        // Use an array of used indices to enforce single use of each starting number
        if !usedNumberIndices.contains(index) {
            viewModel.selectNumber(number)
            usedNumberIndices.append(index)
        } else {
            AudioService.shared.playErrorHaptic()
        }
    }

    private func handleOperatorTap(op: String) {
        let currentSolution = viewModel.currentSolution
        let lastChar = currentSolution.last

        // General rule: operators (+-x÷) must follow a number or closing parenthesis.
        // Parentheses (open) must follow an operator or be the first character.
        // Parentheses (close) must follow a number or another closing parenthesis.

        if "+-*/".contains(op) {
            guard lastChar?.isNumber == true || lastChar == ")" else {
                AudioService.shared.playErrorHaptic()
                return
            }
        } else if op == "(" {
            guard "+-*/".contains(lastChar ?? " ") || currentSolution.isEmpty else {
                AudioService.shared.playErrorHaptic()
                return
            }
        } else if op == ")" {
            guard lastChar?.isNumber == true || lastChar == ")" else {
                AudioService.shared.playErrorHaptic()
                return
            }
        }

        viewModel.selectOperator(op)
    }
    
    private func handleDelete() {
        guard !viewModel.currentSolution.isEmpty else { return }
        
        // Check if the character being deleted is a number
        let lastChar = viewModel.currentSolution.last!
        if lastChar.isNumber {
            // Remove the last added number index from the used set
            _ = usedNumberIndices.popLast()
        }
        
        viewModel.deleteLast()
    }
    
    private func handleClear() {
        usedNumberIndices = []
        viewModel.clearSolutionWithCommand()
    }

    private func handleUndo() {
        guard !viewModel.currentSolution.isEmpty else { return }

        // Check if the last character was a number to update usedNumberIndices
        let lastChar = viewModel.currentSolution.last!
        if lastChar.isNumber {
            _ = usedNumberIndices.popLast()
        }

        viewModel.performUndo()
    }

    private func handleRedo() {
        let previousLength = viewModel.currentSolution.count
        viewModel.performRedo()

        // If a number was added, update usedNumberIndices
        if viewModel.currentSolution.count > previousLength {
            if let lastChar = viewModel.currentSolution.last, lastChar.isNumber {
                // Find the corresponding number and add its index
                if let game = viewModel.game {
                    let numberString = String(lastChar)
                    if let number = Int(numberString) {
                        if let index = game.numbers.firstIndex(where: { $0 == number && !usedNumberIndices.contains(game.numbers.firstIndex(of: $0) ?? -1) }) {
                            usedNumberIndices.append(index)
                        }
                    }
                }
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
        }
        
        ToolbarItem(placement: .principal) {
            Text("Sayılar Oyunu")
                .font(.headline)
                .foregroundColor(.white)
        }
        
        // FIX: Use ToolbarItemGroup to show both Delete and Exit buttons when playing
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if viewModel.gameState == .playing {
                // 1. Delete Button (existing functionality)
                Button(action: handleDelete) {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // 2. Exit Button (New 'Give Up' option)
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
            NumberResultView(
                game: game,
                message: viewModel.resultMessage,
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

// MARK: - Number Playing View (kept for local logic)
struct NumberPlayingView: View {
    let game: NumberGame?
    @Binding var currentSolution: String
    @Binding var usedNumberIndices: [Int]
    let theme: ThemeColors
    let viewModel: NumberGameViewModel

    let onNumberTap: (Int, Int) -> Void
    let onOperatorTap: (String) -> Void
    let onDelete: () -> Void
    let onClear: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onSubmit: () -> Void
    let onHint: () -> Void
    let onGiveUp: () -> Void

    private var currentResult: Int? {
        guard let game = game, !currentSolution.isEmpty else { return nil }
        return try? game.evaluateExpression(currentSolution)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Target number
            if let game = game {
                VStack(spacing: 8) {
                    Text("Hedef")
                        .font(.headline)
                        .foregroundColor(theme.primaryText.opacity(0.9))

                    Text("\(game.targetNumber)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(theme.accentText)
                        .frame(width: 150, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(theme.primaryText.opacity(0.2))
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                        )
                }

                // Proximity Indicator
                NumberProximityIndicator(
                    targetNumber: game.targetNumber,
                    currentResult: currentResult,
                    theme: theme
                )
                
                // Available numbers
                NumberTilesView(
                    numbers: game.numbers,
                    usedIndices: usedNumberIndices,
                    theme: theme,
                    onTap: onNumberTap
                )
                
                // Current solution display
                VStack(spacing: 8) {
                    Text("Çözümünüz")
                        .font(.headline)
                        .foregroundColor(theme.primaryText.opacity(0.9))

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(currentSolution.isEmpty ? "İfadenizi oluşturun..." : currentSolution)
                            .font(.title2.bold())
                            .foregroundColor(theme.primaryText)
                            .padding()
                            .frame(minWidth: 300)
                            .background(theme.numberTileBackground.opacity(0.2))
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)

                    // Show current result if valid
                    if let result = currentResult {
                        Text("= \(result)")
                            .font(.title3.bold())
                            .foregroundColor(result == game.targetNumber ? theme.successColor : theme.secondaryText)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Operators and Actions
                VStack(spacing: 10) {
                    OperatorButtonsView(theme: theme, onOperatorTap: onOperatorTap)

                    // Undo/Redo buttons
                    HStack(spacing: 10) {
                        Button(action: onUndo) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Geri")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(viewModel.commandHistory.canUndo ? theme.primaryText : theme.primaryText.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(viewModel.commandHistory.canUndo ? theme.primaryText.opacity(0.15) : theme.primaryText.opacity(0.05))
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.commandHistory.canUndo)

                        Button(action: onRedo) {
                            HStack {
                                Image(systemName: "arrow.uturn.forward")
                                Text("İleri")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(viewModel.commandHistory.canRedo ? theme.primaryText : theme.primaryText.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(viewModel.commandHistory.canRedo ? theme.primaryText.opacity(0.15) : theme.primaryText.opacity(0.05))
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.commandHistory.canRedo)
                    }
                    .padding(.horizontal, 20)

                    ActionButtonsView(
                        theme: theme,
                        onDelete: onDelete,
                        onClear: onClear,
                        onHint: onHint
                    )
                }
                
                // Submit button
                PrimaryGameButton(
                    title: "Çözümü Gönder",
                    icon: "play.circle.fill",
                    color: currentSolution.isEmpty ? .gray : theme.successColor,
                    action: onSubmit
                )
                .disabled(currentSolution.isEmpty)
                .padding(.horizontal, 20)

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
                .padding(.horizontal, 20)
                .padding(.top, 5)
            }
        }
    }
}

// MARK: - Number Tiles (Refined)

struct NumberTilesView: View {
    let numbers: [Int]
    let usedIndices: [Int]
    let theme: ThemeColors
    let onTap: (Int, Int) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
            ForEach(Array(numbers.enumerated()), id: \.offset) { index, number in
                let isUsed = usedIndices.contains(index)
                let isLarge = number >= 25

                Button(action: { onTap(number, index) }) {
                    VStack(spacing: 4) {
                        Text("\(number)")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(isUsed ? theme.secondaryText.opacity(0.5) : theme.numberTileText)

                        if isLarge && !isUsed {
                            Text("Büyük")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(theme.warningColor)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(isUsed ? theme.numberTileBackground.opacity(0.2) : theme.numberTileBackground)
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isLarge && !isUsed ? theme.warningColor : theme.numberTileText.opacity(0.3),
                                lineWidth: isLarge && !isUsed ? 2 : 1
                            )
                    )
                    .opacity(isUsed ? 0.5 : 1.0)
                }
                .disabled(isUsed)
                .buttonStyle(SpringTileButtonStyle(isSelected: false, theme: theme))
            }
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Operator Buttons (Refined)

struct OperatorButtonsView: View {
    let theme: ThemeColors
    let onOperatorTap: (String) -> Void

    let operators = ["+", "-", "*", "/", "(", ")"]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(operators, id: \.self) { op in
                Button(action: { onOperatorTap(op) }) {
                    Text(op)
                        .font(.title2.bold())
                        .foregroundColor(theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(theme.primaryText.opacity(0.2))
                        .cornerRadius(10)
                }
                .buttonStyle(GrowingButton())
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Action Buttons

struct ActionButtonsView: View {
    let theme: ThemeColors
    let onDelete: () -> Void
    let onClear: () -> Void
    let onHint: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onClear) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Temizle")
                }
                .font(.headline)
                .foregroundColor(theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.errorColor)
                .cornerRadius(10)
            }
            .buttonStyle(GrowingButton())

            Button(action: onHint) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("İpucu")
                }
                .font(.headline)
                .foregroundColor(theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.warningColor)
                .cornerRadius(10)
            }
            .buttonStyle(GrowingButton())
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Hint View (Loading Overlay Added)

struct HintView: View {
    let operations: [Operation]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Çözüm İpucu")
                        .font(.title.bold())
                        .foregroundColor(Color(hex: "#FACC15"))
                        .padding(.top, 20)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(Array(operations.enumerated()), id: \.offset) { index, op in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 30)

                                    Text(op.description)
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(15)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        NumberGameView()
    }
}
