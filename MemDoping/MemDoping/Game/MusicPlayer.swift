//
//  MusicPlayer.swift
//  MemDoping
//
//  Calm, looping ambience synthesized in code (no bundled audio). The daytime
//  loop changes with the audience — children get a livelier, bouncier tune,
//  teens a more striking one with a pulse and a low drone, adults a sparser,
//  more restful one. Night Doping keeps its own sleep loop. Every loop fades to
//  silence at both edges so it repeats seamlessly, and pentatonic scales keep
//  the harmony free of semitone tension. Toggled by GameStore.musicEnabled.
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
        // Background music sits well under the narrator and the game sounds.
        player.volume = 0.5
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        #endif
    }

    /// Which loop is playing, so toggling music back on resumes the right one.
    enum Mood: Equatable { case child, teen, adult, night }
    private(set) var mood: Mood = .adult

    var isNight: Bool { mood == .night }

    /// The daytime loop for this audience (nil = the calm default).
    func start(for band: GameStore.AgeBand? = nil) {
        switch band {
        case .child: play(.child)
        case .teen:  play(.teen)
        default:     play(.adult)
        }
    }

    /// The slower, lower, sleepier loop for Night Doping.
    func startNight() { play(.night) }

    private func play(_ newMood: Mood) {
        if started && mood == newMood { return }   // already in this mode
        do { try engine.start() } catch { return }
        player.stop()
        player.scheduleBuffer(buffer(for: newMood), at: nil, options: .loops)
        player.play()
        started = true
        mood = newMood
    }

    func stop() {
        guard started else { return }
        player.stop()
        engine.stop()
        started = false
    }

    /// Resume the loop that was last playing (or pause everything).
    func setEnabled(_ on: Bool) { on ? play(mood) : stop() }

    // MARK: - Loop recipes

    /// One loop's musical shape. Everything is rendered by `render(_:)`.
    private struct Recipe {
        let duration: Double
        /// Note frequencies the melody picks from.
        let scale: [Double]
        /// (start time, index into `scale`).
        let melody: [(Double, Int)]
        /// How fast each note rings out — larger is pluckier, smaller sustains.
        let decay: Double
        /// Per-note loudness.
        let gain: Double
        /// Seconds of fade at each edge so the loop seam is silent.
        let fade: Double
        /// Optional low drone tones under the melody.
        let drone: [Double]
        let droneGain: Double
        /// A gentle amplitude pulse (Hz); 0 = none.
        let pulse: Double
        /// The instrument's colour: (harmonic multiple, its gain). More upper
        /// harmonics = brighter and more toy-like; fewer = softer and rounder.
        let harmonics: [(Double, Double)]
        /// A low thump on every pulse beat (teen's drive); 0 = none.
        let beatBass: Double

        init(duration: Double, scale: [Double], melody: [(Double, Int)],
             decay: Double, gain: Double, fade: Double,
             drone: [Double] = [], droneGain: Double = 0, pulse: Double = 0,
             harmonics: [(Double, Double)] = [(1, 1.0), (2, 0.35), (3, 0.12)],
             beatBass: Double = 0) {
            self.duration = duration; self.scale = scale; self.melody = melody
            self.decay = decay; self.gain = gain; self.fade = fade
            self.drone = drone; self.droneGain = droneGain; self.pulse = pulse
            self.harmonics = harmonics; self.beatBass = beatBass
        }
    }

    fileprivate func buffer(for mood: Mood) -> AVAudioPCMBuffer {
        render(recipe(for: mood))
    }

    private func recipe(for mood: Mood) -> Recipe {
        switch mood {

        // Children: a gentle music box — a sweet, unhurried lullaby that steps
        // between neighbouring notes rather than leaping, in a friendly middle
        // register. Sympathetic, never busy: a fast, high, sparkly version read
        // as tense, so this one breathes slowly instead.
        case .child:
            return Recipe(
                duration: 20,
                scale: [523.25, 587.33, 659.25, 783.99, 880.00],   // C major pentatonic
                melody: [(1.5, 0), (3.2, 1), (4.9, 2), (6.6, 1), (8.3, 3),
                         (10.0, 2), (11.7, 4), (13.4, 2), (15.1, 1), (16.8, 0)],
                decay: 2.2, gain: 0.075, fade: 2.0, pulse: 0.3,
                harmonics: [(1, 1.0), (2, 0.28), (3, 0.10)])

        // Teens: darker and driving — a low fifth drone, a thumping beat and a
        // minor pentatonic in a mid register. Impressive, not loud.
        case .teen:
            return Recipe(
                duration: 16,
                scale: [220.00, 261.63, 293.66, 329.63, 392.00, 440.00],  // A minor pentatonic, low
                melody: [(0.50, 0), (1.25, 3), (2.00, 2), (2.75, 4), (3.50, 3),
                         (4.25, 5), (5.00, 4), (5.75, 2), (6.50, 3), (7.25, 0),
                         (8.00, 4), (8.75, 5), (9.50, 3), (10.25, 2), (11.00, 4),
                         (11.75, 1), (12.50, 3), (13.25, 5), (14.00, 4), (14.75, 0)],
                decay: 2.6, gain: 0.07, fade: 1.0,
                drone: [82.41, 123.47], droneGain: 0.05, pulse: 2.0,
                harmonics: [(1, 1.0), (2, 0.5), (3, 0.28), (5, 0.10)],
                beatBass: 0.085)

        // Adults: the most restful — very sparse, low, almost pure tones with
        // long ring-outs and wide silences. No sparkle, no pulse.
        case .adult:
            return Recipe(
                duration: 28,
                scale: [261.63, 293.66, 329.63, 392.00, 440.00],   // low, warm
                melody: [(3.0, 0), (7.5, 2), (12.0, 1), (16.5, 3), (21.0, 2), (25.0, 0)],
                decay: 0.55, gain: 0.10, fade: 2.4,
                harmonics: [(1, 1.0), (2, 0.12)])

        // Night Doping: the existing sleep loop — a low warm drone that
        // breathes, with deep bells far apart.
        case .night:
            return Recipe(
                duration: 30,
                scale: [220.0, 261.63, 293.66, 329.63, 392.00],
                melody: [(4, 0), (11, 2), (17, 1), (23, 3), (27, 0)],
                decay: 0.85, gain: 0.06, fade: 3.0,
                drone: [110.0, 164.81], droneGain: 0.045)
        }
    }

    /// Renders a recipe into a seamless looping buffer: soft bell notes (a
    /// singing-bowl timbre) over an optional drone, faded to silence at both
    /// edges so the loop point is inaudible.
    private func render(_ r: Recipe) -> AVAudioPCMBuffer {
        let frames = AVAudioFrameCount(r.duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let channel = buffer.floatChannelData![0]

        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate

            // Edge fade so the loop is silent at the seam.
            var g = 1.0
            if t < r.fade { g = pow(sin(.pi * t / (2 * r.fade)), 2) }
            else if t > r.duration - r.fade { g = pow(sin(.pi * (r.duration - t) / (2 * r.fade)), 2) }

            // A gentle amplitude pulse gives the loop a heartbeat.
            if r.pulse > 0 { g *= 0.86 + 0.14 * sin(2 * .pi * r.pulse * t) }

            var s = 0.0

            // Slow breathing drone.
            if !r.drone.isEmpty {
                let breath = 0.7 + 0.3 * sin(2 * .pi * t / r.duration)
                for f in r.drone { s += r.droneGain * breath * sin(2 * .pi * f * t) }
            }

            // A low thump on every beat gives the teen loop its drive.
            if r.beatBass > 0, r.pulse > 0 {
                let period = 1.0 / r.pulse
                let l = t.truncatingRemainder(dividingBy: period)
                let env = exp(-l * 14)
                if env > 0.001 {
                    s += r.beatBass * env * sin(2 * .pi * 55 * l)
                }
            }

            // Melody notes that pluck and ring out, coloured by the recipe's
            // harmonics — that timbre is what makes each audience sound apart.
            for (start, idx) in r.melody where t >= start {
                let l = t - start
                let env = exp(-l * r.decay)
                if env > 0.001 {
                    let f = r.scale[idx]
                    var tone = 0.0
                    for (mult, amp) in r.harmonics {
                        tone += amp * sin(2 * .pi * f * mult * l)
                    }
                    s += r.gain * env * tone
                }
            }

            channel[i] = Float(s * g)
        }
        return buffer
    }
}
