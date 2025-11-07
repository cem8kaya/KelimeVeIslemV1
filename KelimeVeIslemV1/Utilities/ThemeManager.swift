//
//  ThemeManager.swift
//  KelimeVeIslemV1
//
//  Theme management system for the game
//

import SwiftUI

// MARK: - Theme Enum

enum AppTheme: String, Codable, CaseIterable {
    case classic
    case dark
    case ocean
    case sunset

    var displayName: String {
        switch self {
        case .classic:
            return "Klasik"
        case .dark:
            return "Karanlık"
        case .ocean:
            return "Okyanus"
        case .sunset:
            return "Gün Batımı"
        }
    }

    var icon: String {
        switch self {
        case .classic:
            return "paintpalette"
        case .dark:
            return "moon.fill"
        case .ocean:
            return "water.waves"
        case .sunset:
            return "sun.horizon.fill"
        }
    }
}

// MARK: - Theme Color Palette

struct ThemeColors {
    // Background gradients
    let backgroundGradientStart: Color
    let backgroundGradientEnd: Color

    // Letter game colors
    let letterGameGradientStart: Color
    let letterGameGradientEnd: Color
    let letterTileBackground: Color
    let letterTileText: Color
    let letterTileSelected: Color

    // Number game colors
    let numberGameGradientStart: Color
    let numberGameGradientEnd: Color
    let numberTileBackground: Color
    let numberTileText: Color
    let numberTileSelected: Color

    // UI elements
    let primaryButton: Color
    let secondaryButton: Color
    let successColor: Color
    let errorColor: Color
    let warningColor: Color
    let timerNormal: Color
    let timerWarning: Color
    let timerCritical: Color

    // Text colors
    let primaryText: Color
    let secondaryText: Color
    let accentText: Color

    // Achievement & Combo colors
    let achievementBackground: Color
    let comboColor: Color
    let scoreColor: Color

    // Rare letter highlight
    let rareLetterHighlight: Color
}

// MARK: - Theme Manager

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            // Persist theme choice
            if let encoded = try? JSONEncoder().encode(currentTheme) {
                UserDefaults.standard.set(encoded, forKey: "selectedTheme")
            }
        }
    }

    private init() {
        // Load saved theme or use default
        if let data = UserDefaults.standard.data(forKey: "selectedTheme"),
           let theme = try? JSONDecoder().decode(AppTheme.self, from: data) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .classic
        }
    }

    var colors: ThemeColors {
        switch currentTheme {
        case .classic:
            return classicTheme
        case .dark:
            return darkTheme
        case .ocean:
            return oceanTheme
        case .sunset:
            return sunsetTheme
        }
    }

    // MARK: - Classic Theme (Original Colors)

    private var classicTheme: ThemeColors {
        ThemeColors(
            // Background
            backgroundGradientStart: Color(hex: "#6366F1"),
            backgroundGradientEnd: Color(hex: "#A855F7"),

            // Letter game
            letterGameGradientStart: Color(hex: "#8B5CF6"),
            letterGameGradientEnd: Color(hex: "#06B6D4"),
            letterTileBackground: Color.white.opacity(0.95),
            letterTileText: Color(hex: "#8B5CF6"),
            letterTileSelected: Color(hex: "#06B6D4"),

            // Number game
            numberGameGradientStart: Color(hex: "#FB923C"),
            numberGameGradientEnd: Color(hex: "#F472B6"),
            numberTileBackground: Color.white.opacity(0.95),
            numberTileText: Color(hex: "#FB923C"),
            numberTileSelected: Color(hex: "#F472B6"),

            // UI elements
            primaryButton: Color(hex: "#06B6D4"),
            secondaryButton: Color(hex: "#F97316"),
            successColor: Color(hex: "#10B981"),
            errorColor: Color(hex: "#EF4444"),
            warningColor: Color(hex: "#F59E0B"),
            timerNormal: Color.green,
            timerWarning: Color.orange,
            timerCritical: Color.red,

            // Text
            primaryText: Color.white,
            secondaryText: Color.white.opacity(0.8),
            accentText: Color.yellow,

            // Achievement & Combo
            achievementBackground: Color(hex: "#8B5CF6"),
            comboColor: Color.orange,
            scoreColor: Color.yellow,

            // Rare letters
            rareLetterHighlight: Color(hex: "#FACC15")
        )
    }

    // MARK: - Dark Theme

    private var darkTheme: ThemeColors {
        ThemeColors(
            // Background
            backgroundGradientStart: Color(hex: "#1E1B4B"),
            backgroundGradientEnd: Color(hex: "#0F172A"),

            // Letter game
            letterGameGradientStart: Color(hex: "#312E81"),
            letterGameGradientEnd: Color(hex: "#1E293B"),
            letterTileBackground: Color(hex: "#334155").opacity(0.9),
            letterTileText: Color(hex: "#E0E7FF"),
            letterTileSelected: Color(hex: "#818CF8"),

            // Number game
            numberGameGradientStart: Color(hex: "#1E293B"),
            numberGameGradientEnd: Color(hex: "#0F172A"),
            numberTileBackground: Color(hex: "#334155").opacity(0.9),
            numberTileText: Color(hex: "#FED7AA"),
            numberTileSelected: Color(hex: "#FB923C"),

            // UI elements
            primaryButton: Color(hex: "#818CF8"),
            secondaryButton: Color(hex: "#FB923C"),
            successColor: Color(hex: "#34D399"),
            errorColor: Color(hex: "#F87171"),
            warningColor: Color(hex: "#FBBF24"),
            timerNormal: Color(hex: "#34D399"),
            timerWarning: Color(hex: "#FBBF24"),
            timerCritical: Color(hex: "#F87171"),

            // Text
            primaryText: Color(hex: "#F1F5F9"),
            secondaryText: Color(hex: "#CBD5E1"),
            accentText: Color(hex: "#FDE047"),

            // Achievement & Combo
            achievementBackground: Color(hex: "#4C1D95"),
            comboColor: Color(hex: "#FB923C"),
            scoreColor: Color(hex: "#FDE047"),

            // Rare letters
            rareLetterHighlight: Color(hex: "#FDE047")
        )
    }

    // MARK: - Ocean Theme

    private var oceanTheme: ThemeColors {
        ThemeColors(
            // Background
            backgroundGradientStart: Color(hex: "#0EA5E9"),
            backgroundGradientEnd: Color(hex: "#0369A1"),

            // Letter game
            letterGameGradientStart: Color(hex: "#06B6D4"),
            letterGameGradientEnd: Color(hex: "#0284C7"),
            letterTileBackground: Color.white.opacity(0.95),
            letterTileText: Color(hex: "#0284C7"),
            letterTileSelected: Color(hex: "#22D3EE"),

            // Number game
            numberGameGradientStart: Color(hex: "#0284C7"),
            numberGameGradientEnd: Color(hex: "#0369A1"),
            numberTileBackground: Color.white.opacity(0.95),
            numberTileText: Color(hex: "#0369A1"),
            numberTileSelected: Color(hex: "#06B6D4"),

            // UI elements
            primaryButton: Color(hex: "#22D3EE"),
            secondaryButton: Color(hex: "#0EA5E9"),
            successColor: Color(hex: "#10B981"),
            errorColor: Color(hex: "#EF4444"),
            warningColor: Color(hex: "#F59E0B"),
            timerNormal: Color(hex: "#22D3EE"),
            timerWarning: Color(hex: "#F59E0B"),
            timerCritical: Color(hex: "#EF4444"),

            // Text
            primaryText: Color.white,
            secondaryText: Color.white.opacity(0.85),
            accentText: Color(hex: "#FDE047"),

            // Achievement & Combo
            achievementBackground: Color(hex: "#0284C7"),
            comboColor: Color(hex: "#22D3EE"),
            scoreColor: Color(hex: "#FDE047"),

            // Rare letters
            rareLetterHighlight: Color(hex: "#FCD34D")
        )
    }

    // MARK: - Sunset Theme

    private var sunsetTheme: ThemeColors {
        ThemeColors(
            // Background
            backgroundGradientStart: Color(hex: "#FB923C"),
            backgroundGradientEnd: Color(hex: "#DC2626"),

            // Letter game
            letterGameGradientStart: Color(hex: "#F97316"),
            letterGameGradientEnd: Color(hex: "#EC4899"),
            letterTileBackground: Color.white.opacity(0.95),
            letterTileText: Color(hex: "#DC2626"),
            letterTileSelected: Color(hex: "#FB923C"),

            // Number game
            numberGameGradientStart: Color(hex: "#EC4899"),
            numberGameGradientEnd: Color(hex: "#DC2626"),
            numberTileBackground: Color.white.opacity(0.95),
            numberTileText: Color(hex: "#EC4899"),
            numberTileSelected: Color(hex: "#F97316"),

            // UI elements
            primaryButton: Color(hex: "#F97316"),
            secondaryButton: Color(hex: "#EC4899"),
            successColor: Color(hex: "#10B981"),
            errorColor: Color(hex: "#DC2626"),
            warningColor: Color(hex: "#F59E0B"),
            timerNormal: Color(hex: "#FCD34D"),
            timerWarning: Color(hex: "#FB923C"),
            timerCritical: Color(hex: "#DC2626"),

            // Text
            primaryText: Color.white,
            secondaryText: Color.white.opacity(0.9),
            accentText: Color(hex: "#FEF3C7"),

            // Achievement & Combo
            achievementBackground: Color(hex: "#DC2626"),
            comboColor: Color(hex: "#FB923C"),
            scoreColor: Color(hex: "#FEF3C7"),

            // Rare letters
            rareLetterHighlight: Color(hex: "#FDE68A")
        )
    }
}

// MARK: - Environment Key for Theme

struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
