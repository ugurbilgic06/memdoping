//
//  LadderWorlds.swift
//  MemDoping
//
//  The 100-level ladder, framed with the V2 template: five story worlds of
//  twenty levels each. This is a presentation layer — no level's mechanic,
//  content or order changes. Opening the app shows five worlds instead of a
//  hundred rows, and each world carries a story arc the way a V2 scene does.
//
//  Worlds are chapters everyone plays, not audience tracks: the age band keeps
//  doing what it already did — shifting tone and difficulty (see ageOffset) —
//  so a child still has all 100 levels ahead of them.
//

import SwiftUI

struct LadderWorld: Identifiable, Hashable {
    let id: Int
    let title: LocalizedStringKey
    let emoji: String
    /// One line of story, in the spirit of the V2 world arcs.
    let arc: LocalizedStringKey
    let range: ClosedRange<Int>

    /// The world's own colour, from the house palette. The indices are picked
    /// by hand so all five differ — a plain stride lands on red twice.
    var tint: Color {
        let wheelIndex = [0, 1, 2, 4, 5]   // red, blue, orange, green, pink
        return Brand.houseColor(wheelIndex[id % wheelIndex.count])
    }

    // Identity is the id; LocalizedStringKey isn't Hashable, so synthesis fails.
    static func == (a: LadderWorld, b: LadderWorld) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static let all: [LadderWorld] = [
        LadderWorld(id: 0, title: "First Steps", emoji: "🌱",
                    arc: "You're just looking around. Notice things — that alone changes what stays.",
                    range: 1...20),
        LadderWorld(id: 1, title: "The Workshop", emoji: "🧭",
                    arc: "You start building: pictures, groups, small tricks that hold more than they should.",
                    range: 21...40),
        LadderWorld(id: 2, title: "The Palace", emoji: "🏛️",
                    arc: "Rooms and routes become storage. You learn to walk your memory, not search it.",
                    range: 41...60),
        LadderWorld(id: 3, title: "Deep Water", emoji: "🌊",
                    arc: "Topics mix and the easy answers stop working. Choosing the right method is the skill now.",
                    range: 61...80),
        LadderWorld(id: 4, title: "The Summit", emoji: "👑",
                    arc: "Everything you've built, used together — longer, faster, and from memory alone.",
                    range: 81...100)
    ]

    static func containing(_ levelIndex: Int) -> LadderWorld? {
        all.first { $0.range.contains(levelIndex) }
    }

    /// What this world trains and what it's good for, written for the chosen
    /// audience: concrete and playful for a child, exam-shaped for a teen,
    /// work-and-life for an adult. The band is picked once at the entry, so
    /// this is the line that makes that choice visible everywhere after it.
    func blurb(for band: GameStore.AgeBand?) -> LocalizedStringKey {
        switch (id, band ?? .teen) {

        case (0, .child): return "Learning to really look. You'll start remembering where you left your things and what was just said to you."
        case (0, .teen):  return "Attention first: fewer re-reads, and less of that 'I studied it but it's gone' feeling."
        case (0, .adult): return "Attention and encoding: names at a meeting, where the keys went, what was just said."

        case (1, .child): return "Turning things into pictures and groups — word lists and numbers get much easier."
        case (1, .teen):  return "Images and chunks: vocabulary, formulas and codes, stored in far fewer pieces."
        case (1, .adult): return "Imagery and chunking: phone numbers, IBANs and terminology, held with less effort."

        case (2, .child): return "Using your own room as a memory map — perfect for things you must say in order."
        case (2, .teen):  return "Put your notes in rooms: exam points come back in order, without the notes."
        case (2, .adult): return "Rooms as storage: give a talk without notes, keep a list of errands in order."

        case (3, .child): return "Mixing topics and asking 'why'. Harder right now — that's why it stays longer."
        case (3, .teen):  return "Mixed practice and 'why' questions — this is what separates knowing from recognising."
        case (3, .adult): return "Mix topics and reason about them: pick the right method when it actually matters."

        case (4, .child): return "Everything you've learned, used together in longer games. You'll surprise yourself."
        case (4, .teen):  return "All of it at once — longer, faster, and with nothing in front of you."
        case (4, .adult): return "Every technique combined: long lists, numbers and sequences, from memory alone."

        default: return arc
        }
    }
}
