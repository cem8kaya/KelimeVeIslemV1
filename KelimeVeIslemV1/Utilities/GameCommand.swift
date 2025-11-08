//
//  GameCommand.swift
//  KelimeVeIslemV1
//
//  Command pattern for undo/redo functionality
//

import Foundation

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
class LetterSelectionCommand: GameCommand {
    private let letter: Character
    private weak var viewModel: LetterGameViewModel?

    init(letter: Character, viewModel: LetterGameViewModel) {
        self.letter = letter
        self.viewModel = viewModel
    }

    func execute() {
        viewModel?.addLetterToWord(letter)
    }

    func undo() {
        viewModel?.removeLastLetter()
    }
}

class ClearWordCommand: GameCommand {
    private let previousWord: String
    private weak var viewModel: LetterGameViewModel?

    init(previousWord: String, viewModel: LetterGameViewModel) {
        self.previousWord = previousWord
        self.viewModel = viewModel
    }

    func execute() {
        viewModel?.clearWord()
    }

    func undo() {
        viewModel?.restoreWord(previousWord)
    }
}

// MARK: - Number Game Commands
class NumberSelectionCommand: GameCommand {
    private let number: Int
    private weak var viewModel: NumberGameViewModel?

    init(number: Int, viewModel: NumberGameViewModel) {
        self.number = number
        self.viewModel = viewModel
    }

    func execute() {
        viewModel?.addNumberToSolution(number)
    }

    func undo() {
        viewModel?.removeLastFromSolution()
    }
}

class OperatorSelectionCommand: GameCommand {
    private let operation: String
    private weak var viewModel: NumberGameViewModel?

    init(operation: String, viewModel: NumberGameViewModel) {
        self.operation = operation
        self.viewModel = viewModel
    }

    func execute() {
        viewModel?.addOperatorToSolution(operation)
    }

    func undo() {
        viewModel?.removeLastFromSolution()
    }
}

class ClearSolutionCommand: GameCommand {
    private let previousSolution: String
    private weak var viewModel: NumberGameViewModel?

    init(previousSolution: String, viewModel: NumberGameViewModel) {
        self.previousSolution = previousSolution
        self.viewModel = viewModel
    }

    func execute() {
        viewModel?.clearSolution()
    }

    func undo() {
        viewModel?.restoreSolution(previousSolution)
    }
}
