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

    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }

    /// Difficulty weight (0.5...1.0): more answer choices means a harder task,
    /// so a correct answer counts for more toward the Memory Score.
    var difficultyWeight: Double {
        min(1.0, 0.5 + Double(choiceCount - 2) * 0.15)
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

    // MARK: Preferences (§4 accessibility / comfort)

    var soundEnabled: Bool = true { didSet { save() } }
    var hapticsEnabled: Bool = true { didSet { save() } }

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
            date: .now
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
    }

    private func save() {
        let snapshot = Snapshot(
            xp: xp,
            highestUnlockedLevel: highestUnlockedLevel,
            bestAccuracy: bestAccuracy,
            recentResults: recentResults,
            lastDailyMissionDate: lastDailyMissionDate,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled
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
    }

    /// Wipes all progress. Used from the profile screen.
    func resetProgress() {
        xp = 0
        highestUnlockedLevel = 1
        bestAccuracy = [:]
        recentResults = []
        lastDailyMissionDate = nil
        save()
    }
}
