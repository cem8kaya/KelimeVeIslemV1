//
//  AudioService.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

import Foundation
import AVFoundation
import Combine
import UIKit

@MainActor
class AudioService: ObservableObject {
    static let shared = AudioService()

    @Published var isSoundEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
        }
    }

    @Published var isMusicEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "musicEnabled")
            if !isMusicEnabled {
                stopBackgroundMusic()
            }
        }
    }

    @Published var soundVolume: Float = 0.7 {
        didSet {
            UserDefaults.standard.set(soundVolume, forKey: "soundVolume")
        }
    }

    @Published var musicVolume: Float = 0.5 {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: "musicVolume")
            updateMusicVolume()
        }
    }

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    private let audioQueue = DispatchQueue(label: "com.kelimeveislem.audio", qos: .userInteractive)

    // Background music players
    private var musicPlayer: AVAudioPlayer?
    private var currentMusicType: MusicType?

    // Preloaded sound buffers
    private var soundBuffers: [String: AVAudioPCMBuffer] = [:]

    private init() {
        isSoundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        isMusicEnabled = UserDefaults.standard.bool(forKey: "musicEnabled")
        soundVolume = UserDefaults.standard.float(forKey: "soundVolume")
        musicVolume = UserDefaults.standard.float(forKey: "musicVolume")

        // Set defaults if values are 0 (first launch)
        if soundVolume == 0 { soundVolume = 0.7 }
        if musicVolume == 0 { musicVolume = 0.5 }

        setupAudioSession()
        setupAudioEngine()
        preloadSounds()
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Failed to set up audio session: \(error)")
        }
    }

    private func setupAudioEngine() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()

            // Create explicit mono format at 44.1kHz to match generateAndPlayTone
            guard let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 44100,
                channels: 1,
                interleaved: false
            ) else {
                print("Audio format creation failed")
                return
            }

            engine.attach(player)
            // CRITICAL: Use explicit format instead of nil to avoid channel mismatch
            engine.connect(player, to: engine.mainMixerNode, format: format)

            do {
                try engine.start()
                // Safely update MainActor properties on the MainActor
                Task { @MainActor in
                    self.audioEngine = engine
                    self.playerNode = player
                    self.audioFormat = format
                }
            } catch {
                print("Failed to start audio engine: \(error)")
            }
        }
    }

    // MARK: - Sound Effects

    enum SoundEffect {
        case tick           // Timer tick
        case success        // Correct answer
        case failure        // Wrong answer
        case buttonTap      // Button press
        case gameStart      // Game begins
        case timeWarning    // Time running out
        case letterSelect(pitch: Int) // Letter selection with pitch variation
        case invalidWord    // Invalid word buzz
        case validWord(length: Int) // Valid word chime (pitch increases with length)
        case perfectScore   // Perfect score fanfare
        case levelUp        // Level up celebration
        case achievement    // Achievement unlock
        case comboMilestone(level: Int) // Combo milestone (2x, 3x, 5x, etc.)

        var frequency: Float {
            switch self {
            case .tick: return 800
            case .success: return 1000
            case .failure: return 300
            case .buttonTap: return 600
            case .gameStart: return 880
            case .timeWarning: return 1200
            case .letterSelect(let pitch):
                // Vary pitch based on letter (200-1000 Hz range)
                return Float(400 + (pitch * 60))
            case .invalidWord: return 200
            case .validWord(let length):
                // Higher pitch for longer words (600-1400 Hz)
                return Float(600 + min(length * 100, 800))
            case .perfectScore: return 1600
            case .levelUp: return 1400
            case .achievement: return 1300
            case .comboMilestone(let level):
                return Float(800 + (level * 100))
            }
        }

        var duration: TimeInterval {
            switch self {
            case .tick: return 0.05
            case .success: return 0.3
            case .failure: return 0.25
            case .buttonTap: return 0.1
            case .gameStart: return 0.4
            case .timeWarning: return 0.15
            case .letterSelect: return 0.08
            case .invalidWord: return 0.3
            case .validWord: return 0.4
            case .perfectScore: return 0.8
            case .levelUp: return 0.6
            case .achievement: return 0.5
            case .comboMilestone: return 0.35
            }
        }

        var isMultiTone: Bool {
            switch self {
            case .perfectScore, .levelUp, .achievement:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Background Music Types

    enum MusicType {
        case menu
        case gameplay
        case victory
    }

    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }

        // Execute tone generation on background queue
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            if effect.isMultiTone {
                // Play multi-tone sequence for special effects
                self.generateAndPlayMultiTone(effect: effect)
            } else {
                self.generateAndPlayTone(frequency: effect.frequency, duration: effect.duration, volume: self.soundVolume)
            }
        }
    }

    // MARK: - Background Music

    func playBackgroundMusic(_ type: MusicType) {
        guard isMusicEnabled else { return }

        // Stop current music if playing
        stopBackgroundMusic()

        currentMusicType = type

        // Generate simple looping background music programmatically
        Task {
            await generateAndLoopBackgroundMusic(type: type)
        }
    }

    func stopBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicType = nil
    }

    private func updateMusicVolume() {
        musicPlayer?.volume = musicVolume
    }

    private func generateAndLoopBackgroundMusic(type: MusicType) async {
        // For now, we'll use simple looping tones
        // In a real app, you would load audio files
        // This is a placeholder that demonstrates the concept
        print("🎵 Background music (\(type)) would play here")
    }

    // MARK: - Sound Preloading

    private func preloadSounds() {
        // Preload common sounds to reduce latency
        let commonSounds: [(key: String, freq: Float, dur: TimeInterval)] = [
            ("tick", 800, 0.05),
            ("success", 1000, 0.3),
            ("failure", 300, 0.25),
            ("buttonTap", 600, 0.1),
            ("gameStart", 880, 0.4),
            ("timeWarning", 1200, 0.15),
            ("invalidWord", 200, 0.3)
        ]

        audioQueue.async { [weak self] in
            for sound in commonSounds {
                if let buffer = self?.createAudioBuffer(frequency: sound.freq, duration: sound.dur, volume: 0.7) {
                    Task { @MainActor in
                        self?.soundBuffers[sound.key] = buffer
                    }
                }
            }
            print("✅ Preloaded \(commonSounds.count) sound effects")
        }
    }

    private func generateAndPlayTone(frequency: Float, duration: TimeInterval, volume: Float = 0.7) {
        guard let player = playerNode else {
            print("⚠️ Audio engine not ready")
            return
        }

        guard let audioBuffer = createAudioBuffer(frequency: frequency, duration: duration, volume: volume) else {
            return
        }

        // Schedule and play
        player.scheduleBuffer(audioBuffer, completionHandler: nil)

        if !player.isPlaying {
            player.play()
        }
    }

    private func createAudioBuffer(frequency: Float, duration: TimeInterval, volume: Float) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let length = Int(sampleRate * duration)

        guard length > 0 else { return nil }

        var audioData = [Float](repeating: 0, count: length)

        for i in 0..<length {
            let value = sin(2.0 * .pi * Double(i) * Double(frequency) / sampleRate)
            // Apply ADSR envelope for smoother sound
            let attack = min(1.0, Double(i) / (sampleRate * 0.01))
            let release = min(1.0, Double(length - i) / (sampleRate * 0.05))
            let envelope = attack * release
            audioData[i] = Float(value * envelope * Double(volume) * 0.4)
        }

        guard let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            print("⚠️ Failed to create audio format")
            return nil
        }

        guard let audioBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: UInt32(audioData.count)
        ) else {
            print("⚠️ Failed to create audio buffer")
            return nil
        }

        audioBuffer.frameLength = audioBuffer.frameCapacity

        guard let channelData = audioBuffer.floatChannelData else {
            print("⚠️ Failed to get channel data")
            return nil
        }

        for i in 0..<audioData.count {
            channelData[0][i] = audioData[i]
        }

        return audioBuffer
    }

    // Generate and play multi-tone sequences for special effects
    private func generateAndPlayMultiTone(effect: SoundEffect) {
        let tones: [(frequency: Float, duration: TimeInterval)]

        switch effect {
        case .perfectScore:
            // Ascending major chord arpeggio
            tones = [
                (800, 0.15),
                (1000, 0.15),
                (1200, 0.15),
                (1600, 0.35)
            ]
        case .levelUp:
            // Victory fanfare
            tones = [
                (600, 0.12),
                (800, 0.12),
                (1000, 0.12),
                (1200, 0.12),
                (1400, 0.24)
            ]
        case .achievement:
            // Achievement unlock chime
            tones = [
                (1000, 0.15),
                (1300, 0.15),
                (1600, 0.2)
            ]
        default:
            // Fallback to single tone
            generateAndPlayTone(frequency: effect.frequency, duration: effect.duration, volume: soundVolume)
            return
        }

        // Play tones in sequence
        var delay: TimeInterval = 0
        for tone in tones {
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.generateAndPlayTone(frequency: tone.frequency, duration: tone.duration, volume: self?.soundVolume ?? 0.7)
            }
            delay += tone.duration * 0.8 // Slight overlap
        }
    }


    // MARK: - Haptic Feedback

    func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func playSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    func playErrorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    // MARK: - Cleanup

    deinit {
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
    }
}
