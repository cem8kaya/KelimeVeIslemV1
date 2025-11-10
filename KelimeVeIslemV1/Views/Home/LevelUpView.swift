//
//  LevelUpView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 11/10/25.
//

import SwiftUI

// MARK: - Level Up Celebration View

struct LevelUpView: View {
    let newLevel: Level
    let onDismiss: () -> Void

    @State private var animateText = false
    @State private var animateBadge = false
    @State private var showRewards = false
    @State private var confettiCounter = 0

    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            // Background with blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Confetti
            ConfettiView(counter: $confettiCounter)

            // Main content
            VStack(spacing: 30) {
                Spacer()

                // "Level Up!" Text
                VStack(spacing: 10) {
                    Text("SEVIYE ATLAMA!")
                        .font(.system(size: 42, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .yellow.opacity(0.8), radius: 20, x: 0, y: 0)
                        .scaleEffect(animateText ? 1.0 : 0.3)
                        .opacity(animateText ? 1.0 : 0.0)

                    Text("Tebrikler!")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(animateText ? 1.0 : 0.0)
                }

                // Level Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#FFD700"),
                                    Color(hex: "#FFA500")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                        .shadow(color: .yellow.opacity(0.6), radius: 30, x: 0, y: 10)

                    VStack(spacing: 5) {
                        Text("SEVİYE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))

                        Text("\(newLevel.levelNumber)")
                            .font(.system(size: 60, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(animateBadge ? 1.0 : 0.1)
                .rotationEffect(.degrees(animateBadge ? 0 : 360))

                // Rewards Section
                if !newLevel.rewards.isEmpty && showRewards {
                    VStack(spacing: 15) {
                        Text("Yeni Ödüller!")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(spacing: 10) {
                            ForEach(newLevel.rewards.indices, id: \.self) { index in
                                RewardRow(reward: newLevel.rewards[index])
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Continue button
                Button(action: onDismiss) {
                    Text("Devam Et")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [
                                    themeManager.colors.primaryButton,
                                    themeManager.colors.secondaryButton
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: themeManager.colors.primaryButton.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(showRewards ? 1.0 : 0.0)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Text animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            animateText = true
        }

        // Badge animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.5)) {
                animateBadge = true
            }

            // Trigger confetti
            confettiCounter += 1
        }

        // Rewards animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showRewards = true
            }
        }
    }
}

// MARK: - Reward Row

struct RewardRow: View {
    let reward: LevelReward

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reward.iconName)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 30)

            Text(reward.displayName)
                .font(.body.weight(.semibold))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @Binding var counter: Int
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onChange(of: counter) { _ in
                generateConfetti(in: geometry.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func generateConfetti(in size: CGSize) {
        particles.removeAll()

        for _ in 0..<100 {
            let particle = ConfettiParticle(
                x: Double.random(in: 0...size.width),
                y: -50,
                color: [.red, .orange, .yellow, .green, .blue, .purple, .pink].randomElement()!,
                size: Double.random(in: 8...15),
                rotationSpeed: Double.random(in: -10...10),
                fallSpeed: Double.random(in: 200...400),
                horizontalDrift: Double.random(in: -100...100)
            )
            particles.append(particle)
        }

        // Remove particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            particles.removeAll()
        }
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let color: Color
    let size: Double
    let rotationSpeed: Double
    let fallSpeed: Double
    let horizontalDrift: Double
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle

    @State private var offsetY: Double = 0
    @State private var offsetX: Double = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: particle.size / 4)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(
                x: particle.x + offsetX,
                y: particle.y + offsetY
            )
            .onAppear {
                withAnimation(.linear(duration: 4)) {
                    offsetY = particle.fallSpeed * 2
                    offsetX = particle.horizontalDrift
                    rotation = particle.rotationSpeed * 360
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()

        LevelUpView(
            newLevel: Level.allLevels[4], // Level 5
            onDismiss: {}
        )
    }
}
