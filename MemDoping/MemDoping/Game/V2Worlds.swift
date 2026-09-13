//
//  V2Worlds.swift
//  MemDoping
//
//  The V2 "worlds" model: three age worlds, each with three scenes, wrapped in
//  the six-phase flow with a story arc. A separate V2 entry — it does NOT touch
//  the 100-level ladder.
//
//  Every scene plays one of the app's existing mechanics. Each of those has real
//  research behind it (see GameLevel.techniqueScience), so the worlds are a
//  presentation layer, not a new claim.
//

import SwiftUI

/// The six-phase mission flow the V2 spec targets (§4).
enum V2Phase: String, CaseIterable {
    case hook = "Kanca", tutorial = "Anlatım", play = "Oyun"
    case challenge = "Tempo", recall = "Geri Çağır", reward = "Ödül"
}

struct V2Scene: Identifiable {
    let id = UUID()
    let title: LocalizedStringKey
    /// The technique's own name — shown to the player.
    let tech: LocalizedStringKey
    /// The mechanic that plays this scene.
    let mechanic: LevelMechanic
    /// Which ladder level supplies the content and difficulty for this scene.
    let sourceLevel: Int
    let hook: LocalizedStringKey
    let obj: String   // emoji object shown in the hook
}

struct V2World: Identifiable {
    let id: String
    let label: LocalizedStringKey
    let hint: LocalizedStringKey
    let band: GameStore.AgeBand
    let sky: [Color]
    /// One story line per scene.
    let arc: [LocalizedStringKey]
    let scenes: [V2Scene]
}

enum V2Content {
    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r, green: g, blue: b)
    }

    static let worlds: [V2World] = [
        V2World(
            id: "child", label: "Child", hint: "Forest School · slow · big", band: .child,
            sky: [rgb(0.99, 0.47, 0.54), rgb(1.0, 0.71, 0.36), rgb(1.0, 0.85, 0.54)],
            arc: ["Fox Efe filled the barn but forgot what went where.",
                  "Let's build a picture to remember — the odder the better.",
                  "Looking isn't enough. You have to decide something."],
            scenes: [
                V2Scene(title: "The Barn", tech: "Method of Loci", mechanic: .loci,
                        sourceLevel: 9, hook: "Walk the barn, remember what went where.", obj: "🏠"),
                V2Scene(title: "Make a Scene", tech: "Association & Imagery", mechanic: .scene,
                        sourceLevel: 3, hook: "The odd one sticks.", obj: "🎨"),
                V2Scene(title: "Look Closer", tech: "Attention & Encoding", mechanic: .pairRecall,
                        sourceLevel: 1, hook: "Just looking isn't enough.", obj: "👀")
            ]),
        V2World(
            id: "teen", label: "Teen", hint: "Signal · fast · combo", band: .teen,
            sky: [rgb(0.00, 0.06, 0.29), rgb(0.01, 0.13, 0.48), rgb(0.02, 0.32, 0.76)],
            arc: ["A nine-digit code is coming. Group it or lose it.",
                  "Decoded — but there's no list. You produce it yourself.",
                  "Two channels are mixed. Which is which?"],
            scenes: [
                V2Scene(title: "Group It", tech: "Chunking", mechanic: .chunking,
                        sourceLevel: 2, hook: "Nine digits. Fifteen seconds.", obj: "🔐"),
                V2Scene(title: "Say It Yourself", tech: "Retrieval Practice", mechanic: .retrieval,
                        sourceLevel: 5, hook: "No options. You produce it.", obj: "🔓"),
                V2Scene(title: "Mix It Up", tech: "Interleaving", mechanic: .interleaving,
                        sourceLevel: 7, hook: "Two channels are mixed.", obj: "🌀")
            ]),
        V2World(
            id: "adult", label: "Adult", hint: "Archive · restrained · strategic", band: .adult,
            sky: [rgb(0.00, 0.06, 0.29), rgb(0.04, 0.16, 0.31), rgb(0.42, 0.36, 0.24)],
            arc: ["Every record in the archive hides a 'why'.",
                  "Let's chain the scattered records into one line.",
                  "Yesterday's records are due. Did they survive?"],
            scenes: [
                V2Scene(title: "Why Is That?", tech: "Elaboration", mechanic: .elaboration,
                        sourceLevel: 10, hook: "Every record hides a 'why'.", obj: "📚"),
                V2Scene(title: "The Chain", tech: "Story Linking", mechanic: .story,
                        sourceLevel: 11, hook: "Chain the records into one line.", obj: "🔗"),
                V2Scene(title: "Secret Code", tech: "Number Shapes", mechanic: .numberShape,
                        sourceLevel: 12, hook: "Every digit has a shape.", obj: "🔢")
            ])
    ]
}
