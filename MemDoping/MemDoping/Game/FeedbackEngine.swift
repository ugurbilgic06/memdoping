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
        case pop        // a tile lands / bursts
        case sparkle    // confetti / celebration shimmer
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    /// One canonical buffer format. The player is connected to the mixer with
    /// this exact format so scheduled buffers always match it — connecting with
    /// `nil` picks up the hardware format (often 48 kHz stereo), which then
    /// mismatches our 44.1 kHz mono buffers and crashes `scheduleBuffer`.
    private let format: AVAudioFormat
    private var isRunning = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
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
        // All sounds are soft sine tones with long fades — gentle, never a blip.
        case .tap:       return tone(frequencies: [587], noteDuration: 0.06, gain: 0.09)
        // A soft, warm rising arpeggio — a gentle, positive "well done".
        case .correct:   return tone(frequencies: [523, 659, 784], noteDuration: 0.1, gain: 0.16)
        // A mellow, low two-note settle — reassuring, not a buzzer.
        case .incorrect: return tone(frequencies: [349, 294], noteDuration: 0.16, gain: 0.1)
        case .levelUp:   return tone(frequencies: [523, 659, 784, 1046], noteDuration: 0.13, gain: 0.18)
        case .pop:       return tone(frequencies: [659], noteDuration: 0.06, gain: 0.09)
        case .sparkle:   return tone(frequencies: [988, 1319, 1568], noteDuration: 0.07, gain: 0.11)
        }
    }

    private enum Waveform { case sine, square }

    /// One short note per frequency, concatenated — a tiny arpeggio for
    /// multi-note effects (correct/levelUp). Each note fades in/out to avoid
    /// clicks at its edges.
    private func tone(frequencies: [Double], noteDuration: Double, gain: Float, shape: Waveform = .sine) -> AVAudioPCMBuffer {
        let framesPerNote = Int(noteDuration * sampleRate)
        let totalFrames = AVAudioFrameCount(framesPerNote * frequencies.count)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames)!
        buffer.frameLength = totalFrames
        let channel = buffer.floatChannelData![0]
        let fadeFrames = max(1.0, Double(framesPerNote) * 0.28)   // longer fades = softer

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
