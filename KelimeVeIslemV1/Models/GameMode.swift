//
//  GameMode.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//


import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case letters = "letters"
    case numbers = "numbers"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .letters:
            // Correctly uses the key "game.mode.letters" from Localizable.strings
            return NSLocalizedString("Letters", comment: "Letters game mode")

        case .numbers:
            // Correctly uses the key "game.mode.numbers" from Localizable.strings
            return NSLocalizedString("Numbers", comment: "Numbers game mode")
        }
    }
    
    var icon: String {
        switch self {
        case .letters:
            return "textformat.abc"
        case .numbers:
            return "number"
        }
    }
    
    var description: String {
        switch self {
        case .letters:
            return "Create words from letters"
        case .numbers:
            return "Reach the target number"
        }
    }
}
