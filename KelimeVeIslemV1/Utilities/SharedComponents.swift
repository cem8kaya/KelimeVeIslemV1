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
    var message: String = "Yükleniyor..."

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

// MARK: - Score Popup Animation

struct ScorePopup: View {
    let points: Int
    @State private var opacity: Double = 1.0
    @State private var offset: CGFloat = 0

    var body: some View {
        Text("+\(points)")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.yellow)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    opacity = 0
                    offset = -50
                }
            }
    }
}

struct ScorePopupModifier: ViewModifier {
    @Binding var score: Int
    @State private var previousScore: Int = 0
    @State private var showPopup: Bool = false
    @State private var popupPoints: Int = 0

    func body(content: Content) -> some View {
        ZStack {
            content

            if showPopup {
                VStack {
                    ScorePopup(points: popupPoints)
                        .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .onChange(of: score) { oldValue, newValue in
            let difference = newValue - oldValue
            if difference > 0 {
                popupPoints = difference
                showPopup = true

                // Hide popup after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showPopup = false
                }
            }
        }
    }
}

extension View {
    func scorePopup(score: Binding<Int>) -> some View {
        modifier(ScorePopupModifier(score: score))
    }
}

// MARK: - Combo Counter View

struct ComboView: View {
    let comboCount: Int
    @State private var scale: CGFloat = 1.0
    @State private var showMilestone: Bool = false

    var comboMultiplier: Int {
        if comboCount >= 10 { return 5 }
        if comboCount >= 5 { return 3 }
        if comboCount >= 3 { return 2 }
        return 1
    }

    var comboColor: Color {
        if comboCount >= 10 { return .purple }
        if comboCount >= 5 { return .red }
        if comboCount >= 3 { return .orange }
        return .orange
    }

    var comboIcon: String {
        if comboCount >= 10 { return "🔥🔥🔥" }
        if comboCount >= 5 { return "🔥🔥" }
        return "🔥"
    }

    var body: some View {
        if comboCount >= 2 {
            VStack(spacing: 5) {
                HStack(spacing: 8) {
                    Text(comboIcon)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(comboCount) Combo!")
                            .font(.headline.bold())
                            .foregroundColor(comboColor)

                        if comboMultiplier > 1 {
                            Text("\(comboMultiplier)x Çarpan")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(comboColor.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(comboColor, lineWidth: 2)
                        )
                )
                .scaleEffect(scale)

                // Milestone celebration text
                if showMilestone {
                    Text(milestoneText)
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.3))
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onChange(of: comboCount) { oldValue, newValue in
                // Animate when combo increases
                if newValue > oldValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        scale = 1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            scale = 1.0
                        }
                    }

                    // Show milestone message
                    if isMilestone(newValue) {
                        showMilestone = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showMilestone = false
                            }
                        }
                    }
                }
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func isMilestone(_ count: Int) -> Bool {
        return count == 3 || count == 5 || count == 10 || count % 10 == 0
    }

    private var milestoneText: String {
        switch comboCount {
        case 3: return "🎉 2x Çarpan Kazandınız!"
        case 5: return "⚡ 3x Çarpan Kazandınız!"
        case 10: return "💥 5x Çarpan Kazandınız!"
        case let n where n % 10 == 0: return "🌟 İnanılmaz! \(n) Combo!"
        default: return ""
        }
    }
}

// MARK: - Confetti Animation

struct ConfettiView: View {
    @State private var confettiIsActive = false
    let trigger: Bool

    var body: some View {
        ZStack {
            if confettiIsActive {
                ConfettiLayer()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: trigger) { oldValue, newValue in
            if newValue && !oldValue {
                confettiIsActive = true
                // Stop confetti after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    confettiIsActive = false
                }
            }
        }
    }
}

struct ConfettiLayer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        // Get screen bounds from the view's window scene
        let screenWidth: CGFloat
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            screenWidth = windowScene.screen.bounds.width
        } else {
            // Fallback to a reasonable default if window scene is not available
            screenWidth = 393 // iPhone 14 Pro width as default
        }

        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: screenWidth / 2, y: -50)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: screenWidth, height: 1)

        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen,
            .systemYellow, .systemOrange, .systemPurple,
            .systemPink, .systemTeal
        ]

        var cells: [CAEmitterCell] = []
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 10.0
            cell.velocity = 150
            cell.velocityRange = 100
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3.5
            cell.spinRange = 4
            cell.scale = 0.15
            cell.scaleRange = 0.1
            cell.contents = createConfettiImage(color: color).cgImage
            cells.append(cell)
        }

        emitterLayer.emitterCells = cells
        view.layer.addSublayer(emitterLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func createConfettiImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Achievement Notification

struct AchievementNotification: View {
    let achievement: Achievement
    @State private var isVisible = false
    @State private var offset: CGFloat = -200

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Icon
                Image(systemName: achievement.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(.yellow)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.yellow.opacity(0.2))
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text("🏆 Başarım Kazanıldı!")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)

                    Text(achievement.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)

                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#6366F1")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "#8B5CF6").opacity(0.5), radius: 15, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
            )
            .padding(.horizontal, 20)

            Spacer()
        }
        .offset(y: offset)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
                offset = 100
            }

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    offset = -200
                    isVisible = false
                }
            }
        }
    }
}

// Achievement notification modifier
struct AchievementNotificationModifier: ViewModifier {
    @Binding var achievements: [Achievement]
    @State private var currentAchievement: Achievement?
    @State private var showNotification = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if showNotification, let achievement = currentAchievement {
                AchievementNotification(achievement: achievement)
                    .zIndex(999)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: achievements) { oldValue, newValue in
            // Show notification for new achievements
            if let newAchievement = newValue.first, !showNotification {
                currentAchievement = newAchievement
                showNotification = true

                // Remove from queue and show next after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    showNotification = false
                    if achievements.count > 0 {
                        achievements.removeFirst()
                    }

                    // Show next achievement if any
                    if !achievements.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            currentAchievement = achievements.first
                            showNotification = true
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func achievementNotifications(_ achievements: Binding<[Achievement]>) -> some View {
        modifier(AchievementNotificationModifier(achievements: achievements))
    }
}

// NOTE: GameMode and PersistenceService are assumed to be imported or available in the app scope.
