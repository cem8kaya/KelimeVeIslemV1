//
//  HomeView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  HomeView.swift
//  KelimeVeIslem
//

import SwiftUI

struct HomeView: View {

    @StateObject private var statisticsViewModel = StatisticsViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedMode: GameMode?
    @State private var showSettings = false
    @State private var showStatistics = false
    @State private var showDailyChallenge = false
    @State private var showAchievements = false
    @State private var savedGameState: SavedGameState?
    @State private var resumeGame = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        themeManager.colors.backgroundGradientStart.opacity(0.9),
                        themeManager.colors.backgroundGradientEnd.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Title
                    VStack(spacing: 5) {
                        Text("1 KELIME")
                            .font(.system(size: 48, weight: .black, design: .serif))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                        
                        Text("& 1 ISLEM")
                            .font(.system(size: 48, weight: .black, design: .serif))
                            .foregroundColor(.yellow)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                    }
                    .padding(.top, 50)

                    // Level Progress
                    LevelProgressView(statistics: statisticsViewModel.statistics)
                        .padding(.horizontal, 40)
                        .padding(.top, 10)

                    // Resume Game button (if saved game exists)
                    if let savedState = savedGameState {
                        ResumeGameButton(
                            gameType: savedState.gameType,
                            theme: themeManager.colors,
                            action: {
                                resumeGame = true
                                selectedMode = savedState.gameType
                            }
                        )
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    }

                    Spacer()

                    // Game mode buttons
                    VStack(spacing: 25) {
                        // Letters Button
                        GameModeButton(
                            mode: .letters,
                            color: themeManager.colors.primaryButton,
                            action: { selectedMode = .letters }
                        )

                        // Numbers Button
                        GameModeButton(
                            mode: .numbers,
                            color: themeManager.colors.secondaryButton,
                            action: { selectedMode = .numbers }
                        )

                        // Daily Challenge Button
                        DailyChallengeButton(
                            theme: themeManager.colors,
                            action: { showDailyChallenge = true }
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Quick stats
                    if statisticsViewModel.hasPlayedGames {
                        QuickStatsView(statistics: statisticsViewModel.statistics)
                            .padding(.horizontal)
                    }
                    
                    // Bottom buttons
                    HStack(spacing: 15) {
                        BottomBarButton(
                            title: "Başarımlar",
                            icon: "trophy.fill",
                            action: { showAchievements = true }
                        )

                        BottomBarButton(
                            title: "İstatistikler",
                            icon: "chart.bar.fill",
                            action: { showStatistics = true }
                        )

                        BottomBarButton(
                            title: "Ayarlar",
                            icon: "gearshape.fill",
                            action: { showSettings = true }
                        )
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showStatistics) {
                StatisticsView()
            }
            .sheet(isPresented: $showDailyChallenge) {
                DailyChallengeView()
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
            .fullScreenCover(item: $selectedMode) { mode in
                GameContainerView(
                    mode: mode,
                    savedGameState: resumeGame ? savedGameState : nil,
                    onDismiss: {
                        // Refresh saved game state when returning from game
                        savedGameState = PersistenceService.shared.loadGameState()
                        resumeGame = false
                        // Refresh statistics to update level display
                        statisticsViewModel.refresh()
                    }
                )
            }
        }
        .onAppear {
            statisticsViewModel.refresh()
            savedGameState = PersistenceService.shared.loadGameState()
        }
    }
}

// MARK: - Game Mode Button (Revised)

struct GameModeButton: View {
    let mode: GameMode
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: mode.icon)
                    .font(.system(size: 30))
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(mode.displayName)
                        .font(.system(size: 24, weight: .heavy))
                    Text(mode.description)
                        .font(.caption)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 25))
            }
            .foregroundColor(.white)
            .padding(25)
            .background(color.opacity(0.8))
            .cornerRadius(25)
            .shadow(color: color.opacity(0.6), radius: 10, x: 0, y: 8)
        }
        .buttonStyle(GrowingButton()) // Use shared button style
    }
}

// MARK: - Quick Stats View (Minor refinement)

struct QuickStatsView: View {
    let statistics: GameStatistics
    
    var body: some View {
        VStack(spacing: 12) {
            Text("İlerlemeniz")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            HStack(spacing: 20) {
                StatItem(
                    title: "Toplam Oyun",
                    value: "\(statistics.totalGamesPlayed)"
                )

                Divider()
                    .background(Color.white.opacity(0.4))
                    .frame(height: 40)

                StatItem(
                    title: "Ort. Skor",
                    value: String(format: "%.0f", statistics.averageScore)
                )

                Divider()
                    .background(Color.white.opacity(0.4))
                    .frame(height: 40)

                StatItem(
                    title: "En İyi Skor",
                    value: "\(max(statistics.bestLetterScore, statistics.bestNumberScore))"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Bottom Bar Button

struct BottomBarButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundColor(.white)
            .padding(15)
            .background(Color.white.opacity(0.2))
            .cornerRadius(15)
        }
        .buttonStyle(GrowingButton())
    }
}

// MARK: - Daily Challenge Button

struct DailyChallengeButton: View {
    let theme: ThemeColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text("Günlük Meydan Okuma")
                            .font(.system(size: 20, weight: .heavy))

                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                            Text("2x")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.2))
                        )
                    }

                    Text("Her gün yeni bir zorluk")
                        .font(.caption)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 25))
            }
            .foregroundColor(theme.primaryText)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [theme.achievementBackground, Color(hex: "#EC4899")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: theme.achievementBackground.opacity(0.6), radius: 10, x: 0, y: 8)
        }
        .buttonStyle(GrowingButton())
    }
}

// MARK: - Resume Game Button

struct ResumeGameButton: View {
    let gameType: GameMode
    let theme: ThemeColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Oyuna Devam Et")
                        .font(.system(size: 20, weight: .heavy))
                    Text(gameType == .letters ? "Harfler Oyunu" : "Sayılar Oyunu")
                        .font(.caption)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 25))
            }
            .foregroundColor(.white)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.green, Color.teal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(0.9)
            )
            .cornerRadius(20)
            .shadow(color: Color.green.opacity(0.6), radius: 10, x: 0, y: 8)
        }
        .buttonStyle(GrowingButton())
    }
}

// MARK: - Game Container View

struct GameContainerView: View {
    let mode: GameMode
    let savedGameState: SavedGameState?
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // Use ZStack or a standard view structure here;
        // the dismiss button is now inside the sub-views' toolbars.
        Group {
            switch mode {
            case .letters:
                LetterGameView(savedGameState: savedGameState)
            case .numbers:
                NumberGameView(savedGameState: savedGameState)
            }
        }
        .onDisappear {
            onDismiss()
        }
        // Removed unnecessary toolbar items here as they should be defined in the game views
    }
}

#Preview {
    HomeView()
}
