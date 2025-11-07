//
//  AnimationModifiers.swift
//  KelimeVeIslemV1
//
//  Advanced animations and visual effects for the game
//

import SwiftUI

// MARK: - Spring Tile Button Style

struct SpringTileButtonStyle: ButtonStyle {
    let isSelected: Bool
    let theme: ThemeColors

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : (isSelected ? 1.05 : 1.0))
            .shadow(color: isSelected ? theme.letterTileSelected.opacity(0.5) : .clear,
                    radius: isSelected ? 8 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Pulsing Animation Modifier

struct PulsingModifier: ViewModifier {
    let isActive: Bool
    let color: Color
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .shadow(color: color.opacity(opacity * 0.6), radius: 20, x: 0, y: 0)
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    startPulsing()
                } else {
                    stopPulsing()
                }
            }
            .onAppear {
                if isActive {
                    startPulsing()
                }
            }
    }

    private func startPulsing() {
        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.1
            opacity = 0.3
        }
    }

    private func stopPulsing() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
            opacity = 1.0
        }
    }
}

extension View {
    func pulsing(isActive: Bool, color: Color = .red) -> some View {
        modifier(PulsingModifier(isActive: isActive, color: color))
    }
}

// MARK: - Game State Transition

enum GameStateTransition {
    case ready
    case playing
    case finished

    var offset: CGFloat {
        switch self {
        case .ready: return -500
        case .playing: return 0
        case .finished: return 500
        }
    }

    var opacity: Double {
        switch self {
        case .ready, .finished: return 0
        case .playing: return 1
        }
    }
}

struct GameStateTransitionModifier: ViewModifier {
    let state: GameStateTransition

    func body(content: Content) -> some View {
        content
            .offset(x: state.offset)
            .opacity(state.opacity)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: state)
    }
}

extension View {
    func gameStateTransition(_ state: GameStateTransition) -> some View {
        modifier(GameStateTransitionModifier(state: state))
    }
}

// MARK: - Particle Effect for Valid Words

struct ParticleEffect: View {
    let trigger: Bool
    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var scale: CGFloat
        var opacity: Double
        var color: Color
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .position(particle.position)
                }
            }
            .onChange(of: trigger) { oldValue, newValue in
                if newValue && !oldValue {
                    generateParticles(in: geometry.size)
                }
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let colors: [Color] = [.yellow, .orange, .green, .cyan, .purple]

        var newParticles: [Particle] = []
        for _ in 0..<20 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 50...150)
            let velocity = CGVector(
                dx: Darwin.cos(angle) * speed,
                dy: Darwin.sin(angle) * speed
            )

            let particle = Particle(
                position: center,
                velocity: velocity,
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: 1.0,
                color: colors.randomElement() ?? .yellow
            )
            newParticles.append(particle)
        }

        particles = newParticles
        animateParticles()
    }

    private func animateParticles() {
        let duration: Double = 1.0
        let steps = 60
        let stepDuration = duration / Double(steps)

        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                for index in particles.indices {
                    particles[index].position.x += particles[index].velocity.dx * CGFloat(stepDuration)
                    particles[index].position.y += particles[index].velocity.dy * CGFloat(stepDuration)
                    particles[index].velocity.dy += 200 * CGFloat(stepDuration) // Gravity
                    particles[index].opacity = 1.0 - (Double(step) / Double(steps))
                    particles[index].scale *= 0.98
                }
            }
        }

        // Clear particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            particles.removeAll()
        }
    }
}

struct ParticleEffectModifier: ViewModifier {
    @Binding var trigger: Bool

    func body(content: Content) -> some View {
        ZStack {
            content

            ParticleEffect(trigger: trigger)
                .allowsHitTesting(false)
        }
    }
}

extension View {
    func particleEffect(trigger: Binding<Bool>) -> some View {
        modifier(ParticleEffectModifier(trigger: trigger))
    }
}

// MARK: - Enhanced Score Popup

struct EnhancedScorePopup: View {
    let points: Int
    let multiplier: Int
    @State private var opacity: Double = 1.0
    @State private var offset: CGFloat = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 5) {
            Text("+\(points)")
                .font(.system(size: 36, weight: .heavy))
                .foregroundColor(.yellow)

            if multiplier > 1 {
                Text("\(multiplier)x Combo!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.2
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 1.2)) {
                    opacity = 0
                    offset = -80
                    scale = 1.0
                }
            }
        }
    }
}

struct EnhancedScorePopupModifier: ViewModifier {
    @Binding var score: Int
    let comboCount: Int
    @State private var previousScore: Int = 0
    @State private var showPopup: Bool = false
    @State private var popupPoints: Int = 0

    func body(content: Content) -> some View {
        ZStack {
            content

            if showPopup {
                VStack {
                    EnhancedScorePopup(points: popupPoints, multiplier: comboCount)
                        .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 80)
            }
        }
        .onChange(of: score) { oldValue, newValue in
            let difference = newValue - oldValue
            if difference > 0 {
                popupPoints = difference
                showPopup = true

                // Hide popup after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    showPopup = false
                }
            }
        }
    }
}

extension View {
    func enhancedScorePopup(score: Binding<Int>, comboCount: Int = 1) -> some View {
        modifier(EnhancedScorePopupModifier(score: score, comboCount: comboCount))
    }
}

// MARK: - Shake Animation (for errors)

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * Darwin.sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0
        ))
    }
}

extension View {
    func shake(amount: CGFloat = 10, trigger: Bool) -> some View {
        modifier(ShakeModifier(amount: amount, trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let amount: CGFloat
    let trigger: Bool
    @State private var shakeCount: Int = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(amount: amount, animatableData: CGFloat(shakeCount)))
            .onChange(of: trigger) { oldValue, newValue in
                if newValue {
                    withAnimation(.linear(duration: 0.5)) {
                        shakeCount += 1
                    }
                }
            }
    }
}

// MARK: - Bounce Animation

struct BounceModifier: ViewModifier {
    let trigger: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { oldValue, newValue in
                if newValue && !oldValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                        scale = 1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            scale = 1.0
                        }
                    }
                }
            }
    }
}

extension View {
    func bounce(trigger: Bool) -> some View {
        modifier(BounceModifier(trigger: trigger))
    }
}

// MARK: - Glow Effect

struct GlowModifier: ViewModifier {
    let color: Color
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity), radius: 10, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.5), radius: 20, x: 0, y: 0)
    }
}

extension View {
    func glow(color: Color, intensity: Double = 0.8) -> some View {
        modifier(GlowModifier(color: color, intensity: intensity))
    }
}
