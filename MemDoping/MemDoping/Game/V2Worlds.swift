//
//  V2Worlds.swift
//  MemDoping
//
//  The V2 "worlds" model (from docs/v2/V2_Demo.html): three age worlds, each
//  with three PACER-typed scenes, wrapped in the six-phase flow with a story
//  arc. This is a separate V2 entry — it does NOT touch the 100-level ladder.
//  Scenes reuse the existing 12 mechanics where one fits; the new PACER-only
//  ones (triage / evidence) are marked and land later.
//

import SwiftUI

/// The six-phase mission flow the V2 spec targets.
enum V2Phase: String, CaseIterable {
    case hook = "Kanca", tutorial = "Anlatım", play = "Oyun"
    case challenge = "Tempo", recall = "Geri Çağır", reward = "Ödül"
}

/// One PACER type (for the router / caption).
enum PacerType: String { case P, A, C, E, R, triage }

struct V2Scene: Identifiable {
    let id = UUID()
    let title: String
    let tech: String
    let pacer: PacerType
    /// The existing mechanic that plays this scene, if any (nil = PACER-only,
    /// not yet built as a playable mechanic).
    let mechanic: LevelMechanic?
    let hook: String
    let obj: String   // emoji object
}

struct V2World: Identifiable {
    let id: String
    let label: LocalizedStringKey
    let hint: LocalizedStringKey
    let band: GameStore.AgeBand
    let sky: [Color]
    let arc: [String]       // one story line per scene
    let scenes: [V2Scene]
}

enum V2Content {
    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r, green: g, blue: b) }

    static let worlds: [V2World] = [
        V2World(
            id: "child", label: "Child", hint: "Orman Okulu · yavaş · büyük", band: .child,
            sky: [rgb(0.17, 0.71, 0.66), rgb(0.22, 0.77, 0.44), rgb(1.0, 0.77, 0.24)],
            arc: ["🦊 Tilki Efe kış hazırlığını unutmuş. Yardım eder misin?",
                  "🌰 Tohumları bulduk. Şimdi doğru sırayla ekmeliyiz.",
                  "🏠 Ambarı doldurduk. Nereye ne koyduğunu hatırlıyor musun?"],
            scenes: [
                V2Scene(title: "Ayır", tech: "PACER — sınıflandırma", pacer: .triage, mechanic: nil,
                        hook: "Efe'nin notları karışmış!", obj: "📦"),
                V2Scene(title: "Adım Adım", tech: "PACER P — Uygula", pacer: .P, mechanic: .procedure,
                        hook: "Tohumu ekebilir misin?", obj: "🌱"),
                V2Scene(title: "Ambar", tech: "Method of Loci", pacer: .R, mechanic: .loci,
                        hook: "Ambarı gez, nereye ne koyduğunu hatırla.", obj: "🏠")
            ]),
        V2World(
            id: "teen", label: "Teen", hint: "Sinyal · hızlı · combo", band: .teen,
            sky: [rgb(0.17, 0.11, 0.35), rgb(0.43, 0.16, 0.85), rgb(0.05, 0.65, 0.91)],
            arc: ["📡 Kesik kesik sinyaller geliyor. Türlerine ayır, yoksa kaybolur.",
                  "⚡️ Gelen mesaj bir benzetme. Nerede yalan söylüyor?",
                  "🔐 Son blok dokuz haneli. Grupla, yoksa tutamazsın."],
            scenes: [
                V2Scene(title: "Ayır — hızlı tur", tech: "PACER — sınıflandırma", pacer: .triage, mechanic: nil,
                        hook: "5 kanal. Süre işliyor. Seri yap.", obj: "📡"),
                V2Scene(title: "Nerede Kırılıyor", tech: "PACER A — Sorgula", pacer: .A, mechanic: .analogy,
                        hook: "Gelen mesaj: “Akım, borudaki su gibidir.”", obj: "⚡️"),
                V2Scene(title: "Grupla", tech: "Chunking", pacer: .R, mechanic: .chunking,
                        hook: "Son blok: 9 hane, 15 saniye.", obj: "🔐")
            ]),
        V2World(
            id: "adult", label: "Adult", hint: "Arşiv · sade · stratejik", band: .adult,
            sky: [rgb(0.07, 0.16, 0.18), rgb(0.12, 0.31, 0.29), rgb(0.71, 0.51, 0.24)],
            arc: ["📚 Arşiv dağılmış. Önce neyin neyle bağlı olduğunu çıkaralım.",
                  "📊 Bir bulgu var. Tam olarak neyi kanıtlıyor, neyi kanıtlamıyor?",
                  "🪐 Katalog kaydı silinmiş. Kalanından adı sen çıkaracaksın."],
            scenes: [
                V2Scene(title: "Bağlantı Haritası", tech: "PACER C — Haritala", pacer: .C, mechanic: .conceptMap,
                        hook: "Hatırlamak neye bağlı?", obj: "🧠"),
                V2Scene(title: "Neyi Kanıtlıyor", tech: "PACER E — Sakla + Bağla", pacer: .E, mechanic: nil,
                        hook: "Bir bulgu var. Sınırı nerede?", obj: "📊"),
                V2Scene(title: "Kayıp Kayıt", tech: "Retrieval Practice", pacer: .R, mechanic: .retrieval,
                        hook: "Katalog adı silinmiş. Şıksız.", obj: "🪐")
            ])
    ]
}
