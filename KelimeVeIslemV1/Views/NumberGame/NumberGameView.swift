//
//  NumberGameView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  NumberGameView.swift
//  KelimeVeIslem
//

import SwiftUI
import UIKit // Needed for Haptics

struct NumberGameView: View {
    
    @StateObject private var viewModel = NumberGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showResult = false
    @State private var showExitConfirmation = false
    
    // Track which numbers were used in the current solution, by their index in the 'numbers' array
    @State private var usedNumberIndices: [Int] = []
    
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
                "Exit Game?",
                isPresented: $showExitConfirmation,
                titleVisibility: .visible
            ) {
                Button("Exit Game", role: .destructive) {
                    viewModel.resetGame()
                    dismiss()
                }
                Button("Resume", role: .cancel) {}
            } message: {
                Text("Your current progress will be lost.")
            }
            .onChange(of: viewModel.gameState) { newState in
                if newState == .playing {
                    usedNumberIndices = []
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
                LoadingOverlay(message: "Calculating solution...")
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: "#F97316").opacity(0.8), Color(hex: "#EC4899").opacity(0.8)], // Orange to Pink
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            // Use the centralized TimerView
            TimerView(timeRemaining: viewModel.timeRemaining, mode: .numbers)
                .frame(width: 80, height: 80)
            
            Spacer()
            
            if let game = viewModel.game {
                // Use the centralized ScoreView
                ScoreView(score: game.score)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Game Content
    
    private var gameContentView: some View {
        Group {
            if viewModel.gameState == .ready {
                // Using the new shared GameReadyView
                GameReadyView(
                    title: "Ready for Numbers?",
                    subtitle: "Reach the target number\nusing the given numbers!",
                    actionTitle: "Start Game",
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
                    onNumberTap: handleNumberTap,
                    onOperatorTap: handleOperatorTap,
                    onDelete: handleDelete,
                    onClear: handleClear,
                    onSubmit: {
                        viewModel.submitSolution()
                    },
                    onHint: {
                        viewModel.requestHint()
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
            viewModel.addToSolution("\(number)")
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
        
        if "+−×÷".contains(op) {
            guard lastChar?.isNumber == true || lastChar == ")" else {
                AudioService.shared.playErrorHaptic()
                return
            }
        } else if op == "(" {
            guard "+−×÷".contains(lastChar ?? " ") || currentSolution.isEmpty else {
                AudioService.shared.playErrorHaptic()
                return
            }
        } else if op == ")" {
            guard lastChar?.isNumber == true || lastChar == ")" else {
                AudioService.shared.playErrorHaptic()
                return
            }
        }
        
        viewModel.addToSolution(op)
    }
    
    private func handleDelete() {
        guard !viewModel.currentSolution.isEmpty else { return }
        
        // Check if the character being deleted is a number
        let lastChar = viewModel.currentSolution.last!
        if lastChar.isNumber {
            // Find the last added number index and remove it from the used set
            if let lastIndex = usedNumberIndices.popLast() {
                // If this logic fails (e.g., if the user manually typed), we might need a more robust check.
                // For now, rely on tap interaction.
            }
        }
        
        viewModel.deleteLast()
    }
    
    private func handleClear() {
        usedNumberIndices = []
        viewModel.clearSolution()
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
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
            Text("Numbers Game")
                .font(.headline)
                .foregroundColor(.white)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.gameState == .playing {
                Button(action: handleDelete) {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
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
    
    let onNumberTap: (Int, Int) -> Void
    let onOperatorTap: (String) -> Void
    let onDelete: () -> Void
    let onClear: () -> Void
    let onSubmit: () -> Void
    let onHint: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            // Target number
            if let game = game {
                VStack(spacing: 8) {
                    Text("Target")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("\(game.targetNumber)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#FACC15")) // Amber Yellow
                        .frame(width: 150, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.2))
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                        )
                }
                
                // Available numbers
                NumberTilesView(
                    numbers: game.numbers,
                    usedIndices: usedNumberIndices,
                    onTap: onNumberTap
                )
                
                // Current solution display
                VStack(spacing: 8) {
                    Text("Your Solution")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(currentSolution.isEmpty ? "Build your expression..." : currentSolution)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding()
                            .frame(minWidth: 300)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                }
                
                // Operators and Actions
                VStack(spacing: 10) {
                    OperatorButtonsView(onOperatorTap: onOperatorTap)
                    
                    ActionButtonsView(
                        onDelete: onDelete,
                        onClear: onClear,
                        onHint: onHint
                    )
                }
                
                // Submit button
                PrimaryGameButton(
                    title: "Submit Solution",
                    icon: "play.circle.fill",
                    color: currentSolution.isEmpty ? .gray : Color(hex: "#22C55E"), // Lime Green
                    action: onSubmit
                )
                .disabled(currentSolution.isEmpty)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Number Tiles (Refined)

struct NumberTilesView: View {
    let numbers: [Int]
    let usedIndices: [Int]
    let onTap: (Int, Int) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
            ForEach(Array(numbers.enumerated()), id: \.offset) { index, number in
                Button(action: { onTap(number, index) }) {
                    Text("\(number)")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(usedIndices.contains(index) ? .gray : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(usedIndices.contains(index) ? Color.white.opacity(0.1) : Color.white.opacity(0.3))
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(usedIndices.contains(index) ? Color.white.opacity(0.2) : Color.white.opacity(0.7), lineWidth: usedIndices.contains(index) ? 0 : 1.5)
                        )
                }
                .disabled(usedIndices.contains(index))
                .buttonStyle(GrowingButton())
            }
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Operator Buttons (Refined)

struct OperatorButtonsView: View {
    let onOperatorTap: (String) -> Void
    
    let operators = ["+", "−", "×", "÷", "(", ")"]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(operators, id: \.self) { op in
                Button(action: { onOperatorTap(op) }) {
                    Text(op)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.2))
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
    let onDelete: () -> Void
    let onClear: () -> Void
    let onHint: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: onClear) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Clear")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#EF4444")) // Red
                .cornerRadius(10)
            }
            .buttonStyle(GrowingButton())
            
            Button(action: onHint) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("Hint")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#FBBF24")) // Yellow
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
                    Text("Solution Hint")
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
                    Button("Close") {
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
