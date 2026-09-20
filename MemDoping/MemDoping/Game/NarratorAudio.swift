//
//  NarratorAudio.swift
//  MemDoping
//
//  Plays pre-recorded narrator clips bundled with the app (professional / human
//  voice), keyed by mechanic + language. Files live in Resources/Audio and are
//  named `narrate_<mechanic>_<lang>.<ext>`, e.g. narrate_loci_tr.m4a. If no clip
//  is bundled for a line, the caller falls back to on-device TTS (NarratorVoice).
//  This lets us swap in real recordings later with no code changes.
//

import AVFoundation

@MainActor
final class NarratorAudio {
    static let shared = NarratorAudio()

    private var player: AVAudioPlayer?
    private init() {}

    /// Play the recorded clip for this mechanic/language, if one is bundled.
    /// - Returns: true when a clip was found and started (so TTS can be skipped).
    @discardableResult
    func play(mechanic: LevelMechanic, lang: String) -> Bool {
        let code = lang.hasPrefix("tr") ? "tr" : "en"
        let name = "narrate_\(mechanic.rawValue)_\(code)"
        guard let url = ["m4a", "mp3", "caf", "aiff", "wav"].lazy
            .compactMap({ Bundle.main.url(forResource: name, withExtension: $0) })
            .first
        else { return false }

        do {
            player?.stop()
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = 0.9
            p.prepareToPlay()
            p.play()
            player = p
            return true
        } catch {
            return false
        }
    }

    func stop() { player?.stop() }
}
