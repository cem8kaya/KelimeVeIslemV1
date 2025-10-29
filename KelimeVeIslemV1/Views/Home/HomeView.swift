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
    @State private var selectedMode: GameMode?
    @State private var showSettings = false
    @State private var showStatistics = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#6D28D9").opacity(0.9), Color(hex: "#EC4899").opacity(0.8)], // Deep Violet to Pink
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
                    
                    Spacer()
                    
                    // Game mode buttons
                    VStack(spacing: 25) {
                        // Letters Button
                        GameModeButton(
                            mode: .letters,
                            color: Color(hex: "#06B6D4"), // Cyan
                            action: { selectedMode = .letters }
                        )
                        
                        // Numbers Button
                        GameModeButton(
                            mode: .numbers,
                            color: Color(hex: "#F97316"), // Orange
                            action: { selectedMode = .numbers }
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
                    HStack(spacing: 20) {
                        BottomBarButton(
                            title: "Stats",
                            icon: "chart.bar.fill",
                            action: { showStatistics = true }
                        )
                        
                        BottomBarButton(
                            title: "Settings",
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
            .fullScreenCover(item: $selectedMode) { mode in
                GameContainerView(mode: mode)
            }
        }
        .onAppear {
            statisticsViewModel.refresh()
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
            Text("Your Progress")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Total Games",
                    value: "\(statistics.totalGamesPlayed)"
                )
                
                Divider()
                    .background(Color.white.opacity(0.4))
                    .frame(height: 40)
                
                StatItem(
                    title: "Avg Score",
                    value: String(format: "%.0f", statistics.averageScore)
                )
                
                Divider()
                    .background(Color.white.opacity(0.4))
                    .frame(height: 40)
                
                StatItem(
                    title: "Best Score",
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

// MARK: - Game Container View

struct GameContainerView: View {
    let mode: GameMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Use ZStack or a standard view structure here;
        // the dismiss button is now inside the sub-views' toolbars.
        Group {
            switch mode {
            case .letters:
                LetterGameView()
            case .numbers:
                NumberGameView()
            }
        }
        // Removed unnecessary toolbar items here as they should be defined in the game views
    }
}

#Preview {
    HomeView()
}
