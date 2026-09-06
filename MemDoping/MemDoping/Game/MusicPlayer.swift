//
//  MusicPlayer.swift
//  MemDoping
//
//  A calm, looping ambient pad synthesized in code (no bundled audio). A soft
//  major chord under a slow "breathing" envelope that fades to silence at both
//  ends of the buffer, so it loops seamlessly like gentle waves. Kept quiet and
//  mixable; toggled by GameStore.musicEnabled. A real track can replace this
//  later by loading a file into the same player.
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

    func start() {
        guard !started else { return }
        do { try engine.start() } catch { return }
        player.scheduleBuffer(padBuffer(), at: nil, options: .loops)
        player.play()
        started = true
    }

    func stop() {
        guard started else { return }
        player.stop()
        engine.stop()
        started = false
    }

    func setEnabled(_ on: Bool) { on ? start() : stop() }

    /// A ~12 s soft chord that swells and fades within the loop (zero at the
    /// edges, so the loop point is silent → seamless).
    private func padBuffer() -> AVAudioPCMBuffer {
        let duration = 12.0
        let frames = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let channel = buffer.floatChannelData![0]

        // A warm C major chord (C3, G3, C4, E4), lightly detuned for a chorus.
        let notes: [Double] = [130.81, 196.00, 261.63, 329.63]

        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let envelope = pow(sin(.pi * t / duration), 2)   // 0 → 1 → 0
            var sample = 0.0
            for f in notes {
                sample += sin(2 * .pi * f * t)
                sample += 0.5 * sin(2 * .pi * (f * 1.004) * t)
            }
            sample /= Double(notes.count * 2)
            channel[i] = Float(sample * envelope) * 0.11
        }
        return buffer
    }
}
