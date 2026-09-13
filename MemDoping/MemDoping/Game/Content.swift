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
/// Holds the app's chosen language so both UI strings and content resolve to it,
/// letting the player switch language in-app (nil = follow the system).
enum AppLocale {
    static private(set) var bundle: Bundle = .main
    static private(set) var locale: Locale = .autoupdatingCurrent

    static func apply(_ code: String?) {
        if let code,
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let b = Bundle(path: path) {
            bundle = b
            locale = Locale(identifier: code)
        } else {
            bundle = .main
            locale = .autoupdatingCurrent
        }
    }
}

extension String {
    var localizedContent: String {
        String(localized: String.LocalizationValue(self),
               bundle: AppLocale.bundle, locale: AppLocale.locale)
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
    /// PACER **P** — Procedural. Study a procedure once, then carry it out from
    /// memory in the right order while refusing the steps that don't belong.
    /// A wrong move is corrected on the spot, because feedback is what fixes
    /// procedural knowledge (PACER guide p.3).
    case procedure
    /// PACER **A** — Analogous. Judge an analogy: which parts genuinely map,
    /// and where does it break? The guide is explicit that an analogy is not
    /// the thing itself, so the required operation is critique, not recall
    /// (PACER guide p.4).
    case analogy
    /// PACER **C** — Conceptual. Build a labelled map: connect each idea to the
    /// centre *and name the relation* (causes, increases, requires…), then
    /// recall the relations. Mapping, not a single "why" (PACER guide p.5).
    case conceptMap
}

// MARK: - PACER P — Procedural  (guide p.3, p.11)

/// One move in a procedure. `why` is the corrective shown when the player puts
/// it in the wrong place — the guide treats feedback as the thing that repairs
/// procedural knowledge, so every step has to be able to explain its position.
struct ProcedureStep: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let text: String
    /// Why this step belongs where it does. Shown on a misstep, not up front.
    let why: String
}

/// A procedure the player performs from memory. `traps` are plausible-looking
/// moves that are NOT part of it: knowing what doesn't belong is part of knowing
/// the procedure.
struct Procedure: Identifiable, Hashable {
    let id: String
    let title: String
    let goal: String
    let steps: [ProcedureStep]     // in the one correct order
    let traps: [ProcedureStep]     // plausible, but not part of this procedure
}

// MARK: - PACER A — Analogous  (guide p.4, p.11)

/// One claim about an analogy. `holds == false` marks a point where the
/// comparison stops being true — the guide's "analojinin kırıldığı nokta".
struct AnalogyAspect: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let holds: Bool
}

/// An analogy to be critiqued rather than memorised.
struct Analogy: Identifiable, Hashable {
    let id: String
    let symbol: String
    /// The full comparison as the player meets it.
    let claim: String
    /// Short label for the thing being explained, used in recall prompts.
    let target: String
    let aspects: [AnalogyAspect]
    /// What the analogy still fails to capture — the guide's "could a better
    /// one be built?" beat, shown after the critique.
    let blindSpot: String

    var breakingPoints: [AnalogyAspect] { aspects.filter { !$0.holds } }
    var holdingPoints: [AnalogyAspect] { aspects.filter(\.holds) }
}

// MARK: - PACER C — Conceptual  (guide p.5, p.11)

/// The label on a connection. The guide insists the relation itself is written
/// on the link ("neden olur, artırır, azaltır, gerektirir, örneğidir"), because
/// an unlabelled line carries almost no meaning.
enum RelationKind: String, Hashable, CaseIterable {
    case causes, increases, decreases, requires, exampleOf

    /// Reads as "<from> — <label> — <to>".
    var label: String {
        switch self {
        case .causes:    return "causes"
        case .increases: return "increases"
        case .decreases: return "decreases"
        case .requires:  return "requires"
        case .exampleOf: return "is an example of"
        }
    }

    var icon: String {
        switch self {
        case .causes:    return "arrow.right.circle.fill"
        case .increases: return "arrow.up.circle.fill"
        case .decreases: return "arrow.down.circle.fill"
        case .requires:  return "lock.circle.fill"
        case .exampleOf: return "circle.hexagongrid.circle.fill"
        }
    }
}

/// One idea placed around the centre of a map.
struct ConceptNode: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let name: String
    /// How this node relates to the map's centre.
    let relation: RelationKind
    /// Plain-language note shown after the link is made, so a wrong guess still
    /// teaches the relation instead of only marking it wrong.
    let note: String
}

/// A small concept map: one centre, several labelled spokes.
struct ConceptMapDeck: Identifiable, Hashable {
    let id: String
    let title: String
    let centerIcon: String
    let center: String
    let nodes: [ConceptNode]
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
    /// The procedure a PACER-P level asks the player to carry out. nil elsewhere.
    var procedure: Procedure? = nil
    /// The analogies a PACER-A level critiques. nil elsewhere.
    var analogies: [Analogy]? = nil
    /// The map a PACER-C level builds. nil elsewhere.
    var conceptMap: ConceptMapDeck? = nil

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
        case .analogy:   return 0.80   // judge what holds and what breaks
        case .conceptMap: return 0.86  // recall a labelled relation, not a fact
        case .procedure: return 0.92   // perform the whole order unaided
        }
    }

    /// A short "how this technique works" explanation, shown on the level intro
    /// so players learn the method up front. Honest, no over-claiming (§9).
    var techniqueExplanation: String {
        let key: String
        switch mechanic {
        case .pairRecall:
            key = orientingDepth != nil
                ? "You remember what you think about. Making a small decision about each item forces deeper processing — that's what makes it stick."
                : "Study the pairs, then recall the right word on cue. Pulling a memory up on purpose is what strengthens it."
        case .scene:
            key = "Link two things with a vivid, silly mental picture. An image you build yourself is easier to find again than a plain fact."
        case .chunking:
            key = "Working memory holds only a few things at once — but a group counts as one. Break a long number into small chunks and you carry fewer pieces."
        case .retrieval:
            key = "Pulling an answer out of memory yourself, instead of re-reading it, is one of the strongest ways to make it last. It feels harder — that's the point."
        case .interleaving:
            key = "Mixing categories instead of blocking them trains you to pick the right one each time. Harder now, but it pays off later."
        case .elaboration:
            key = "Ask 'why is this true?' and build an answer. Tying a fact to what you already know gives memory more hooks to grab."
        case .story:
            key = "Chain the items into one short story. The story carries the order for you, so a long list becomes easy to recall in sequence."
        case .loci:
            key = "Place each item along a route you know, then walk it back in your mind. This borrows your powerful spatial memory — a learnable skill, not a talent."
        case .numberShape:
            key = "Every digit has a shape — 1 a candle, 2 a swan. Turning numbers into pictures gives memory something concrete to hold."
        case .procedure:
            key = "Watch it once, then do it yourself. A procedure isn't learned by reading the steps — it's learned by running them and fixing what goes wrong."
        case .analogy:
            key = "A comparison is a shortcut, not the thing itself. Find where it fits, then find exactly where it stops fitting — that edge is the useful part."
        case .conceptMap:
            key = "Don't collect facts — connect them, and say what the connection is. Naming the link is what turns a pile of ideas into something you can think with."
        }
        return key.localizedContent
    }

    /// The plain-language scientific reason the technique works. Honest about
    /// strength (§9) — shown to teens/adults, hidden for the child band.
    var techniqueScience: String {
        let key: String
        switch mechanic {
        case .pairRecall:
            key = orientingDepth != nil
                ? "Backed by 'levels of processing' research: the more meaningfully you handle something, the better you recall it (Craik & Lockhart)."
                : "Recalling on cue is retrieval practice — repeatedly tested material is remembered better."
        case .scene:
            key = "Based on dual coding (Paivio): a word plus an image gives memory two routes to it. A modest, conditional effect."
        case .chunking:
            key = "Working memory holds only about four chunks (Miller; Cowan) — grouping lets you carry more within that limit."
        case .retrieval:
            key = "The testing effect: retrieving a memory strengthens it more than re-reading (Roediger & Karpicke) — one of the most robust findings."
        case .interleaving:
            key = "Mixed practice sharpens choosing the right method — it roughly doubled next-day accuracy in Taylor & Rohrer's study."
        case .elaboration:
            key = "Elaborative interrogation: asking 'why' links facts to what you know. A moderate benefit, best on familiar material."
        case .story:
            key = "Bower & Clark found a story group recalled far more of a list long-term — a striking effect from a classic study."
        case .loci:
            key = "The method of loci borrows your spatial memory. Maguire (2003): memory champions aren't smarter — they use this method."
        case .numberShape:
            key = "It combines chunking and imagery. Direct evidence for the number-shape trick itself is thin — treat it as a handy aid, not a rule."
        case .procedure:
            key = "PACER treats a procedure as something you practise, not store: you only know it once you can run it without looking, and errors plus feedback are what correct it."
        case .analogy:
            key = "PACER pairs analogies with critique, not recall. An analogy that is never tested at its edges quietly becomes a wrong belief."
        case .conceptMap:
            key = "PACER handles concepts by mapping: expertise is less about knowing separate facts than seeing how they connect — so the relation gets written on the link."
        }
        return key.localizedContent
    }

    /// A difficulty-scaled clone at a new index, keeping the mechanic and its
    /// wired content. Used to extend the curated levels into the 100-level
    /// ladder; counts are capped and sessions clamp to available content.
    func scaled(toIndex newIndex: Int, step: Int, theme newTheme: MemoryTheme? = nil) -> GameLevel {
        GameLevel(
            index: newIndex, title: title, technique: technique, tip: tip,
            itemCount: min(8, itemCount + step),
            questionCount: min(8, max(questionCount, questionCount + step / 2)),
            choiceCount: choiceCount == 0 ? 0 : min(5, choiceCount + step / 3),
            memorizeSeconds: memorizeSeconds == 0 ? 0 : max(6, memorizeSeconds - step),
            theme: newTheme ?? theme, mechanic: mechanic, orientingDepth: orientingDepth,
            route: route, interleavedThemes: interleavedThemes, whyDeck: whyDeck,
            procedure: procedure, analogies: analogies, conceptMap: conceptMap
        )
    }

    /// Mechanics whose gameplay reads from the single `theme`, so rotating it
    /// adds image variety across the generated ladder.
    var usesSingleTheme: Bool {
        switch mechanic {
        case .pairRecall, .scene, .retrieval, .story: return true
        default: return false   // chunking/numberShape/loci/elaboration/interleaving
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
            route: route, interleavedThemes: interleavedThemes, whyDeck: whyDeck,
            procedure: procedure, analogies: analogies, conceptMap: conceptMap
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
            .init(symbol: "🦋", word: "Butterfly", deepAnswer: true),
            .init(symbol: "🦁", word: "Lion", deepAnswer: false),
            .init(symbol: "🐬", word: "Dolphin", deepAnswer: false),
            .init(symbol: "🦅", word: "Eagle", deepAnswer: true),
            .init(symbol: "🐘", word: "Elephant", deepAnswer: false),
            .init(symbol: "🦇", word: "Bat", deepAnswer: true),
            .init(symbol: "🐸", word: "Frog", deepAnswer: false)
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
            .init(symbol: "🍉", word: "Melon", deepAnswer: true),
            .init(symbol: "🍓", word: "Strawberry", deepAnswer: true),
            .init(symbol: "🍕", word: "Pizza", deepAnswer: false),
            .init(symbol: "🍫", word: "Chocolate", deepAnswer: true),
            .init(symbol: "🥦", word: "Broccoli", deepAnswer: false),
            .init(symbol: "🍌", word: "Banana", deepAnswer: true),
            .init(symbol: "🍞", word: "Bread", deepAnswer: false)
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
            .init(symbol: "🌌", word: "Galaxy", deepAnswer: true),
            .init(symbol: "☀️", word: "Sun", deepAnswer: true),
            .init(symbol: "🌠", word: "Meteor", deepAnswer: false),
            .init(symbol: "🔭", word: "Telescope", deepAnswer: false),
            .init(symbol: "👽", word: "Alien", deepAnswer: false),
            .init(symbol: "🪨", word: "Asteroid", deepAnswer: false),
            .init(symbol: "🌑", word: "New Moon", deepAnswer: false)
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
            .init(symbol: "🏔️", word: "Mountain", deepAnswer: false),
            .init(symbol: "✈️", word: "Airplane", deepAnswer: false),
            .init(symbol: "📷", word: "Camera", deepAnswer: true),
            .init(symbol: "🛂", word: "Passport", deepAnswer: true),
            .init(symbol: "🕶️", word: "Sunglasses", deepAnswer: true),
            .init(symbol: "🛳️", word: "Ship", deepAnswer: false),
            .init(symbol: "🏨", word: "Hotel", deepAnswer: false)
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

    static let nature = MemoryTheme(
        id: "nature",
        title: "Nature",
        deepQuestion: "Does it grow?",
        pairs: [
            .init(symbol: "🌳", word: "Tree", deepAnswer: true),
            .init(symbol: "🌸", word: "Blossom", deepAnswer: true),
            .init(symbol: "🍄", word: "Mushroom", deepAnswer: true),
            .init(symbol: "🐌", word: "Snail", deepAnswer: false),
            .init(symbol: "🦎", word: "Lizard", deepAnswer: false),
            .init(symbol: "🌻", word: "Sunflower", deepAnswer: true),
            .init(symbol: "🐞", word: "Ladybug", deepAnswer: false),
            .init(symbol: "🍁", word: "Leaf", deepAnswer: true),
            .init(symbol: "🌵", word: "Cactus", deepAnswer: true),
            .init(symbol: "🌴", word: "Palm", deepAnswer: true),
            .init(symbol: "🌊", word: "Wave", deepAnswer: false),
            .init(symbol: "🌿", word: "Herb", deepAnswer: true),
            .init(symbol: "❄️", word: "Snowflake", deepAnswer: false),
            .init(symbol: "☁️", word: "Cloud", deepAnswer: false)
        ]
    )

    static let sports = MemoryTheme(
        id: "sports",
        title: "Sports",
        deepQuestion: "Is it played with a ball?",
        pairs: [
            .init(symbol: "⚽️", word: "Football", deepAnswer: true),
            .init(symbol: "🏀", word: "Basketball", deepAnswer: true),
            .init(symbol: "🎾", word: "Tennis", deepAnswer: true),
            .init(symbol: "🏓", word: "Ping Pong", deepAnswer: true),
            .init(symbol: "🥊", word: "Boxing", deepAnswer: false),
            .init(symbol: "🏹", word: "Archery", deepAnswer: false),
            .init(symbol: "🏊", word: "Swimming", deepAnswer: false),
            .init(symbol: "⛳️", word: "Golf", deepAnswer: true),
            .init(symbol: "🏐", word: "Volleyball", deepAnswer: true),
            .init(symbol: "🏈", word: "Rugby", deepAnswer: true),
            .init(symbol: "⛷️", word: "Skiing", deepAnswer: false),
            .init(symbol: "🚴", word: "Cycling", deepAnswer: false),
            .init(symbol: "🏒", word: "Hockey", deepAnswer: false),
            .init(symbol: "🎳", word: "Bowling", deepAnswer: true)
        ]
    )

    static let vehicles = MemoryTheme(
        id: "vehicles",
        title: "Vehicles",
        deepQuestion: "Does it have wheels?",
        pairs: [
            .init(symbol: "🚗", word: "Car", deepAnswer: true),
            .init(symbol: "🚲", word: "Bicycle", deepAnswer: true),
            .init(symbol: "🚌", word: "Bus", deepAnswer: true),
            .init(symbol: "🏍️", word: "Motorcycle", deepAnswer: true),
            .init(symbol: "🚚", word: "Truck", deepAnswer: true),
            .init(symbol: "🚜", word: "Tractor", deepAnswer: true),
            .init(symbol: "🛹", word: "Skateboard", deepAnswer: true),
            .init(symbol: "🚁", word: "Helicopter", deepAnswer: false),
            .init(symbol: "⛵", word: "Sailboat", deepAnswer: false),
            .init(symbol: "🛶", word: "Canoe", deepAnswer: false)
        ]
    )

    static let music = MemoryTheme(
        id: "music",
        title: "Music",
        deepQuestion: "Do you blow into it?",
        pairs: [
            .init(symbol: "🎸", word: "Guitar", deepAnswer: false),
            .init(symbol: "🎹", word: "Piano", deepAnswer: false),
            .init(symbol: "🥁", word: "Drum", deepAnswer: false),
            .init(symbol: "🎻", word: "Violin", deepAnswer: false),
            .init(symbol: "🪕", word: "Banjo", deepAnswer: false),
            .init(symbol: "🎤", word: "Microphone", deepAnswer: false),
            .init(symbol: "🔔", word: "Bell", deepAnswer: false),
            .init(symbol: "🎺", word: "Trumpet", deepAnswer: true),
            .init(symbol: "🎷", word: "Saxophone", deepAnswer: true),
            .init(symbol: "🪈", word: "Flute", deepAnswer: true)
        ]
    )

    static let ocean = MemoryTheme(
        id: "ocean",
        title: "Ocean",
        deepQuestion: "Does it live in the sea?",
        pairs: [
            .init(symbol: "🐟", word: "Fish", deepAnswer: true),
            .init(symbol: "🐋", word: "Whale", deepAnswer: true),
            .init(symbol: "🦀", word: "Crab", deepAnswer: true),
            .init(symbol: "🦈", word: "Shark", deepAnswer: true),
            .init(symbol: "🦑", word: "Squid", deepAnswer: true),
            .init(symbol: "🪼", word: "Jellyfish", deepAnswer: true),
            .init(symbol: "🐡", word: "Blowfish", deepAnswer: true),
            .init(symbol: "🐚", word: "Seashell", deepAnswer: true),
            .init(symbol: "⚓", word: "Anchor", deepAnswer: false),
            .init(symbol: "🏖️", word: "Beach", deepAnswer: false)
        ]
    )

    static let clothes = MemoryTheme(
        id: "clothes",
        title: "Clothes",
        deepQuestion: "Do you wear it on your feet?",
        pairs: [
            .init(symbol: "👟", word: "Shoe", deepAnswer: true),
            .init(symbol: "🥾", word: "Boot", deepAnswer: true),
            .init(symbol: "🧦", word: "Sock", deepAnswer: true),
            .init(symbol: "🩴", word: "Sandal", deepAnswer: true),
            .init(symbol: "🎩", word: "Hat", deepAnswer: false),
            .init(symbol: "👕", word: "Shirt", deepAnswer: false),
            .init(symbol: "👗", word: "Dress", deepAnswer: false),
            .init(symbol: "🧤", word: "Gloves", deepAnswer: false),
            .init(symbol: "🧣", word: "Scarf", deepAnswer: false),
            .init(symbol: "🧢", word: "Cap", deepAnswer: false)
        ]
    )

    /// Themes rotated across the generated ladder for image variety.
    static let themePool: [MemoryTheme] = [
        animals, food, space, travel, nature, sports, vehicles, music, ocean, clothes
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

    // MARK: - PACER P — procedures  (SAMPLE CONTENT)
    // Everyday procedures where the order is genuinely causal, so a misstep can
    // be explained rather than just marked wrong. Each carries "traps": moves
    // that look reasonable but belong to a different job.

    static let procedures: [Procedure] = [
        Procedure(
            id: "plant-a-seed",
            title: "Plant a Seed",
            goal: "Get a seed into soil so it can actually sprout.",
            steps: [
                .init(icon: "🪴", text: "Fill the pot with soil",
                      why: "Nothing can be planted until there's somewhere to plant it."),
                .init(icon: "🕳️", text: "Make a small hole",
                      why: "The hole has to exist before the seed can go in — you can't dig around a buried seed."),
                .init(icon: "🌰", text: "Drop the seed in",
                      why: "This is the point of the whole job; everything before it is preparation."),
                .init(icon: "🤲", text: "Cover it with soil",
                      why: "An uncovered seed dries out. Cover before watering or the water just washes it away."),
                .init(icon: "💧", text: "Water it",
                      why: "Water comes after covering, so it soaks the soil instead of moving the seed."),
                .init(icon: "☀️", text: "Put it somewhere bright",
                      why: "Light matters once it's planted — moving it earlier changes nothing.")
            ],
            traps: [
                .init(icon: "✂️", text: "Trim the leaves",
                      why: "There are no leaves yet. This belongs to caring for a grown plant."),
                .init(icon: "🧂", text: "Add salt to the soil",
                      why: "Salt harms most plants — this isn't a step in any planting procedure."),
                .init(icon: "🧊", text: "Freeze the seed first",
                      why: "A few species need chilling, but it isn't part of ordinary planting.")
            ]
        ),
        Procedure(
            id: "wash-hands",
            title: "Wash Your Hands",
            goal: "Actually remove what's on your hands, not just rinse them.",
            steps: [
                .init(icon: "🚰", text: "Wet your hands",
                      why: "Soap spreads and lathers on wet skin; on dry hands it mostly smears."),
                .init(icon: "🧼", text: "Apply soap",
                      why: "Soap is what lifts grease and germs — water alone slides past them."),
                .init(icon: "🫧", text: "Scrub for 20 seconds",
                      why: "The scrubbing does the work. This is the step people shorten, and it's the one that matters."),
                .init(icon: "🚿", text: "Rinse thoroughly",
                      why: "Rinsing carries away what the soap lifted. Skip it and it stays on your hands."),
                .init(icon: "🧻", text: "Dry your hands",
                      why: "Damp hands pick up and pass on far more than dry ones.")
            ],
            traps: [
                .init(icon: "🧴", text: "Use hand sanitiser instead",
                      why: "That's a different procedure — a substitute for washing, not a step inside it."),
                .init(icon: "💨", text: "Shake them dry and move on",
                      why: "It leaves hands damp, which undoes part of the work.")
            ]
        ),
        Procedure(
            id: "make-tea",
            title: "Brew a Cup of Tea",
            goal: "Get the flavour out of the leaves without ruining it.",
            steps: [
                .init(icon: "🫖", text: "Boil the water",
                      why: "Hot water is what pulls flavour out; lukewarm water barely extracts anything."),
                .init(icon: "🍵", text: "Put tea in the cup",
                      why: "The tea has to be waiting when the water arrives, so steeping starts at full heat."),
                .init(icon: "💦", text: "Pour the water over it",
                      why: "Pouring over the leaves wets all of them at once — this is where brewing begins."),
                .init(icon: "⏳", text: "Let it steep",
                      why: "Time is the actual extraction. Rushing here is why weak tea is weak."),
                .init(icon: "🥄", text: "Remove the tea",
                      why: "Left too long it turns bitter — taking it out is what stops the process."),
                .init(icon: "🍯", text: "Add milk or sugar if you like",
                      why: "Last, once you can taste what you're adjusting.")
            ],
            traps: [
                .init(icon: "🧊", text: "Add ice to cool it faster",
                      why: "That's iced tea — a different drink, made a different way."),
                .init(icon: "🔁", text: "Boil the tea in the pot",
                      why: "Boiling leaves directly makes tea harsh. Steeping and boiling aren't the same operation.")
            ]
        )
    ]

    // MARK: - PACER A — analogies to critique  (SAMPLE CONTENT)
    // Familiar comparisons that are genuinely useful *and* genuinely leaky. The
    // first is the PACER guide's own worked example (p.4).

    static let analogies: [Analogy] = [
        Analogy(
            id: "current-water",
            symbol: "⚡️",
            claim: "Electric current is like water flowing through a pipe.",
            target: "electric current",
            aspects: [
                .init(text: "A narrower pipe resists flow, like a thin wire resists current", holds: true),
                .init(text: "More pressure pushes more flow, like voltage pushes current", holds: true),
                .init(text: "Both keep flowing in a loop when the path is closed", holds: true),
                .init(text: "Water spills out of an open pipe — current does the same from a cut wire", holds: false),
                .init(text: "You can see and touch the water; the same goes for current", holds: false)
            ],
            blindSpot: "The picture has no room for what electricity actually is — charges pushed along by a field — so it can't explain anything magnetic."
        ),
        Analogy(
            id: "brain-computer",
            symbol: "🧠",
            claim: "The brain is like a computer.",
            target: "the brain",
            aspects: [
                .init(text: "Both take in information, process it and produce output", holds: true),
                .init(text: "Both can hold something briefly while working on it", holds: true),
                .init(text: "The brain stores a memory in one place and reads it back unchanged", holds: false),
                .init(text: "Its parts can be swapped out one at a time, like components", holds: false),
                .init(text: "Deleting something removes it cleanly, as deleting a file does", holds: false)
            ],
            blindSpot: "Remembering rebuilds the memory each time and changes it a little — the opposite of reading a file, which is the whole point of the comparison."
        ),
        Analogy(
            id: "eye-camera",
            symbol: "👁️",
            claim: "The eye is like a camera.",
            target: "the eye",
            aspects: [
                .init(text: "A lens focuses light onto a surface at the back", holds: true),
                .init(text: "An opening widens and narrows to control how much light enters", holds: true),
                .init(text: "It captures a whole sharp image at once, like a photo", holds: false),
                .init(text: "What you see is the picture exactly as it landed", holds: false)
            ],
            blindSpot: "Only a tiny patch of what you see is sharp. The steady, detailed scene in your head is assembled by the brain from darting glances."
        ),
        Analogy(
            id: "atom-solar-system",
            symbol: "⚛️",
            claim: "An atom is like a tiny solar system.",
            target: "an atom",
            aspects: [
                .init(text: "Something heavy sits at the centre with lighter things around it", holds: true),
                .init(text: "Most of it is empty space", holds: true),
                .init(text: "Electrons travel neat orbits, the way planets do", holds: false),
                .init(text: "You could say where an electron is at a given moment", holds: false)
            ],
            blindSpot: "Electrons don't have paths to point at — only regions where they're likely to be. The orbit picture is the part every physics course has to undo later."
        )
    ]

    // MARK: - PACER C — concept maps  (SAMPLE CONTENT)
    // Small maps where the *relation* carries the meaning, so an unlabelled line
    // would say almost nothing.

    static let conceptMaps: [ConceptMapDeck] = [
        ConceptMapDeck(
            id: "memory-map",
            title: "What Holds a Memory",
            centerIcon: "🧠",
            center: "Remembering",
            nodes: [
                .init(icon: "😴", name: "Sleep", relation: .requires,
                      note: "Memories are consolidated during sleep — lose the sleep and you lose part of the day's learning."),
                .init(icon: "🎯", name: "Attention", relation: .requires,
                      note: "Nothing can be recalled that was never encoded, and encoding starts with attending."),
                .init(icon: "🔁", name: "Retrieval practice", relation: .increases,
                      note: "Pulling something up strengthens it — more than reading it again does."),
                .init(icon: "😰", name: "Stress", relation: .decreases,
                      note: "High stress crowds working memory, leaving less room to hold and link things."),
                .init(icon: "📱", name: "Divided attention", relation: .decreases,
                      note: "Splitting attention weakens encoding, so there's less to retrieve later."),
                .init(icon: "🏰", name: "Method of loci", relation: .exampleOf,
                      note: "It's one specific technique for remembering, not a separate kind of memory.")
            ]
        ),
        ConceptMapDeck(
            id: "plant-map",
            title: "What a Plant Needs",
            centerIcon: "🌱",
            center: "Plant growth",
            nodes: [
                .init(icon: "☀️", name: "Sunlight", relation: .requires,
                      note: "Photosynthesis is powered by light — without it the plant cannot make food."),
                .init(icon: "💧", name: "Water", relation: .requires,
                      note: "Water carries nutrients up the plant and keeps its cells firm."),
                .init(icon: "🌡️", name: "Warmth", relation: .increases,
                      note: "Growth speeds up with warmth, up to a point — then heat starts to harm."),
                .init(icon: "🧂", name: "Salty soil", relation: .decreases,
                      note: "Salt pulls water out of roots, so the plant struggles even when watered."),
                .init(icon: "🍂", name: "Shade from taller plants", relation: .decreases,
                      note: "Less light reaching the leaves means less food made."),
                .init(icon: "🌻", name: "A sunflower", relation: .exampleOf,
                      note: "A specific plant, not a condition for growth — examples sit on a different kind of link.")
            ]
        ),
        ConceptMapDeck(
            id: "forgetting-map",
            title: "Why Things Slip Away",
            centerIcon: "🌫️",
            center: "Forgetting",
            nodes: [
                .init(icon: "⏳", name: "Time without review", relation: .causes,
                      note: "Untouched memories fade — the classic forgetting curve."),
                .init(icon: "🔀", name: "Similar memories", relation: .causes,
                      note: "Close-but-different memories interfere with each other and blur."),
                .init(icon: "📅", name: "Spaced review", relation: .decreases,
                      note: "Revisiting at widening intervals flattens the curve."),
                .init(icon: "🔗", name: "Meaningful links", relation: .decreases,
                      note: "More hooks into what you already know means more ways back to it."),
                .init(icon: "🫥", name: "Blanking in an exam", relation: .exampleOf,
                      note: "One instance of forgetting, not a cause of it.")
            ]
        )
    ]
}

// MARK: - Sample level ladder  (design stages of §3, simple -> complex)

enum SampleLevels {

    /// Hand-crafted opening levels — each introduces a technique with its own
    /// tip. The full 100-level ladder (`all`) extends these by cycling the
    /// mechanics with a rising difficulty curve.
    static let curated: [GameLevel] = [
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
        ),
        // PACER P / A / C. Appended after the existing twelve so no level below
        // is renumbered — a player's saved highestUnlockedLevel keeps its meaning.
        GameLevel(
            index: 13,
            title: "Do It Yourself",
            technique: "Procedural — Practice",
            tip: "Watch once, then run it from memory. Getting a step wrong is fine — that's how a procedure gets corrected.",
            itemCount: 5, questionCount: 5, choiceCount: 0, memorizeSeconds: 16,
            theme: SampleContent.animals,   // unused by this mechanic
            mechanic: .procedure,
            procedure: SampleContent.procedures[0]
        ),
        GameLevel(
            index: 14,
            title: "Where It Breaks",
            technique: "Analogous — Critique",
            tip: "Every comparison fits somewhere and fails somewhere. Find both — the failure is the part worth knowing.",
            itemCount: 2, questionCount: 3, choiceCount: 3, memorizeSeconds: 0,
            theme: SampleContent.animals,   // unused by this mechanic
            mechanic: .analogy,
            analogies: SampleContent.analogies
        ),
        GameLevel(
            index: 15,
            title: "Map It",
            technique: "Conceptual — Mapping",
            tip: "Connect each idea to the centre and say what the link is. The label is the knowledge — an unnamed line tells you nothing.",
            itemCount: 5, questionCount: 4, choiceCount: 3, memorizeSeconds: 0,
            theme: SampleContent.animals,   // unused by this mechanic
            mechanic: .conceptMap,
            conceptMap: SampleContent.conceptMaps[0]
        )
    ]

    /// The full 100-level ladder: the curated levels, then difficulty-scaled
    /// clones that cycle through every mechanic. Clearly sample content — a
    /// data-driven progression, not a final, evidence-reviewed curriculum (§3).
    static let all: [GameLevel] = {
        var levels = curated
        var index = curated.count + 1
        while index <= 100 {
            let template = curated[(index - 1) % curated.count]
            let step = (index - 1) / curated.count        // 0,1,2… harder each cycle
            // Rotate the theme (for single-theme mechanics) so images vary.
            let theme = template.usesSingleTheme
                ? SampleContent.themePool[index % SampleContent.themePool.count]
                : nil
            levels.append(template.scaled(toIndex: index, step: step, theme: theme))
            index += 1
        }
        return levels
    }()

    static func level(at index: Int) -> GameLevel? {
        all.first { $0.index == index }
    }
}
