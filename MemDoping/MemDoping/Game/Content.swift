//
//  Content.swift
//  MemDoping
//
//  Sample game content and level definitions for the vertical-slice prototype.
//
//  NOTE: All content in this file is clearly-labeled SAMPLE content used to
//  demonstrate the core loop (Play -> Learn -> Remember -> Level Up). It is NOT
//  a final, evidence-reviewed curriculum. See MemDoping_Master_Project.md §3.
//

import Foundation

/// A single item to memorize: a symbol paired with a word.
/// The "association & imagery" technique links the picture to the word.
struct MemoryPair: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let word: String
}

/// A themed deck of memory pairs. Themes make the sample content approachable
/// for children and adults alike.
struct MemoryTheme: Identifiable, Hashable {
    let id: String
    let title: String
    let pairs: [MemoryPair]
}

/// One playable level. Difficulty is expressed as data (§7 adaptive difficulty):
/// more items, more choices, and shorter memorize windows mean greater learning
/// demand — not merely tighter timers.
struct GameLevel: Identifiable, Hashable {
    let index: Int              // 1-based position in the ladder
    let title: String
    let technique: String       // research candidate technique being practiced
    let tip: String             // one guided rule at a time
    let itemCount: Int          // pairs shown in the Learn phase
    let questionCount: Int      // recall questions asked
    let choiceCount: Int        // answer options per question (incl. correct)
    let memorizeSeconds: Int    // Learn-phase window
    let theme: MemoryTheme

    var id: Int { index }

    /// Accuracy required to master this level and unlock the next one.
    var masteryPercent: Double { 0.6 }
}

// MARK: - Sample themed decks  (SAMPLE CONTENT — not final curriculum)

enum SampleContent {

    static let animals = MemoryTheme(
        id: "animals",
        title: "Animals",
        pairs: [
            .init(symbol: "🦊", word: "Fox"),
            .init(symbol: "🐢", word: "Turtle"),
            .init(symbol: "🦉", word: "Owl"),
            .init(symbol: "🐝", word: "Bee"),
            .init(symbol: "🐙", word: "Octopus"),
            .init(symbol: "🦒", word: "Giraffe"),
            .init(symbol: "🐧", word: "Penguin"),
            .init(symbol: "🦋", word: "Butterfly")
        ]
    )

    static let food = MemoryTheme(
        id: "food",
        title: "Food",
        pairs: [
            .init(symbol: "🍎", word: "Apple"),
            .init(symbol: "🥑", word: "Avocado"),
            .init(symbol: "🍇", word: "Grapes"),
            .init(symbol: "🥕", word: "Carrot"),
            .init(symbol: "🧀", word: "Cheese"),
            .init(symbol: "🍯", word: "Honey"),
            .init(symbol: "🥨", word: "Pretzel"),
            .init(symbol: "🍉", word: "Melon")
        ]
    )

    static let space = MemoryTheme(
        id: "space",
        title: "Space",
        pairs: [
            .init(symbol: "🚀", word: "Rocket"),
            .init(symbol: "🪐", word: "Saturn"),
            .init(symbol: "🌙", word: "Moon"),
            .init(symbol: "☄️", word: "Comet"),
            .init(symbol: "🛰️", word: "Satellite"),
            .init(symbol: "🌟", word: "Star"),
            .init(symbol: "👩‍🚀", word: "Astronaut"),
            .init(symbol: "🌌", word: "Galaxy")
        ]
    )

    static let travel = MemoryTheme(
        id: "travel",
        title: "Travel",
        pairs: [
            .init(symbol: "🧳", word: "Suitcase"),
            .init(symbol: "🗺️", word: "Map"),
            .init(symbol: "🏝️", word: "Island"),
            .init(symbol: "🚂", word: "Train"),
            .init(symbol: "🎫", word: "Ticket"),
            .init(symbol: "🧭", word: "Compass"),
            .init(symbol: "⛺️", word: "Tent"),
            .init(symbol: "🏔️", word: "Mountain")
        ]
    )
}

// MARK: - Sample level ladder  (design stages of §3, simple -> complex)

enum SampleLevels {

    /// The ordered ladder players climb. Stages 1-5 of the master brief are
    /// expressed here as growing item counts, choice counts, and shorter windows.
    static let all: [GameLevel] = [
        GameLevel(
            index: 1,
            title: "First Links",
            technique: "Association & Imagery",
            tip: "Picture the symbol doing something with its word. Silly images stick.",
            itemCount: 3, questionCount: 3, choiceCount: 3, memorizeSeconds: 12,
            theme: SampleContent.animals
        ),
        GameLevel(
            index: 2,
            title: "Warm Up",
            technique: "Association & Imagery",
            tip: "Look at each pair for a beat, then move on. Trust the picture.",
            itemCount: 4, questionCount: 4, choiceCount: 3, memorizeSeconds: 14,
            theme: SampleContent.food
        ),
        GameLevel(
            index: 3,
            title: "Fewer Hints",
            technique: "Retrieval Practice",
            tip: "Actively pulling an answer from memory strengthens it more than re-reading.",
            itemCount: 5, questionCount: 5, choiceCount: 4, memorizeSeconds: 14,
            theme: SampleContent.space
        ),
        GameLevel(
            index: 4,
            title: "Hold It Longer",
            technique: "Retrieval Practice",
            tip: "A short delay before recall makes the memory work — and last.",
            itemCount: 6, questionCount: 5, choiceCount: 4, memorizeSeconds: 13,
            theme: SampleContent.travel
        ),
        GameLevel(
            index: 5,
            title: "Mixed Field",
            technique: "Interleaving",
            tip: "Switching between items keeps your brain choosing the right link.",
            itemCount: 6, questionCount: 6, choiceCount: 4, memorizeSeconds: 12,
            theme: SampleContent.animals
        ),
        GameLevel(
            index: 6,
            title: "On Your Own",
            technique: "Independent Strategy",
            tip: "Pick whichever memory trick fits each pair. You lead now.",
            itemCount: 7, questionCount: 6, choiceCount: 4, memorizeSeconds: 11,
            theme: SampleContent.space
        )
    ]

    static func level(at index: Int) -> GameLevel? {
        all.first { $0.index == index }
    }
}
