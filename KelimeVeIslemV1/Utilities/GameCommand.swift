//
//  GameCommand.swift
//  KelimeVeIslemV1
//
//  Command pattern for undo/redo functionality
//

import Foundation
import Combine

// MARK: - Command Protocol
protocol GameCommand {
    func execute()
    func undo()
}

// MARK: - Command History Manager
class CommandHistory: ObservableObject {
    @Published private(set) var canUndo: Bool = false
    @Published private(set) var canRedo: Bool = false

    private var undoStack: [GameCommand] = []
    private var redoStack: [GameCommand] = []
    private let maxHistorySize: Int = 10

    func executeCommand(_ command: GameCommand) {
        command.execute()
        undoStack.append(command)

        // Limit history size
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }

        // Clear redo stack when new command is executed
        redoStack.removeAll()

        updateState()
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        updateState()
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        updateState()
    }

    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateState()
    }

    private func updateState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}

// MARK: - Letter Game Commands

/// Adds one letter tile (identified by its index in the pool, so duplicate
/// letters stay distinguishable) to the current word.
class LetterSelectionCommand: GameCommand {
    private let letter: Character
    private let tileIndex: Int
    private weak var viewModel: LetterGameViewModel?

    init(letter: Character, tileIndex: Int, viewModel: LetterGameViewModel) {
        self.letter = letter
        self.tileIndex = tileIndex
        self.viewModel = viewModel
    }

    func execute() {
        viewModel?.addLetterToWord(letter, tileIndex: tileIndex)
    }

    func undo() {
        viewModel?.removeLastLetter()
    }
}

class ClearWordCommand: GameCommand {
    private let previousWord: String
    private let previousIndices: [Int]
    private weak var viewModel: LetterGameViewModel?

    init(previousWord: String, previousIndices: [Int], viewModel: LetterGameViewModel) {
        self.previousWord = previousWord
        self.previousIndices = previousIndices
        self.viewModel = viewModel
    }

    func execute() {
        viewModel?.clearWord()
    }

    func undo() {
        viewModel?.restoreWord(previousWord, tileIndices: previousIndices)
    }
}

// MARK: - Number Game Commands

/// Appends one token (a number tile or an operator) to the solution.
class AppendTokenCommand: GameCommand {
    private let token: SolutionToken
    private weak var viewModel: NumberGameViewModel?

    init(token: SolutionToken, viewModel: NumberGameViewModel) {
        self.token = token
        self.viewModel = viewModel
    }

    func execute() {
        viewModel?.appendToken(token)
    }

    func undo() {
        viewModel?.removeLastToken()
    }
}

class ClearSolutionCommand: GameCommand {
    private let previousTokens: [SolutionToken]
    private weak var viewModel: NumberGameViewModel?

    init(previousTokens: [SolutionToken], viewModel: NumberGameViewModel) {
        self.previousTokens = previousTokens
        self.viewModel = viewModel
    }

    func execute() {
        viewModel?.clearSolution()
    }

    func undo() {
        viewModel?.restoreTokens(previousTokens)
    }
}
