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
            print("⚠️ Failed to set up audio session: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            
            do {
                try engine.start()
                Task { @MainActor in
                    self.audioEngine = engine
                    self.playerNode = player
                }
            } catch {
                print("⚠️ Failed to start audio engine: \(error)")
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
        
        audioQueue.async { [weak self] in
            self?.generateAndPlayTone(frequency: effect.frequency, duration: effect.duration)
        }
    }
    
    private func generateAndPlayTone(frequency: Float, duration: TimeInterval) {
        guard let engine = audioEngine, let player = playerNode else {
            print("⚠️ Audio engine not ready")
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
            print("⚠️ Failed to create audio format")
            return
        }
        
        guard let audioBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: UInt32(audioData.count)
        ) else {
            print("⚠️ Failed to create audio buffer")
            return
        }
        
        audioBuffer.frameLength = audioBuffer.frameCapacity
        
        guard let channelData = audioBuffer.floatChannelData else {
            print("⚠️ Failed to get channel data")
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

