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

/// Resolves a content-model string (level titles, technique names, tips,
/// theme words) against Localizable.xcstrings for display. Kept separate from
/// the stored String itself so gameplay matching (e.g. answer == prompt.word)
/// stays keyed on one canonical value regardless of display language.
extension String {
    var localizedContent: String {
        String(localized: String.LocalizationValue(self))
    }
}

/// Which game a level actually plays. Each case has its own session model and
/// screen; the ladder, XP and Memory Score are shared across all of them.
enum LevelMechanic: String, Hashable {
    /// Study symbol/word pairs, then pick the right word (T02/T06/T08).
    case pairRecall
    /// Split a number into groups, hold it, type it back (T03).
    case chunking
    /// Study the deck, then rebuild each word from scrambled letters — free
    /// recall, no options (T04 Retrieval Practice).
    case retrieval
    /// Place items along a familiar route, then walk it back and recall what
    /// was left at each stop (T09 Method of Loci).
    case loci
}

/// One stop along a memory-palace route (e.g. the front door of a home).
struct RouteStop: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let name: String
}

/// A familiar route the player mentally walks. Kept concrete and everyday so
/// it feels known, not abstract (docs/techniques/method-of-loci.md).
struct MemoryRoute: Identifiable, Hashable {
    let id: String
    let title: String
    let stops: [RouteStop]
}

/// How deeply the Learn-phase orienting question makes the player process an
/// item (T01 Attention & Encoding — Craik & Lockhart's levels of processing).
/// See docs/techniques/attention-encoding.md.
enum OrientingDepth: String, Hashable {
    case shallow   // surface form of the word itself
    case medium    // sound-adjacent property
    case deep      // meaning of the thing the word names
}

/// A single item to memorize: a symbol paired with a word.
/// The "association & imagery" technique links the picture to the word.
struct MemoryPair: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let word: String
    /// Answer to the owning theme's `deepQuestion`. A real-world fact, so it
    /// holds regardless of display language (unlike the shallow/medium
    /// questions, which are computed from the localized word at runtime).
    let deepAnswer: Bool
}

/// A themed deck of memory pairs. Themes make the sample content approachable
/// for children and adults alike.
struct MemoryTheme: Identifiable, Hashable {
    let id: String
    let title: String
    /// Semantic yes/no question for the `deep` orienting level. Per-theme
    /// because a single question can't meaningfully span every category.
    let deepQuestion: String
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
    var mechanic: LevelMechanic = .pairRecall
    /// When set, the Learn phase asks a yes/no orienting question per item
    /// (T01) instead of showing the whole deck at once. nil = classic deck.
    var orientingDepth: OrientingDepth? = nil
    /// The route a Method-of-Loci level is walked along. nil for other mechanics.
    var route: MemoryRoute? = nil

    var id: Int { index }

    /// Accuracy required to master this level and unlock the next one.
    var masteryPercent: Double { 0.6 }
}

// MARK: - Sample themed decks  (SAMPLE CONTENT — not final curriculum)

enum SampleContent {

    static let animals = MemoryTheme(
        id: "animals",
        title: "Animals",
        deepQuestion: "Can it fly?",
        pairs: [
            .init(symbol: "🦊", word: "Fox", deepAnswer: false),
            .init(symbol: "🐢", word: "Turtle", deepAnswer: false),
            .init(symbol: "🦉", word: "Owl", deepAnswer: true),
            .init(symbol: "🐝", word: "Bee", deepAnswer: true),
            .init(symbol: "🐙", word: "Octopus", deepAnswer: false),
            .init(symbol: "🦒", word: "Giraffe", deepAnswer: false),
            .init(symbol: "🐧", word: "Penguin", deepAnswer: false),
            .init(symbol: "🦋", word: "Butterfly", deepAnswer: true)
        ]
    )

    static let food = MemoryTheme(
        id: "food",
        title: "Food",
        deepQuestion: "Does it taste sweet?",
        pairs: [
            .init(symbol: "🍎", word: "Apple", deepAnswer: true),
            .init(symbol: "🥑", word: "Avocado", deepAnswer: false),
            .init(symbol: "🍇", word: "Grapes", deepAnswer: true),
            .init(symbol: "🥕", word: "Carrot", deepAnswer: false),
            .init(symbol: "🧀", word: "Cheese", deepAnswer: false),
            .init(symbol: "🍯", word: "Honey", deepAnswer: true),
            .init(symbol: "🥨", word: "Pretzel", deepAnswer: false),
            .init(symbol: "🍉", word: "Melon", deepAnswer: true)
        ]
    )

    static let space = MemoryTheme(
        id: "space",
        title: "Space",
        deepQuestion: "Is it bigger than Earth?",
        pairs: [
            .init(symbol: "🚀", word: "Rocket", deepAnswer: false),
            .init(symbol: "🪐", word: "Saturn", deepAnswer: true),
            .init(symbol: "🌙", word: "Moon", deepAnswer: false),
            .init(symbol: "☄️", word: "Comet", deepAnswer: false),
            .init(symbol: "🛰️", word: "Satellite", deepAnswer: false),
            .init(symbol: "🌟", word: "Star", deepAnswer: true),
            .init(symbol: "👩‍🚀", word: "Astronaut", deepAnswer: false),
            .init(symbol: "🌌", word: "Galaxy", deepAnswer: true)
        ]
    )

    static let travel = MemoryTheme(
        id: "travel",
        title: "Travel",
        deepQuestion: "Can you carry it in a bag?",
        pairs: [
            .init(symbol: "🧳", word: "Suitcase", deepAnswer: false),
            .init(symbol: "🗺️", word: "Map", deepAnswer: true),
            .init(symbol: "🏝️", word: "Island", deepAnswer: false),
            .init(symbol: "🚂", word: "Train", deepAnswer: false),
            .init(symbol: "🎫", word: "Ticket", deepAnswer: true),
            .init(symbol: "🧭", word: "Compass", deepAnswer: true),
            .init(symbol: "⛺️", word: "Tent", deepAnswer: false),
            .init(symbol: "🏔️", word: "Mountain", deepAnswer: false)
        ]
    )

    /// A walk through a familiar home — the starter memory palace.
    static let home = MemoryRoute(
        id: "home",
        title: "Your Home",
        stops: [
            .init(icon: "🚪", name: "Front door"),
            .init(icon: "🛋️", name: "Couch"),
            .init(icon: "🪟", name: "Window"),
            .init(icon: "🍽️", name: "Table"),
            .init(icon: "🛏️", name: "Bed"),
            .init(icon: "🪴", name: "Plant"),
            .init(icon: "🚿", name: "Shower"),
            .init(icon: "📺", name: "TV")
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
            title: "Look Closer",
            technique: "Attention & Encoding",
            tip: "Don't just look — answer the question about each item. Deciding something about a word is what makes it stick.",
            itemCount: 4, questionCount: 4, choiceCount: 3, memorizeSeconds: 0,
            theme: SampleContent.animals,
            orientingDepth: .shallow
        ),
        GameLevel(
            index: 2,
            title: "Group It",
            technique: "Chunking",
            tip: "Your mind holds only a few things at once — but a group counts as one thing. Break the number up and carry fewer pieces.",
            itemCount: 9, questionCount: 3, choiceCount: 0, memorizeSeconds: 15,
            theme: SampleContent.animals,   // unused by this mechanic
            mechanic: .chunking
        ),
        GameLevel(
            index: 3,
            title: "First Links",
            technique: "Association & Imagery",
            tip: "Picture the symbol doing something with its word. Silly images stick.",
            itemCount: 3, questionCount: 3, choiceCount: 3, memorizeSeconds: 12,
            theme: SampleContent.animals
        ),
        GameLevel(
            index: 4,
            title: "Warm Up",
            technique: "Association & Imagery",
            tip: "Look at each pair for a beat, then move on. Trust the picture.",
            itemCount: 4, questionCount: 4, choiceCount: 3, memorizeSeconds: 14,
            theme: SampleContent.food
        ),
        GameLevel(
            index: 5,
            title: "Say It Yourself",
            technique: "Retrieval Practice",
            tip: "No options this time — spell each word from memory. Pulling it out yourself is what makes it last.",
            itemCount: 5, questionCount: 4, choiceCount: 4, memorizeSeconds: 14,
            theme: SampleContent.space,
            mechanic: .retrieval
        ),
        GameLevel(
            index: 6,
            title: "No Peeking",
            technique: "Retrieval Practice",
            tip: "Stuck on a word? Tap Hint for the next letter — it's free. Finishing it yourself still counts.",
            itemCount: 6, questionCount: 5, choiceCount: 4, memorizeSeconds: 13,
            theme: SampleContent.travel,
            mechanic: .retrieval
        ),
        GameLevel(
            index: 7,
            title: "Mixed Field",
            technique: "Interleaving",
            tip: "Switching between items keeps your brain choosing the right link.",
            itemCount: 6, questionCount: 6, choiceCount: 4, memorizeSeconds: 12,
            theme: SampleContent.animals
        ),
        GameLevel(
            index: 8,
            title: "On Your Own",
            technique: "Independent Strategy",
            tip: "Pick whichever memory trick fits each pair. You lead now.",
            itemCount: 7, questionCount: 6, choiceCount: 4, memorizeSeconds: 11,
            theme: SampleContent.space
        ),
        GameLevel(
            index: 9,
            title: "Memory Palace",
            technique: "Method of Loci",
            tip: "Walk your home and leave each item at a spot — picture it vividly there. This isn't a talent; it's a strategy anyone can learn.",
            itemCount: 5, questionCount: 5, choiceCount: 0, memorizeSeconds: 0,
            theme: SampleContent.travel,
            mechanic: .loci,
            route: SampleContent.home
        )
    ]

    static func level(at index: Int) -> GameLevel? {
        all.first { $0.index == index }
    }
}
