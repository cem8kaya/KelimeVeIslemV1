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
    var useOnlineDictionary: Bool
    var difficultyLevel: DifficultyLevel
    var selectedTheme: String  // Store theme as string for compatibility
    var practiceMode: Bool

    /// False until the player manually changes a timer in Settings. While
    /// false, the level system's time budget applies; once true, the player's
    /// explicit choice always wins.
    var usesCustomTimers: Bool

    // NOTE: Sound on/off lives in AudioService (single source of truth for the
    // audio pipeline); it is intentionally not duplicated here anymore.

    static let `default` = GameSettings(
        language: .turkish,
        letterCount: 9,
        letterTimerDuration: 60,
        numberTimerDuration: 90,
        useOnlineDictionary: false,
        difficultyLevel: .medium,
        selectedTheme: "classic",
        practiceMode: false,
        usesCustomTimers: false
    )

    init(
        language: GameLanguage,
        letterCount: Int,
        letterTimerDuration: Int,
        numberTimerDuration: Int,
        useOnlineDictionary: Bool,
        difficultyLevel: DifficultyLevel,
        selectedTheme: String,
        practiceMode: Bool,
        usesCustomTimers: Bool = false
    ) {
        self.language = language
        self.letterCount = letterCount
        self.letterTimerDuration = letterTimerDuration
        self.numberTimerDuration = numberTimerDuration
        self.useOnlineDictionary = useOnlineDictionary
        self.difficultyLevel = difficultyLevel
        self.selectedTheme = selectedTheme
        self.practiceMode = practiceMode
        self.usesCustomTimers = usesCustomTimers
    }

    // Tolerant decoding: missing keys fall back to defaults so adding fields
    // never wipes previously stored user settings.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = GameSettings.default
        language = try container.decodeIfPresent(GameLanguage.self, forKey: .language) ?? defaults.language
        letterCount = try container.decodeIfPresent(Int.self, forKey: .letterCount) ?? defaults.letterCount
        letterTimerDuration = try container.decodeIfPresent(Int.self, forKey: .letterTimerDuration) ?? defaults.letterTimerDuration
        numberTimerDuration = try container.decodeIfPresent(Int.self, forKey: .numberTimerDuration) ?? defaults.numberTimerDuration
        useOnlineDictionary = try container.decodeIfPresent(Bool.self, forKey: .useOnlineDictionary) ?? defaults.useOnlineDictionary
        difficultyLevel = try container.decodeIfPresent(DifficultyLevel.self, forKey: .difficultyLevel) ?? defaults.difficultyLevel
        selectedTheme = try container.decodeIfPresent(String.self, forKey: .selectedTheme) ?? defaults.selectedTheme
        practiceMode = try container.decodeIfPresent(Bool.self, forKey: .practiceMode) ?? defaults.practiceMode
        // Data saved before this field existed came from a UI where timers
        // were always explicit — preserve that behaviour on migration.
        usesCustomTimers = try container.decodeIfPresent(Bool.self, forKey: .usesCustomTimers)
            ?? (container.contains(.letterTimerDuration) || container.contains(.numberTimerDuration))
    }

    private enum CodingKeys: String, CodingKey {
        case language, letterCount, letterTimerDuration, numberTimerDuration
        case useOnlineDictionary, difficultyLevel, selectedTheme, practiceMode
        case usesCustomTimers
    }

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
