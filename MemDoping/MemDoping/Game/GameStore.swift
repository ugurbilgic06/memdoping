//
//  GameStore.swift
//  MemDoping
//
//  Persistent progression store. Keeps MemDoping XP, the Memory Score, and level
//  unlocks separated (§7): XP rewards effort, Memory Score reflects recall
//  performance, and neither can be bought. Persisted with UserDefaults.
//

import Foundation
import Observation

/// The result of one completed mission, used to compute the Memory Score.
struct SessionResult: Codable, Identifiable {
    var id = UUID()
    let levelIndex: Int
    let correct: Int
    let total: Int
    let choiceCount: Int
    let date: Date
    /// Mechanic-aware difficulty (see GameLevel.memoryDifficulty). Optional so
    /// saves written before mechanic-aware weighting still decode.
    var difficulty: Double? = nil

    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }

    /// How much this result counts toward the Memory Score. Prefers the stored
    /// mechanic-aware difficulty; falls back to the old choiceCount formula for
    /// legacy results that predate it.
    var difficultyWeight: Double {
        if let difficulty { return min(1.0, max(0.2, difficulty)) }
        return min(1.0, 0.5 + Double(choiceCount - 2) * 0.15)
    }
}

/// A studied item waiting for its next spaced review (T05). Keyed by a stable
/// "themeId:word" string so it survives the per-run UUIDs on MemoryPair.
struct ReviewRecord: Codable, Identifiable {
    var id: String { key }
    let key: String
    let themeId: String
    let word: String
    let symbol: String
    var stage: Int          // index into ReviewSchedule.intervalDays
    var dueDate: Date
    var lastRemembered: Bool?
}

/// Expanding review intervals — a simplified, transparent form of the
/// evidence-based "expanding retrieval" principle (Cepeda et al. 2006/2008).
/// Late reviews are only deferred, never punished (§6 no coercive streaks).
enum ReviewSchedule {
    static let intervalDays: [Int] = [1, 3, 7, 14]

    static func nextDue(stage: Int, from date: Date = .now) -> Date {
        let days = intervalDays[min(max(stage, 0), intervalDays.count - 1)]
        return Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
}

@Observable
final class GameStore {

    // MARK: Persisted progression

    private(set) var xp: Int = 0
    private(set) var highestUnlockedLevel: Int = 1
    private(set) var bestAccuracy: [Int: Double] = [:]     // levelIndex -> best
    private(set) var recentResults: [SessionResult] = []   // most recent first
    private(set) var lastDailyMissionDate: Date?

    // MARK: Spaced review (T05 — system layer)

    /// Items scheduled for spaced review, keyed by "themeId:word".
    private(set) var reviews: [String: ReviewRecord] = [:]
    /// Outcomes of delayed reviews (newest first) — the basis for the
    /// Retention indicator, which is §2's "delayed recall" component.
    private(set) var retentionHistory: [Bool] = []

    // MARK: Preferences (§4 accessibility / comfort)

    var soundEnabled: Bool = true { didSet { save() } }
    var hapticsEnabled: Bool = true { didSet { save() } }
    var musicEnabled: Bool = true { didSet { save(); MusicPlayer.shared.setEnabled(musicEnabled) } }

    /// Chosen UI/content language ("tr", "en"); nil follows the system.
    var languageCode: String? = nil { didSet { AppLocale.apply(languageCode); save() } }

    /// Night Doping progresses through a gentle ladder of 20 calm sessions.
    static let nightLevels = 20
    var nightLevel: Int = 1 { didSet { save() } }
    /// Advance Night Doping after a finished wind-down (wraps at the end).
    func advanceNight() {
        nightLevel = nightLevel >= GameStore.nightLevels ? 1 : nightLevel + 1
    }

    /// Whether the player has seen the first-run welcome.
    private(set) var hasOnboarded: Bool = false

    // MARK: Audience (§1 — adapt to each age group)

    enum AgeBand: String, Codable, CaseIterable { case child, teen, adult }

    /// The chosen audience band; nil until picked (treated as neutral).
    private(set) var ageBand: AgeBand?

    func setAgeBand(_ band: AgeBand) { ageBand = band; save() }

    /// A baseline difficulty shift from the age band: younger = gentler.
    var ageOffset: Int {
        switch ageBand {
        case .child:        return -2
        case .teen, .none:  return 0
        case .adult:        return 1
        }
    }

    // MARK: Adaptive difficulty (§7)

    /// A transparent difficulty offset that nudges up on repeated success and
    /// down on repeated struggle. Applied to a level's parameters, not its
    /// identity. Bounded so it can never punish or trivialize.
    private(set) var adaptiveOffset: Int = 0
    static let adaptiveRange = -2...3

    private let defaultsKey = "memdoping.save.v1"

    init() { load() }

    // MARK: - Derived state

    /// The next level the player should tackle: highest unlocked, capped to the
    /// ladder length.
    var currentLevel: GameLevel {
        SampleLevels.level(at: min(highestUnlockedLevel, SampleLevels.all.count))
            ?? SampleLevels.all[0]
    }

    var totalLevels: Int { SampleLevels.all.count }

    var isLevelUnlocked: (Int) -> Bool {
        { [highestUnlockedLevel] index in index <= highestUnlockedLevel }
    }

    /// XP needed to fill the current progress ring. Simple, transparent rule
    /// (§2): every level of the ring is 500 XP.
    var xpPerRing: Int { 500 }
    var ringLevel: Int { xp / xpPerRing + 1 }
    var ringProgress: Double { Double(xp % xpPerRing) / Double(xpPerRing) }

    /// Whether today's daily mission has been completed.
    var isDailyMissionDone: Bool {
        guard let last = lastDailyMissionDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: - Memory Score (§2)
    // A 0-100 rolling indicator from recent comparable tasks, weighted by
    // difficulty. Shows an insufficient-data state until enough sessions exist.
    // This is an in-game recall indicator, NOT an IQ or clinical score.

    static let minSessionsForScore = 3

    var hasEnoughDataForScore: Bool {
        recentResults.count >= Self.minSessionsForScore
    }

    var memoryScore: Int? {
        guard hasEnoughDataForScore else { return nil }
        let sample = recentResults.prefix(10)
        let weightedSum = sample.reduce(0.0) { $0 + $1.accuracy * $1.difficultyWeight }
        let weightTotal = sample.reduce(0.0) { $0 + $1.difficultyWeight }
        guard weightTotal > 0 else { return nil }
        return Int((weightedSum / weightTotal * 100).rounded())
    }

    /// Short trend label comparing the newest half of results to the older half.
    var memoryScoreTrend: ScoreTrend {
        guard recentResults.count >= 4 else { return .steady }
        let mid = recentResults.count / 2
        let newer = Array(recentResults[0..<mid])
        let older = Array(recentResults[mid...])
        let newAcc = newer.map(\.accuracy).reduce(0, +) / Double(newer.count)
        let oldAcc = older.map(\.accuracy).reduce(0, +) / Double(older.count)
        if newAcc - oldAcc > 0.08 { return .up }
        if oldAcc - newAcc > 0.08 { return .down }
        return .steady
    }

    enum ScoreTrend { case up, down, steady }

    // MARK: - Spaced review queue (T05)

    /// Items whose review time has arrived, oldest-due first.
    var dueReviews: [ReviewRecord] {
        reviews.values.filter { $0.dueDate <= .now }.sorted { $0.dueDate < $1.dueDate }
    }
    var dueReviewCount: Int { dueReviews.count }
    var hasScheduledReviews: Bool { !reviews.isEmpty }

    /// The soonest upcoming review, used for the quiet "next review" line when
    /// nothing is due yet.
    var nextReviewDate: Date? {
        reviews.values.map(\.dueDate).filter { $0 > .now }.min()
    }

    /// Retention: how much of what was learned survives a delay. Distinct from
    /// the Memory Score (same-session recall). Not an IQ or clinical measure.
    var retentionScore: Int? {
        guard retentionHistory.count >= 3 else { return nil }
        let sample = retentionHistory.prefix(20)
        let remembered = sample.filter { $0 }.count
        return Int((Double(remembered) / Double(sample.count) * 100).rounded())
    }

    /// Enqueues the items a pair-based mission just taught. Re-learning an item
    /// already in the queue leaves its schedule untouched, so replaying a level
    /// can't farm the review system.
    func scheduleReviews(themeId: String, pairs: [MemoryPair]) {
        let now = Date.now
        for pair in pairs {
            let key = "\(themeId):\(pair.word)"
            guard reviews[key] == nil else { continue }
            reviews[key] = ReviewRecord(
                key: key, themeId: themeId, word: pair.word, symbol: pair.symbol,
                stage: 0, dueDate: ReviewSchedule.nextDue(stage: 0, from: now),
                lastRemembered: nil
            )
        }
        save()
    }

    /// Records a spaced-review outcome and reschedules the item. Success widens
    /// the interval; a miss steps back one stage (gentle, never a reset — §6).
    func recordReview(key: String, remembered: Bool) {
        guard var record = reviews[key] else { return }
        record.lastRemembered = remembered
        record.stage = remembered ? record.stage + 1 : max(0, record.stage - 1)
        record.dueDate = ReviewSchedule.nextDue(stage: record.stage)
        reviews[key] = record

        retentionHistory.insert(remembered, at: 0)
        if retentionHistory.count > 40 { retentionHistory.removeLast() }
        save()
    }

    // MARK: - Recording a completed session

    /// Records a finished mission: awards XP, updates best accuracy, unlocks the
    /// next level on mastery, and refreshes the Memory Score sample.
    /// Returns a summary describing what changed (for the results screen).
    @discardableResult
    func complete(level: GameLevel, correct: Int, total: Int) -> SessionOutcome {
        let result = SessionResult(
            levelIndex: level.index,
            correct: correct,
            total: total,
            choiceCount: level.choiceCount,
            date: .now,
            difficulty: level.memoryDifficulty
        )
        recentResults.insert(result, at: 0)
        if recentResults.count > 30 { recentResults.removeLast() }

        // XP: base for finishing + per-correct + mastery bonus. Transparent and
        // farming-resistant (mastery bonus only once per new level unlocked).
        var earned = 20 + correct * 15
        let mastered = result.accuracy >= level.masteryPercent
        var didUnlock = false

        if mastered && level.index == highestUnlockedLevel
            && highestUnlockedLevel < totalLevels {
            highestUnlockedLevel += 1
            earned += 100
            didUnlock = true
        }
        xp += earned

        let prevBest = bestAccuracy[level.index] ?? 0
        let newBest = max(prevBest, result.accuracy)
        bestAccuracy[level.index] = newBest

        if !isDailyMissionDone { lastDailyMissionDate = .now }

        // Adaptive difficulty (§7): repeated success permits one small step up;
        // repeated struggle steps down. Transparent and bounded.
        if result.accuracy >= 0.85 {
            adaptiveOffset = min(Self.adaptiveRange.upperBound, adaptiveOffset + 1)
        } else if result.accuracy <= 0.40 {
            adaptiveOffset = max(Self.adaptiveRange.lowerBound, adaptiveOffset - 1)
        }

        save()

        return SessionOutcome(
            xpEarned: earned,
            mastered: mastered,
            unlockedNextLevel: didUnlock,
            isNewBest: newBest > prevBest,
            memoryScore: memoryScore
        )
    }

    struct SessionOutcome {
        let xpEarned: Int
        let mastered: Bool
        let unlockedNextLevel: Bool
        let isNewBest: Bool
        let memoryScore: Int?
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var xp: Int
        var highestUnlockedLevel: Int
        var bestAccuracy: [Int: Double]
        var recentResults: [SessionResult]
        var lastDailyMissionDate: Date?
        var soundEnabled: Bool
        var hapticsEnabled: Bool
        var musicEnabled: Bool?
        var reviews: [String: ReviewRecord]?
        var retentionHistory: [Bool]?
        var hasOnboarded: Bool?
        var adaptiveOffset: Int?
        var ageBand: AgeBand?
        var languageCode: String?
        var nightLevel: Int?
    }

    private func save() {
        let snapshot = Snapshot(
            xp: xp,
            highestUnlockedLevel: highestUnlockedLevel,
            bestAccuracy: bestAccuracy,
            recentResults: recentResults,
            lastDailyMissionDate: lastDailyMissionDate,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            musicEnabled: musicEnabled,
            reviews: reviews,
            retentionHistory: retentionHistory,
            hasOnboarded: hasOnboarded,
            adaptiveOffset: adaptiveOffset,
            ageBand: ageBand,
            languageCode: languageCode,
            nightLevel: nightLevel
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        xp = snapshot.xp
        highestUnlockedLevel = snapshot.highestUnlockedLevel
        bestAccuracy = snapshot.bestAccuracy
        recentResults = snapshot.recentResults
        lastDailyMissionDate = snapshot.lastDailyMissionDate
        soundEnabled = snapshot.soundEnabled
        hapticsEnabled = snapshot.hapticsEnabled
        musicEnabled = snapshot.musicEnabled ?? true
        reviews = snapshot.reviews ?? [:]
        retentionHistory = snapshot.retentionHistory ?? []
        hasOnboarded = snapshot.hasOnboarded ?? false
        adaptiveOffset = snapshot.adaptiveOffset ?? 0
        ageBand = snapshot.ageBand
        nightLevel = snapshot.nightLevel ?? 1
        languageCode = snapshot.languageCode   // didSet applies AppLocale
    }

    // MARK: - Adaptive difficulty application

    /// Applies the adaptive offset to a level's gameplay parameters (item count,
    /// choices, and study time) while preserving its identity. Sessions already
    /// clamp counts to the available content, so over-shoot is safe. Study time
    /// grows when eased and shrinks when ramped, but never below a floor.
    func adapted(_ level: GameLevel) -> GameLevel {
        // Age band sets the baseline; adaptive performance nudges from there.
        let o = adaptiveOffset + ageOffset
        guard o != 0 else { return level }
        let stepSign = o > 0 ? 1 : -1
        return level.varying(
            itemCount: max(2, level.itemCount + o),
            questionCount: max(2, level.questionCount + stepSign),
            choiceCount: level.choiceCount == 0 ? 0
                : min(5, max(2, level.choiceCount + stepSign)),
            memorizeSeconds: level.memorizeSeconds == 0 ? 0
                : max(6, level.memorizeSeconds - o * 2)
        )
    }

    enum DifficultyState { case eased, standard, ramped }

    /// The current adaptation state (UI maps this to a localized label).
    var difficultyState: DifficultyState {
        if adaptiveOffset < 0 { return .eased }
        if adaptiveOffset > 0 { return .ramped }
        return .standard
    }

    /// Marks the first-run welcome as seen.
    func completeOnboarding() {
        hasOnboarded = true
        save()
    }

    /// Wipes all progress. Used from the profile screen.
    func resetProgress() {
        xp = 0
        highestUnlockedLevel = 1
        bestAccuracy = [:]
        recentResults = []
        lastDailyMissionDate = nil
        reviews = [:]
        retentionHistory = []
        adaptiveOffset = 0
        save()
    }
}
