//
//  ErrorHandling.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  ErrorHandling.swift
//  KelimeVeIslem
//

import Foundation
import Combine
import Combine

// MARK: - App Errors

enum AppError: LocalizedError {
    case dictionaryLoadFailed
    case wordValidationFailed
    case expressionEvaluationFailed
    case timerCreationFailed
    case audioPlaybackFailed
    case persistenceError(String)
    case networkError(String)
    case invalidInput(String)
    
    var errorDescription: String? {
        switch self {
        case .dictionaryLoadFailed:
            return NSLocalizedString("error.dictionary_load",
                comment: "Failed to load dictionary")
        case .wordValidationFailed:
            return NSLocalizedString("error.word_validation",
                comment: "Failed to validate word")
        case .expressionEvaluationFailed:
            return NSLocalizedString("error.expression_eval",
                comment: "Failed to evaluate expression")
        case .timerCreationFailed:
            return NSLocalizedString("error.timer_creation",
                comment: "Failed to create timer")
        case .audioPlaybackFailed:
            return NSLocalizedString("error.audio_playback",
                comment: "Failed to play audio")
        case .persistenceError(let message):
            return "Persistence error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        }
    }
}

// MARK: - Error Handler

@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showError: Bool = false
    
    func handle(_ error: Error, retryAction: (() -> Void)? = nil) {
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = .networkError(error.localizedDescription)
        }
        showError = true
        
        // Log error for debugging
        print("❌ Error: \(error.localizedDescription)")
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
}

// MARK: - Result Extensions

extension Result {
    var value: Success? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
    
    var error: Failure? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}
