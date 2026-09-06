//
//  FeedbackEngine.swift
//  MemDoping
//
//  Sensory Motivation Engine (§4): short sound and haptic feedback for
//  correct/incorrect answers and level-up moments. Tones are synthesized in
//  code (no bundled audio assets) so the effect ships without external
//  files. Both engines are silent no-ops unless the caller checks
//  GameStore's soundEnabled/hapticsEnabled first — comfort settings must
//  actually take effect, not just exist as toggles.
//

import AVFoundation
#if os(iOS)
import UIKit
#endif

/// Plays very short procedurally-generated tones for game feedback.
final class SoundPlayer {
    static let shared = SoundPlayer()

    enum Effect {
        case tap
        case correct
        case incorrect
        case levelUp
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private var isRunning = false

    private init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        #endif
    }

    func play(_ effect: Effect) {
        startIfNeeded()
        guard isRunning else { return }
        player.scheduleBuffer(buffer(for: effect), at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    private func startIfNeeded() {
        guard !isRunning else { return }
        do {
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    private func buffer(for effect: Effect) -> AVAudioPCMBuffer {
        switch effect {
        case .tap:       return tone(frequencies: [880], noteDuration: 0.05, gain: 0.15)
        case .correct:   return tone(frequencies: [660, 990], noteDuration: 0.11, gain: 0.2)
        case .incorrect: return tone(frequencies: [220], noteDuration: 0.18, gain: 0.2, shape: .square)
        case .levelUp:   return tone(frequencies: [523, 659, 784], noteDuration: 0.13, gain: 0.22)
        }
    }

    private enum Waveform { case sine, square }

    /// One short note per frequency, concatenated — a tiny arpeggio for
    /// multi-note effects (correct/levelUp). Each note fades in/out to avoid
    /// clicks at its edges.
    private func tone(frequencies: [Double], noteDuration: Double, gain: Float, shape: Waveform = .sine) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let framesPerNote = Int(noteDuration * sampleRate)
        let totalFrames = AVAudioFrameCount(framesPerNote * frequencies.count)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames)!
        buffer.frameLength = totalFrames
        let channel = buffer.floatChannelData![0]
        let fadeFrames = max(1.0, Double(framesPerNote) * 0.1)

        var offset = 0
        for frequency in frequencies {
            for i in 0..<framesPerNote {
                let t = Double(i) / sampleRate
                let raw: Double = switch shape {
                case .sine:   sin(2 * .pi * frequency * t)
                case .square: sin(2 * .pi * frequency * t) >= 0 ? 1 : -1
                }
                let envelope = min(1, min(Double(i), Double(framesPerNote - i)) / fadeFrames)
                channel[offset + i] = Float(raw * envelope) * gain
            }
            offset += framesPerNote
        }
        return buffer
    }
}

/// Wraps UIKit haptics; a silent no-op on platforms without them (macOS,
/// visionOS) so callers don't need per-platform checks.
final class HapticsPlayer {
    static let shared = HapticsPlayer()
    private init() {}

    func notify(success: Bool) {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(success ? .success : .error)
        #endif
    }

    func tap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
