//
//  LevelProgressView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/10/25.
//

import SwiftUI

// MARK: - Level Progress View

struct LevelProgressView: View {
    let statistics: GameStatistics
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 15) {
            // Level Header
            HStack {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.colors.primaryButton,
                                    themeManager.colors.secondaryButton
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: themeManager.colors.primaryButton.opacity(0.4), radius: 8, x: 0, y: 4)

                    VStack(spacing: 2) {
                        Text("LVL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))

                        Text("\(statistics.currentLevel)")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Level title
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("Seviye \(statistics.currentLevel)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        if statistics.currentLevel < Level.allLevels.count {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))

                            Text("\(statistics.currentLevel + 1)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }

                    // XP Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 12)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#10B981"),
                                            Color(hex: "#34D399")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: max(20, CGFloat(statistics.progressToNextLevel) * 200),
                                    height: 12
                                )
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: statistics.progressToNextLevel)
                        }
                        .frame(width: 200)

                        // XP Text
                        if statistics.currentLevel < Level.allLevels.count {
                            Text("\(statistics.totalXP) / \(statistics.level.xpRequired + statistics.xpForNextLevel) XP")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Max Seviye!")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        themeManager.colors.primaryButton.opacity(0.5),
                                        themeManager.colors.secondaryButton.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
        }
    }
}

// MARK: - Compact Level Badge (for smaller spaces)

struct CompactLevelBadge: View {
    let level: Int
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.colors.primaryButton,
                            themeManager.colors.secondaryButton
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .shadow(color: themeManager.colors.primaryButton.opacity(0.4), radius: 4, x: 0, y: 2)

            VStack(spacing: 0) {
                Text("LVL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))

                Text("\(level)")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Level Rewards Preview

struct LevelRewardsView: View {
    let level: Level
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        if !level.rewards.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Seviye \(level.levelNumber) Ödülleri")
                    .font(.headline)
                    .foregroundColor(.white)

                ForEach(level.rewards.indices, id: \.self) { index in
                    HStack(spacing: 10) {
                        Image(systemName: level.rewards[index].iconName)
                            .foregroundColor(.yellow)
                            .frame(width: 24)

                        Text(level.rewards[index].displayName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - XP Gain Animation (for after game)

struct XPGainView: View {
    let xpGained: Int
    let currentCombo: Int
    @State private var animateIn = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("+\(xpGained) XP")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                if currentCombo > 1 {
                    Text("Kombo x\(currentCombo)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#F59E0B"),
                            Color(hex: "#EAB308")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.yellow.opacity(0.6), radius: 10, x: 0, y: 4)
        )
        .scaleEffect(animateIn ? 1.0 : 0.5)
        .opacity(animateIn ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Helper for Hex Colors

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            LevelProgressView(statistics: GameStatistics(
                totalGamesPlayed: 25,
                totalScore: 2500,
                totalXP: 850,
                currentLevel: 5
            ))
            .padding()

            XPGainView(xpGained: 125, currentCombo: 3)
        }
    }
}
