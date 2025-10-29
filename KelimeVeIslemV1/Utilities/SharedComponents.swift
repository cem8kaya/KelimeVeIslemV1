//
//  SharedComponents.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  SharedComponents.swift
//  KelimeVeIslem
//
//  Centralized views for Timer, Score, Loading, and general UI utilities.
//

import SwiftUI

// MARK: - Utility Extension for Hex Colors (Used globally)

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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom Button Styles (Used globally for all game buttons)

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Primary Game Button

struct PrimaryGameButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                }
                Text(title)
                    .font(.title2.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color)
            .cornerRadius(15)
            .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 5)
        }
        .buttonStyle(GrowingButton())
    }
}

// MARK: - Timer View

struct TimerView: View {
    let timeRemaining: Int
    let totalDuration: Int
    
    init(timeRemaining: Int, mode: GameMode) {
        self.timeRemaining = timeRemaining
        // Note: GameMode needs to be imported or available in scope. Assuming it is.
        let settings = PersistenceService.shared.loadSettings()
        
        switch mode {
        case .letters:
            self.totalDuration = settings.letterTimerDuration
        case .numbers:
            self.totalDuration = settings.numberTimerDuration
        }
    }
    
    private var progress: Double {
        guard totalDuration > 0 else { return 1.0 }
        // Ensure progress doesn't go below zero if there's a slight delay in state update
        return max(0, Double(timeRemaining) / Double(totalDuration))
    }
    
    private var progressColor: Color {
        if timeRemaining <= 10 {
            return .red
        } else if timeRemaining <= 20 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 5)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)
            
            VStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                
                Text("\(timeRemaining)s")
                    .font(.headline.bold())
                    .monospacedDigit()
            }
            .foregroundColor(progressColor)
        }
        .frame(width: 60, height: 60)
        .padding(.vertical, 8)
        .accessibilityLabel("Time remaining: \(timeRemaining) seconds")
    }
}

// MARK: - Score View

struct ScoreView: View {
    let score: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.body)
            
            Text("\(score)")
                .font(.title2.bold())
                .monospacedDigit()
        }
        .foregroundColor(.yellow)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.2))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .accessibilityLabel("Current score: \(score) points")
    }
}

// MARK: - Loading Overlay (Resolves "Cannot find 'LoadingOverlay'")

struct LoadingOverlay: View {
    var message: String = "Loading..."
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 15) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.black.opacity(0.7))
            .cornerRadius(15)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Game Ready View (Resolves "Cannot find 'ReadyView'")

struct GameReadyView: View {
    let title: String
    let subtitle: String
    let actionTitle: String
    let color: Color
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            PrimaryGameButton(
                title: actionTitle,
                icon: "play.fill",
                color: color,
                action: onStart
            )
            .padding(.horizontal, 40)
        }
    }
}

// NOTE: GameMode and PersistenceService are assumed to be imported or available in the app scope.
