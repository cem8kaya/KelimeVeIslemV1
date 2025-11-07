//
//  AchievementsView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/7/25.
//


import SwiftUI
import Combine

struct AchievementsView: View {
    @StateObject private var viewModel = AchievementsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: Achievement.AchievementCategory?

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#1E3A8A").opacity(0.9), Color(hex: "#3B82F6").opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Stats Header
                    AchievementStatsHeader(progress: viewModel.progress)
                        .padding(.horizontal)

                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryButton(
                                title: "Tümü",
                                icon: "square.grid.2x2.fill",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )

                            ForEach(Achievement.AchievementCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    title: category.displayName,
                                    icon: category.iconName,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Achievement List
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredAchievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Başarımlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private var filteredAchievements: [Achievement] {
        let allAchievements = Array(viewModel.progress.achievements.values)

        if let category = selectedCategory {
            return allAchievements
                .filter { $0.category == category }
                .sorted { achievement1, achievement2 in
                    if achievement1.isUnlocked != achievement2.isUnlocked {
                        return achievement1.isUnlocked
                    }
                    return achievement1.progressPercentage > achievement2.progressPercentage
                }
        } else {
            return allAchievements.sorted { achievement1, achievement2 in
                if achievement1.isUnlocked != achievement2.isUnlocked {
                    return achievement1.isUnlocked
                }
                return achievement1.progressPercentage > achievement2.progressPercentage
            }
        }
    }
}

// MARK: - Achievement Stats Header

struct AchievementStatsHeader: View {
    let progress: AchievementProgress

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundColor(.yellow)

                Text("Başarımlar")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Spacer()

                Text("\(progress.totalUnlocked)/\(progress.achievements.count)")
                    .font(.title2.bold())
                    .foregroundColor(.yellow)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 20)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 20)
                        .animation(.easeInOut, value: progressPercentage)
                }
            }
            .frame(height: 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
        )
    }

    private var progressPercentage: Double {
        guard progress.achievements.count > 0 else { return 0 }
        return Double(progress.totalUnlocked) / Double(progress.achievements.count)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.caption.bold())
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
            )
        }
        .buttonStyle(GrowingButton())
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked ?
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(achievement.title)
                    .font(.headline.bold())
                    .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.7))

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)

                if !achievement.isUnlocked {
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.cyan)
                                .frame(width: geometry.size.width * achievement.progressPercentage, height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text("\(achievement.progress)/\(achievement.targetValue)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                } else if let unlockedAt = achievement.unlockedAt {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text("Kazanıldı: \(formattedDate(unlockedAt))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    achievement.isUnlocked ?
                    Color.white.opacity(0.15) :
                    Color.white.opacity(0.08)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    achievement.isUnlocked ?
                    Color.yellow.opacity(0.5) :
                    Color.white.opacity(0.2),
                    lineWidth: achievement.isUnlocked ? 2 : 1
                )
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Achievements ViewModel

@MainActor
class AchievementsViewModel: ObservableObject {
    @Published var progress: AchievementProgress

    private let achievementTracker = AchievementTracker.shared

    init() {
        self.progress = achievementTracker.getProgress()
    }

    func refresh() {
        progress = achievementTracker.getProgress()
    }
}

// MARK: - Achievement Category Extension

extension Achievement.AchievementCategory: CaseIterable {
    static var allCases: [Achievement.AchievementCategory] {
        return [.general, .letters, .numbers, .speed, .combo, .daily, .mastery]
    }

    var displayName: String {
        switch self {
        case .general: return "Genel"
        case .letters: return "Kelime"
        case .numbers: return "Sayı"
        case .speed: return "Hız"
        case .combo: return "Kombo"
        case .daily: return "Günlük"
        case .mastery: return "Ustalık"
        }
    }

    var iconName: String {
        switch self {
        case .general: return "star.fill"
        case .letters: return "textformat.abc"
        case .numbers: return "number"
        case .speed: return "hare.fill"
        case .combo: return "flame.fill"
        case .daily: return "calendar.badge.clock"
        case .mastery: return "crown.fill"
        }
    }
}

#Preview {
    AchievementsView()
}
