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
    /// Build a vivid mental image for each pair by choosing a modifier, then
    /// recall (T02 Association & Imagery — the active "Canlı Sahne" version).
    case scene
    /// Mix 2-3 themes in one mission; each question first asks the category,
    /// then the answer — never two of the same theme in a row (T06 Interleaving).
    case interleaving
    /// Pick the plausible "why" for a fact, then recall which reason went with
    /// which fact (T07 Elaboration — "Neden Böyle?").
    case elaboration
    /// Link items into a chain story with action cards, then recall the order
    /// (T08 Story Linking — serial recall).
    case story
    /// Turn each digit into a shape image, memorize a number as shapes, then
    /// type it back (T11 Number-Shape System). Evidence is weak — sample only.
    case numberShape
}

/// A fact plus the reason behind it, for elaborative interrogation (T07).
/// Best for familiar, factual material where the player has some background —
/// its benefit is conditional (Dunlosky et al. 2013 rated it moderate).
struct WhyFact: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let subject: String        // the fact, e.g. "Owls hunt at night"
    let because: String        // the plausible reason
    let wrong: [String]        // implausible reasons, for the elaborate step
}

/// A themed set of why-facts.
struct WhyDeck: Identifiable, Hashable {
    let id: String
    let title: String
    let facts: [WhyFact]
}

/// A vivid modifier the player attaches to an item to build a memorable scene
/// (T02). Deliberately silly — odd images stick better.
struct SceneModifier: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let text: String   // resolved via localizedContent; reads as "<word> <text>"
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
    /// The themes mixed together in an Interleaving level. nil for other
    /// mechanics (which use the single `theme`).
    var interleavedThemes: [MemoryTheme]? = nil
    /// The fact set an Elaboration level uses. nil for other mechanics.
    var whyDeck: WhyDeck? = nil

    var id: Int { index }

    /// Accuracy required to master this level and unlock the next one.
    var masteryPercent: Double { 0.6 }

    /// How much a correct answer here counts toward the Memory Score (§2
    /// "comparable tasks"). Free recall and reconstruction demand more than
    /// multiple-choice recognition, so they weigh more — independent of
    /// choiceCount, which is 0 for the non-recognition mechanics.
    var memoryDifficulty: Double {
        switch mechanic {
        case .pairRecall, .scene:
            // Recognition recall; scene building enriches encoding but the test
            // is still multiple-choice. A little harder with more distractors.
            return min(0.75, 0.5 + Double(max(0, choiceCount - 2)) * 0.08)
        case .elaboration:
            // Reason about a fact, then recognise which reason it was.
            return min(0.78, 0.55 + Double(max(0, choiceCount - 2)) * 0.08)
        case .chunking:  return 0.80   // reproduce a number from grouped memory
        case .interleaving: return 0.85   // discriminate category, then recall
        case .story:     return 0.88   // serial recall of a linked sequence
        case .numberShape: return 0.82 // reproduce a digit sequence via shapes
        case .loci:      return 0.90   // serial reconstruction along a route
        case .retrieval: return 0.95   // free recall — produce every letter
        }
    }

    /// Returns a copy with adjusted gameplay parameters (for adaptive difficulty,
    /// §7). Identity, mechanic and content are preserved.
    func varying(itemCount: Int, questionCount: Int, choiceCount: Int, memorizeSeconds: Int) -> GameLevel {
        GameLevel(
            index: index, title: title, technique: technique, tip: tip,
            itemCount: itemCount, questionCount: questionCount,
            choiceCount: choiceCount, memorizeSeconds: memorizeSeconds,
            theme: theme, mechanic: mechanic, orientingDepth: orientingDepth,
            route: route, interleavedThemes: interleavedThemes, whyDeck: whyDeck
        )
    }
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

    /// Classic number-shape pegs (T11): each digit maps to an object that looks
    /// like the digit. Language-independent (shape, not rhyme). Index = digit.
    static let numberShapes: [String] = ["🥚", "🕯️", "🦢", "❤️", "⛵", "🐍", "🍒", "🚩", "⛄", "🎈"]
    static let numberShapeNames: [String] = ["Egg", "Candle", "Swan", "Heart", "Sailboat", "Snake", "Cherry", "Flag", "Snowman", "Balloon"]

    /// Vivid modifiers for building associations (T02). Read as "<word> <text>".
    static let sceneModifiers: [SceneModifier] = [
        .init(emoji: "🔥", text: "is on fire"),
        .init(emoji: "🧊", text: "is frozen solid"),
        .init(emoji: "🌈", text: "is glowing"),
        .init(emoji: "🦣", text: "is enormous"),
        .init(emoji: "🐜", text: "is tiny"),
        .init(emoji: "🤸", text: "is bouncing"),
        .init(emoji: "💃", text: "is dancing"),
        .init(emoji: "🌀", text: "is spinning"),
        .init(emoji: "🎈", text: "is floating"),
        .init(emoji: "😱", text: "is screaming")
    ]

    /// A soft, familiar deck for Night Doping — the calm, untimed mode (§4).
    static let nightCalm = MemoryTheme(
        id: "night",
        title: "Calm",
        deepQuestion: "Is it peaceful?",
        pairs: [
            .init(symbol: "🌙", word: "Moon", deepAnswer: true),
            .init(symbol: "⭐️", word: "Star", deepAnswer: true),
            .init(symbol: "🌊", word: "Wave", deepAnswer: true),
            .init(symbol: "🕯️", word: "Candle", deepAnswer: true),
            .init(symbol: "🍵", word: "Tea", deepAnswer: true),
            .init(symbol: "☁️", word: "Cloud", deepAnswer: true),
            .init(symbol: "🛏️", word: "Bed", deepAnswer: true),
            .init(symbol: "📖", word: "Book", deepAnswer: true)
        ]
    )

    /// Vivid linking actions for chain stories (T08). Read as "<A> <action> <B>".
    static let storyActions: [String] = [
        "chased", "swallowed", "hugged", "jumped over", "carried",
        "painted", "tickled", "followed", "kicked", "threw"
    ]

    /// Everyday "why" facts — familiar enough that most players have some
    /// background, which is where elaboration works best (T07).
    static let whyEveryday = WhyDeck(
        id: "why-everyday",
        title: "Everyday Why",
        facts: [
            .init(symbol: "🦉", subject: "Owls hunt at night",
                  because: "their eyes see well in the dark",
                  wrong: ["they are afraid of the sun", "they like the colour black"]),
            .init(symbol: "🐫", subject: "Camels cross deserts",
                  because: "their humps store fat for energy",
                  wrong: ["they drink lots of coffee", "they dislike shade"]),
            .init(symbol: "🐝", subject: "Bees visit flowers",
                  because: "they gather nectar to make honey",
                  wrong: ["they enjoy the smell", "flowers tell them jokes"]),
            .init(symbol: "🧊", subject: "Ice floats on water",
                  because: "it is less dense than liquid water",
                  wrong: ["it is scared of the bottom", "water only lifts cubes"]),
            .init(symbol: "🌵", subject: "Cacti have spines, not leaves",
                  because: "spines lose less water in the heat",
                  wrong: ["to look a bit scary", "they forgot to grow leaves"]),
            .init(symbol: "🦇", subject: "Bats fly in the dark",
                  because: "they use sound to find their way",
                  wrong: ["the moon guides them home", "they dislike birds"]),
            .init(symbol: "🥶", subject: "We shiver when cold",
                  because: "trembling muscles make heat",
                  wrong: ["our body is dancing", "cold makes us sleepy"]),
            .init(symbol: "🌙", subject: "The moon changes shape",
                  because: "sunlight lights different parts as it orbits",
                  wrong: ["clouds nibble part of it", "it shrinks when tired"])
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
            tip: "Pick a wild twist for each item and picture it — the sillier the scene, the better it sticks.",
            itemCount: 3, questionCount: 3, choiceCount: 3, memorizeSeconds: 0,
            theme: SampleContent.animals,
            mechanic: .scene
        ),
        GameLevel(
            index: 4,
            title: "Make a Scene",
            technique: "Association & Imagery",
            tip: "You build the image now. Choose the twist that makes you smile — that's the one you'll remember.",
            itemCount: 4, questionCount: 4, choiceCount: 3, memorizeSeconds: 0,
            theme: SampleContent.food,
            mechanic: .scene
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
            tip: "Two categories, shuffled together. Spot the category first, then the word. Feeling harder is the point — it's working.",
            itemCount: 6, questionCount: 6, choiceCount: 3, memorizeSeconds: 0,
            theme: SampleContent.animals,
            mechanic: .interleaving,
            interleavedThemes: [SampleContent.animals, SampleContent.food]
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
        ),
        GameLevel(
            index: 10,
            title: "Why Is That?",
            technique: "Elaboration",
            tip: "Don't just take a fact — ask why it's true. Reasons you build yourself are easier to recall. Works best on things you already know a little about.",
            itemCount: 5, questionCount: 5, choiceCount: 3, memorizeSeconds: 0,
            theme: SampleContent.animals,   // unused by this mechanic
            mechanic: .elaboration,
            whyDeck: SampleContent.whyEveryday
        ),
        GameLevel(
            index: 11,
            title: "Chain Story",
            technique: "Story Linking",
            tip: "Don't memorize a list — tie the items into one silly story. A story you built brings the order back for you.",
            itemCount: 4, questionCount: 4, choiceCount: 3, memorizeSeconds: 0,
            theme: SampleContent.animals,
            mechanic: .story
        ),
        GameLevel(
            index: 12,
            title: "Secret Code",
            technique: "Number Shapes",
            tip: "Every digit has a shape — 1 is a candle, 2 a swan, 8 a snowman. Don't memorize the number; picture the shapes.",
            itemCount: 4, questionCount: 4, choiceCount: 0, memorizeSeconds: 15,
            theme: SampleContent.animals,   // unused by this mechanic
            mechanic: .numberShape
        )
    ]

    static func level(at index: Int) -> GameLevel? {
        all.first { $0.index == index }
    }
}
