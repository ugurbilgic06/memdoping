//
//  MusicPlayer.swift
//  MemDoping
//
//  A calm, looping spa ambience synthesized in code (no bundled audio): soft
//  pentatonic chimes — like singing bowls / a Chinese spa — wandering gently
//  over a warm, breathing drone. The whole loop fades to silence at both edges
//  so it repeats seamlessly. The pentatonic scale has no semitone tension, so it
//  reads as soothing, never eerie. Kept quiet and mixable; toggled by
//  GameStore.musicEnabled. A real track can replace this later.
//

import AVFoundation

final class MusicPlayer {
    static let shared = MusicPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private let format: AVAudioFormat
    private var started = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        #endif
    }

    private(set) var isNight = false

    /// The daytime spa loop.
    func start() { startMode(night: false) }
    /// A slower, lower, sleepier loop for Night Doping.
    func startNight() { startMode(night: true) }

    private func startMode(night: Bool) {
        if started && isNight == night { return }   // already in this mode
        do { try engine.start() } catch { return }
        player.stop()
        player.scheduleBuffer(night ? nightBuffer() : padBuffer(), at: nil, options: .loops)
        player.play()
        started = true
        isNight = night
    }

    func stop() {
        guard started else { return }
        player.stop()
        engine.stop()
        started = false
    }

    func setEnabled(_ on: Bool) { on ? start() : stop() }

    /// A ~20 s spa loop: soft pentatonic bell chimes over a warm breathing drone,
    /// fading to silence at both edges so the loop point is seamless.
    private func padBuffer() -> AVAudioPCMBuffer {
        let duration = 20.0
        let frames = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let channel = buffer.floatChannelData![0]

        // C major pentatonic in a gentle chime octave (C5 D5 E5 G5 A5 C6). No
        // semitones → nothing dissonant or tense.
        let penta: [Double] = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50]
        // A slow, wandering melody: (start time, index into `penta`).
        let melody: [(Double, Int)] = [
            (1.6, 0), (3.5, 2), (5.3, 1), (7.1, 3), (8.9, 2),
            (10.7, 4), (12.5, 3), (14.3, 5), (16.0, 4), (17.4, 1)
        ]
        let fade = 1.6   // seconds of fade at each edge → seamless loop

        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate

            // Edge fade so the loop is silent at the seam.
            var g = 1.0
            if t < fade { g = pow(sin(.pi * t / (2 * fade)), 2) }
            else if t > duration - fade { g = pow(sin(.pi * (duration - t) / (2 * fade)), 2) }

            // Only soft bell chimes over quiet — no background drone/hum. Each
            // note plucks and rings out (singing-bowl timbre), the way calm
            // Chinese relaxation music breathes with space between the notes.
            var s = 0.0
            for (start, idx) in melody where t >= start {
                let l = t - start
                let env = exp(-l * 1.9)
                if env > 0.001 {
                    let f = penta[idx]
                    let bell = sin(2 * .pi * f * l)
                        + 0.35 * sin(2 * .pi * 2 * f * l)
                        + 0.12 * sin(2 * .pi * 3 * f * l)
                    s += 0.09 * env * bell
                }
            }

            channel[i] = Float(s * g)
        }
        return buffer
    }

    /// A ~30 s sleep loop for Night Doping: a soft, low, warm drone that breathes
    /// slowly, with a few deep, long-ringing bells far apart — lower, quieter and
    /// slower than the day loop, to help wind down.
    private func nightBuffer() -> AVAudioPCMBuffer {
        let duration = 30.0
        let frames = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let channel = buffer.floatChannelData![0]

        // A low, warm drone (A2 + E3) for a calm, grounding hum.
        let drone: [Double] = [110.0, 164.81]
        // A minor pentatonic in a low octave (A3 C4 D4 E4 G4) — soft and restful.
        let penta: [Double] = [220.0, 261.63, 293.66, 329.63, 392.00]
        // Very sparse, slow notes with long silences between them.
        let melody: [(Double, Int)] = [(4, 0), (11, 2), (17, 1), (23, 3), (27, 0)]
        let fade = 3.0

        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate

            var g = 1.0
            if t < fade { g = pow(sin(.pi * t / (2 * fade)), 2) }
            else if t > duration - fade { g = pow(sin(.pi * (duration - t) / (2 * fade)), 2) }

            // Soft breathing drone.
            let breath = 0.7 + 0.3 * sin(2 * .pi * t / duration)
            var s = 0.0
            for f in drone { s += 0.045 * breath * sin(2 * .pi * f * t) }

            // Deep bells that ring out for a long time.
            for (start, idx) in melody where t >= start {
                let l = t - start
                let env = exp(-l * 0.85)
                if env > 0.001 {
                    let f = penta[idx]
                    let bell = sin(2 * .pi * f * l) + 0.3 * sin(2 * .pi * 2 * f * l)
                    s += 0.06 * env * bell
                }
            }

            channel[i] = Float(s * g)
        }
        return buffer
    }
}
