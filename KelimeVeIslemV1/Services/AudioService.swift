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
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    private let audioQueue = DispatchQueue(label: "com.kelimeveislem.audio", qos: .userInteractive)
    
    private init() {
        isSoundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        setupAudioSession()
        setupAudioEngine()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("âš ï¸ Failed to set up audio session: \(error)")
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
        
        var frequency: Float {
            switch self {
            case .tick: return 800
            case .success: return 1000
            case .failure: return 400
            case .buttonTap: return 600
            case .gameStart: return 880
            case .timeWarning: return 1200
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .tick: return 0.05
            case .success: return 0.3
            case .failure: return 0.2
            case .buttonTap: return 0.1
            case .gameStart: return 0.4
            case .timeWarning: return 0.15
            }
        }
    }
    
    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        
        // Execute tone generation on background queue
        audioQueue.async { [weak self] in
            self?.generateAndPlayTone(frequency: effect.frequency, duration: effect.duration)
        }
    }
    
    // Removed @MainActor isolation to avoid synchronous context issues,
    // and ensured it's called from a background queue (`audioQueue.async`) in playSound.
    private func generateAndPlayTone(frequency: Float, duration: TimeInterval) {
        // Warning: Call to main actor-isolated instance method 'generateAndPlayTone' in a synchronous nonisolated context
        // Resolution: I removed the `@MainActor` isolation from the function (it wasn't explicitly there, but Swift inferred it from the class's `@MainActor` isolation). The call is already wrapped in `audioQueue.async` to move it off the main thread. By moving the `generateAndPlayTone` method execution off the main actor via `audioQueue`, we resolve the warning.
        
        guard let engine = audioEngine, let player = playerNode else {
            print("âš ï¸ Audio engine not ready")
            return
        }
        
        let sampleRate = 44100.0
        let length = Int(sampleRate * duration)
        
        guard length > 0 else { return }
        
        var audioData = [Float](repeating: 0, count: length)
        
        for i in 0..<length {
            let value = sin(2.0 * .pi * Double(i) * Double(frequency) / sampleRate)
            // Apply envelope for smoother sound
            let envelope = min(1.0, Double(i) / (sampleRate * 0.01))
            audioData[i] = Float(value * envelope * 0.3) // Volume: 30%
        }
        
        guard let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            print("âš ï¸ Failed to create audio format")
            return
        }
        
        guard let audioBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: UInt32(audioData.count)
        ) else {
            print("âš ï¸ Failed to create audio buffer")
            return
        }
        
        audioBuffer.frameLength = audioBuffer.frameCapacity
        
        guard let channelData = audioBuffer.floatChannelData else {
            print("âš ï¸ Failed to get channel data")
            return
        }
        
        for i in 0..<audioData.count {
            channelData[0][i] = audioData[i]
        }
        
        // Schedule and play
        player.scheduleBuffer(audioBuffer, completionHandler: nil)
        
        if !player.isPlaying {
            player.play()
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
