//
//  NarratorVoice.swift
//  MemDoping
//
//  Speaks the owl narrator's line aloud using on-device text-to-speech, in the
//  app's chosen language (tr/en). This is the first pass at "voiced" narration —
//  no recorded audio assets. Toggled by GameStore.soundEnabled at the call site;
//  it plays over the ambient music (session is .ambient + .mixWithOthers).
//

import AVFoundation

@MainActor
final class NarratorVoice {
    static let shared = NarratorVoice()

    private let synth = AVSpeechSynthesizer()
    private init() {}

    /// Speak one line, replacing anything already being spoken.
    func speak(_ text: String) {
        let line = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }
        synth.stopSpeaking(at: .immediate)   // never overlap two lines

        let u = AVSpeechUtterance(string: line)
        u.voice = Self.voice(for: AppLocale.locale)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.96   // natural, unhurried
        u.pitchMultiplier = 1.0                              // natural pitch (less robotic)
        u.volume = 0.7                                       // sit under the music
        u.preUtteranceDelay = 0.15
        synth.speak(u)
    }

    func stop() { synth.stopSpeaking(at: .immediate) }

    /// A short, concrete spoken example for each mechanic, in the current
    /// language — so the owl demonstrates the technique, not just names it.
    /// Kept inline (not in the String Catalog) so it always has both languages.
    static func example(for m: LevelMechanic) -> String {
        let tr = (AppLocale.locale.language.languageCode?.identifier ?? "en") == "tr"
        switch m {
        case .loci:
            return tr ? "Eşyaları odandaki duraklara bırak: anahtarı kapıya, elmayı masaya. Sonra odayı gezerek her durakta ne bıraktığını hatırla."
                      : "Leave items at spots in your room — the key at the door, the apple on the table — then walk the room and recall what's at each spot."
        case .scene:
            return tr ? "Canlı bir sahne kur: elmanın alev aldığını hayal et. Görüntü ne kadar tuhafsa o kadar akılda kalır."
                      : "Build a vivid scene: picture the apple bursting into flames. The odder the image, the better it sticks."
        case .pairRecall:
            return tr ? "Önce sembolle kelimeyi birlikte gör, örneğin tilki ve 'tilki'. Sonra kelime saklanınca sen hatırla."
                      : "First see the symbol and word together — the fox and 'fox'. Then recall it when the word hides."
        case .chunking:
            return tr ? "Uzun sayıyı gruplara böl: 497162 yerine 497 - 162 olarak tut. Küçük gruplar akılda daha kolay kalır."
                      : "Break a long number into groups: hold 497 - 162 instead of 497162. Small groups are easier to keep."
        case .retrieval:
            return tr ? "Seçenek yok, kelimeyi kendin kur. Karışık F-O-X harflerinden 'fox' kelimesini yeniden yaz."
                      : "No options — build the word yourself. Reassemble the scrambled F-O-X into 'fox'."
        case .interleaving:
            return tr ? "İki konuyu karıştır. Her soruda önce hangi konu olduğunu söyle, sonra cevabı ver; asla arka arkaya aynısı gelmez."
                      : "Mix two topics. Each question, first say which topic it is, then answer — never the same one twice in a row."
        case .elaboration:
            return tr ? "Her bilgiye bir 'neden' ekle. 'Çünkü…' diye devam ettir; sebep, bilgiyi hafızaya çıpalar."
                      : "Add a 'why' to each fact. Continue it with 'because…' — the reason anchors it in memory."
        case .story:
            return tr ? "Öğeleri bir zincir hikâyeye bağla: kaplumbağa elmayı kapar, elma bir rokete dönüşür. Sıra hikâyede saklı."
                      : "Link items into a chain story: the turtle grabs the apple, the apple turns into a rocket. The order lives in the tale."
        case .numberShape:
            return tr ? "Her rakamı benzediği bir şekle çevir. Örneğin 2 bir kuğuya benzer; sayıyı şekillerin hikâyesi olarak hatırla."
                      : "Turn each digit into a look-alike shape. A 2 looks like a swan — remember the number as a story of shapes."
        }
    }

    /// The most natural system voice for the current language. Prefers higher
    /// quality (premium > enhanced > default) and avoids the novelty voices, so
    /// once the player downloads an Enhanced/Premium voice in iOS Settings it is
    /// used automatically — the compact default is only a fallback.
    private static func voice(for locale: Locale) -> AVSpeechSynthesisVoice? {
        let lang = locale.language.languageCode?.identifier
            ?? Locale.current.language.languageCode?.identifier
            ?? "en"
        let matches = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(lang) }
        // Drop the joke/novelty voices (Zarvox, Bubbles…) that live under
        // "speech.synthesis.voice"; keep the real spoken voices.
        let real = matches.filter { !$0.identifier.contains("speech.synthesis.voice") }
        let pool = real.isEmpty ? matches : real
        return pool.max { $0.quality.rawValue < $1.quality.rawValue }
            ?? AVSpeechSynthesisVoice(language: lang)
    }
}
