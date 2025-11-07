//
//  StatisticsView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  StatisticsView.swift
//  KelimeVeIslem
//

import SwiftUI

struct StatisticsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var showClearAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Overall Statistics
                        OverallStatsCard(statistics: viewModel.statistics)
                        
                        // Best Scores
                        VStack(spacing: 20) {
                            ScoreCard(
                                title: "En İyi Harf Skoru",
                                score: viewModel.statistics.bestLetterScore,
                                icon: "textformat.abc"
                            )

                            ScoreCard(
                                title: "En İyi Sayı Skoru",
                                score: viewModel.statistics.bestNumberScore,
                                icon: "number"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Achievements
                        AchievementsCard(statistics: viewModel.statistics)
                        
                        // Recent Results
                        if !viewModel.recentResults.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Son Oyunlar")
                                    .font(.title2.bold())
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.recentResults.prefix(10)) { result in
                                    ResultRow(result: result, viewModel: viewModel)
                                }
                            }
                            .padding(.vertical)
                        }
                        
                        // Clear data button
                        Button(role: .destructive) {
                            showClearAlert = true
                        } label: {
                            Text("Tüm İstatistikleri Temizle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("İstatistikler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
            .alert("İstatistikler Temizlensin mi?", isPresented: $showClearAlert) {
                Button("İptal", role: .cancel) {}
                Button("Temizle", role: .destructive) {
                    viewModel.clearAllResults()
                }
            } message: {
                Text("Bu işlem tüm oyun geçmişinizi ve istatistiklerinizi kalıcı olarak silecektir.")
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

// MARK: - Overall Stats Card

struct OverallStatsCard: View {
    let statistics: GameStatistics
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Genel İstatistikler")
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                StatBox(title: "Oynanan Oyun", value: "\(statistics.totalGamesPlayed)", icon: "gamecontroller.fill")
                StatBox(title: "Toplam Skor", value: "\(statistics.totalScore)", icon: "star.fill")
                StatBox(title: "Ortalama Skor", value: String(format: "%.1f", statistics.averageScore), icon: "chart.bar.fill")
                StatBox(title: "Tam İsabet", value: "\(statistics.perfectNumberMatches)", icon: "target")
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
    }
}

// MARK: - Score Card

struct ScoreCard: View {
    let title: String
    let score: Int
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.yellow)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text("\(score) puan")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
    }
}

// MARK: - Achievements Card

struct AchievementsCard: View {
    let statistics: GameStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Başarımlar")
                .font(.title2.bold())

            AchievementRow(
                title: "Kelime Ustası",
                description: "\(statistics.letterGamesPlayed) harf oyunu oynandı",
                icon: "text.book.closed.fill",
                isUnlocked: statistics.letterGamesPlayed >= 10
            )

            AchievementRow(
                title: "Sayı Sihirbazı",
                description: "\(statistics.numberGamesPlayed) sayı oyunu oynandı",
                icon: "number.circle.fill",
                isUnlocked: statistics.numberGamesPlayed >= 10
            )

            AchievementRow(
                title: "Mükemmel Hassasiyet",
                description: "\(statistics.perfectNumberMatches) tam isabet",
                icon: "target",
                isUnlocked: statistics.perfectNumberMatches >= 5
            )

            if !statistics.longestWord.isEmpty {
                AchievementRow(
                    title: "En Uzun Kelime",
                    description: statistics.longestWord,
                    icon: "text.alignleft",
                    isUnlocked: true
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct AchievementRow: View {
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? .yellow : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Result Row

struct ResultRow: View {
    let result: GameResult
    let viewModel: StatisticsViewModel
    
    var body: some View {
        HStack {
            Image(systemName: result.mode.icon)
                .font(.title3)
                .foregroundColor(result.mode == .letters ? .blue : .purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.formatResult(result))
                    .font(.subheadline.bold())
                
                Text(viewModel.formatDate(result.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    StatisticsView()
}
