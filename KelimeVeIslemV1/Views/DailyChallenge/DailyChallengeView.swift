//
//  DailyChallengeView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/7/25.
//


import SwiftUI

struct DailyChallengeView: View {
    @StateObject private var viewModel = DailyChallengeViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showLeaderboard = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#8B5CF6").opacity(0.9), Color(hex: "#EC4899").opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)

                            Text("GÜNLÜK MEYDAN OKUMA")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.white)
                        }

                        Text(formattedDate())
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)

                    // Challenge Info Card
                    VStack(spacing: 20) {
                        // Challenge Type
                        HStack {
                            Image(systemName: viewModel.todayChallenge.mode.icon)
                                .font(.title)

                            Text(viewModel.todayChallenge.mode.displayName)
                                .font(.title2.bold())

                            Spacer()

                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundColor(.orange)

                            Text("2x PUAN")
                                .font(.headline.bold())
                                .foregroundColor(.orange)
                        }
                        .foregroundColor(.white)

                        Divider()
                            .background(Color.white.opacity(0.3))

                        // Stats
                        HStack(spacing: 20) {
                            DailyChallengeStatItem(
                                icon: "checkmark.circle.fill",
                                title: "Tamamlanan",
                                value: "\(viewModel.stats.totalChallengesCompleted)"
                            )

                            Divider()
                                .background(Color.white.opacity(0.3))
                                .frame(height: 40)

                            DailyChallengeStatItem(
                                icon: "bolt.fill",
                                title: "Seri",
                                value: "\(viewModel.stats.currentStreak)"
                            )

                            Divider()
                                .background(Color.white.opacity(0.3))
                                .frame(height: 40)

                            DailyChallengeStatItem(
                                icon: "star.fill",
                                title: "En İyi",
                                value: "\(viewModel.stats.bestScore)"
                            )
                        }
                    }
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal)

                    Spacer()

                    // Challenge Status
                    if viewModel.isTodayChallengeCompleted {
                        CompletedChallengeView(
                            result: viewModel.todayResult!,
                            stats: viewModel.stats
                        )
                    } else {
                        // Start Challenge Button
                        PrimaryGameButton(
                            title: "Günlük Meydan Okumayı Başlat",
                            icon: "play.fill",
                            color: Color(hex: "#10B981"),
                            action: {
                                viewModel.startChallenge()
                            }
                        )
                        .padding(.horizontal, 40)
                    }

                    // Leaderboard Button
                    Button(action: { showLeaderboard = true }) {
                        HStack {
                            Image(systemName: "list.number")
                                .font(.title3)
                            Text("Lider Tablosu")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(15)
                    }
                    .buttonStyle(GrowingButton())
                    .padding(.horizontal, 40)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            })
            .sheet(isPresented: $showLeaderboard) {
                LeaderboardView(results: viewModel.leaderboard, stats: viewModel.stats)
            }
            .fullScreenCover(isPresented: $viewModel.showChallengeGame) {
                DailyChallengeGameView(
                    challenge: viewModel.todayChallenge,
                    onComplete: { result in
                        viewModel.completeChallenge(with: result)
                    }
                )
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter.string(from: Date())
    }
}

// MARK: - Daily Challenge Stat Item

struct DailyChallengeStatItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)

            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Completed Challenge View

struct CompletedChallengeView: View {
    let result: DailyChallengeResult
    let stats: DailyChallengeStats

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Tebrikler!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Bugünün meydan okumısını tamamladınız")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            VStack(spacing: 15) {
                HStack {
                    Text("Skorunuz:")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(result.score)")
                            .font(.title2.bold())
                            .foregroundColor(.yellow)
                    }
                }

                HStack {
                    Text("Süreniz:")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text("\(result.duration)s")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }

                if stats.currentStreak > 1 {
                    HStack {
                        Text("Mevcut Seri:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.orange)
                            Text("\(stats.currentStreak) gün")
                                .font(.title3.bold())
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.2))
            )
            .padding(.horizontal, 40)

            Text("Yarın yeni bir meydan okuma için geri gelin!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Leaderboard View

struct LeaderboardView: View {
    let results: [DailyChallengeResult]
    let stats: DailyChallengeStats
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#1E3A8A").opacity(0.9), Color(hex: "#6366F1").opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Stats Summary
                    VStack(spacing: 15) {
                        HStack(spacing: 30) {
                            LeaderboardStatCard(
                                icon: "trophy.fill",
                                title: "En Uzun Seri",
                                value: "\(stats.longestStreak)",
                                color: .orange
                            )

                            LeaderboardStatCard(
                                icon: "star.fill",
                                title: "En İyi Skor",
                                value: "\(stats.bestScore)",
                                color: .yellow
                            )
                        }

                        LeaderboardStatCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Ortalama Skor",
                            value: String(format: "%.0f", stats.averageScore),
                            color: .cyan
                        )
                    }
                    .padding(.horizontal)

                    // Results List
                    if results.isEmpty {
                        Spacer()

                        VStack(spacing: 15) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))

                            Text("Henüz sonuç yok")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))

                            Text("İlk günlük meydan okumayı tamamlayın")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()
                    } else {
                        List {
                            ForEach(results.indices, id: \.self) { index in
                                let result = results[index]
                                LeaderboardRow(rank: index + 1, result: result)
                                    .listRowBackground(Color.white.opacity(0.1))
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
                .padding(.top, 20)
            }
            .navigationTitle("Lider Tablosu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            })
        }
    }
}

// MARK: - Leaderboard Stat Card

struct LeaderboardStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title.bold())
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.2))
        )
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let rank: Int
    let result: DailyChallengeResult

    var body: some View {
        HStack(spacing: 15) {
            // Rank
            Text("#\(rank)")
                .font(.title3.bold())
                .foregroundColor(rankColor)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 5) {
                Text(result.playerName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(formattedDate(result.challengeDate))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(result.score)")
                        .font(.headline.bold())
                        .foregroundColor(.yellow)
                }

                Text("\(result.duration)s")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(hex: "#C0C0C0") // Silver
        case 3: return Color(hex: "#CD7F32") // Bronze
        default: return .white
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    DailyChallengeView()
}
