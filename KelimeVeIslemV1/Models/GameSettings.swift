//
//  GameSettings.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//


import Foundation

struct GameSettings: Codable {
    var language: GameLanguage
    var letterCount: Int
    var letterTimerDuration: Int
    var numberTimerDuration: Int
    var soundEnabled: Bool
    var useOnlineDictionary: Bool
    var difficultyLevel: DifficultyLevel
    var selectedTheme: String  // Store theme as string for compatibility

    static let `default` = GameSettings(
        language: .turkish,
        letterCount: 9,
        letterTimerDuration: 60,
        numberTimerDuration: 90,
        soundEnabled: true,
        useOnlineDictionary: false,
        difficultyLevel: .medium,
        selectedTheme: "classic"
    )
    
    enum DifficultyLevel: String, Codable, CaseIterable {
        case easy
        case medium
        case hard
        
        var displayName: String {
            switch self {
            case .easy:
                return "Kolay"
            case .medium:
                return "Orta"
            case .hard:
                return "Zor"
            }
        }
        
        var numberConfig: (small: Int, large: Int) {
            switch self {
            case .easy:
                return (small: 5, large: 1)
            case .medium:
                return (small: 4, large: 2)
            case .hard:
                return (small: 3, large: 3)
            }
        }
        
        var description: String {
            switch self {
            case .easy:
                return "5 küçük + 1 büyük sayı"
            case .medium:
                return "4 küçük + 2 büyük sayı"
            case .hard:
                return "3 küçük + 3 büyük sayı"
            }
        }
    }
    
    func validate() -> Bool {
        return letterCount >= 6 && letterCount <= 12 &&
               letterTimerDuration >= 30 && letterTimerDuration <= 120 &&
               numberTimerDuration >= 60 && numberTimerDuration <= 180
    }
}
