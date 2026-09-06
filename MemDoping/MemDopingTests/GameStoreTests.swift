//
//  GameStoreTests.swift
//  MemDopingTests
//
//  Reward integrity, progression, scoring comparability, and the spaced-review
//  scheduler (§10 P7). Uses the Swift Testing framework.
//

import Testing
@testable import MemDoping

@MainActor
struct GameStoreTests {

    /// A store with a clean slate (progress is persisted in UserDefaults).
    private func freshStore() -> GameStore {
        let store = GameStore()
        store.resetProgress()
        return store
    }

    private func level(_ i: Int) -> GameLevel { SampleLevels.level(at: i)! }

    // MARK: Reward integrity

    @Test func masteringCurrentLevelAwardsBonusAndUnlocksNext() {
        let store = freshStore()
        #expect(store.highestUnlockedLevel == 1)

        let lvl = level(1)
        let outcome = store.complete(level: lvl, correct: 4, total: 4)

        // 20 base + 4*15 per-correct + 100 first-unlock bonus.
        #expect(outcome.xpEarned == 20 + 60 + 100)
        #expect(outcome.mastered)
        #expect(outcome.unlockedNextLevel)
        #expect(store.highestUnlockedLevel == 2)
    }

    @Test func failingDoesNotUnlockAndGivesNoBonus() {
        let store = freshStore()
        let outcome = store.complete(level: level(1), correct: 1, total: 4)  // 25% < 60%
        #expect(!outcome.mastered)
        #expect(!outcome.unlockedNextLevel)
        #expect(outcome.xpEarned == 20 + 15)
        #expect(store.highestUnlockedLevel == 1)
    }

    @Test func replayingAnUnlockedLevelCannotFarmTheUnlockBonus() {
        let store = freshStore()
        _ = store.complete(level: level(1), correct: 4, total: 4)   // unlocks 2
        let xpAfterFirst = store.xp
        // Replay level 1 (no longer the highest unlocked): mastery, but no bonus.
        let outcome = store.complete(level: level(1), correct: 4, total: 4)
        #expect(!outcome.unlockedNextLevel)
        #expect(outcome.xpEarned == 20 + 60)
        #expect(store.xp == xpAfterFirst + 80)
        #expect(store.highestUnlockedLevel == 2)
    }

    @Test func bestAccuracyKeepsTheMaximum() {
        let store = freshStore()
        _ = store.complete(level: level(1), correct: 4, total: 4)   // 100%
        _ = store.complete(level: level(1), correct: 2, total: 4)   // 50%
        #expect(store.bestAccuracy[1] == 1.0)
    }

    // MARK: Memory Score

    @Test func memoryScoreNeedsEnoughData() {
        let store = freshStore()
        #expect(store.memoryScore == nil)
        _ = store.complete(level: level(1), correct: 4, total: 4)
        _ = store.complete(level: level(1), correct: 4, total: 4)
        #expect(store.memoryScore == nil)                 // still < 3
        _ = store.complete(level: level(1), correct: 4, total: 4)
        #expect(store.memoryScore != nil)                 // 3 sessions
        #expect(store.memoryScore == 100)                 // all perfect
    }

    // MARK: Scoring comparability (difficulty weights)

    @Test func productionMechanicsWeighMoreThanRecognition() {
        // Free recall / reconstruction should count for more than multiple choice.
        #expect(level(1).memoryDifficulty < level(5).memoryDifficulty)   // orienting(pairRecall) < retrieval
        #expect(level(2).memoryDifficulty > level(1).memoryDifficulty)   // chunking > recognition
        #expect(level(9).memoryDifficulty > level(1).memoryDifficulty)   // loci > recognition
    }

    @Test func legacyResultWithoutDifficultyUsesChoiceCountFallback() {
        let legacy = SessionResult(levelIndex: 1, correct: 1, total: 1, choiceCount: 3, date: .now)
        #expect(abs(legacy.difficultyWeight - 0.65) < 0.0001)
    }

    // MARK: Spaced review (T05)

    @Test func reviewsAreScheduledForLaterAndNotDuplicated() {
        let store = freshStore()
        let pairs = Array(SampleContent.space.pairs.prefix(3))
        store.scheduleReviews(themeId: SampleContent.space.id, pairs: pairs)
        #expect(store.reviews.count == 3)
        #expect(store.dueReviewCount == 0)          // due tomorrow, not now
        #expect(store.nextReviewDate != nil)

        store.scheduleReviews(themeId: SampleContent.space.id, pairs: pairs)
        #expect(store.reviews.count == 3)           // no duplicates
    }

    @Test func reviewOutcomeWidensOnSuccessAndStepsBackOnMiss() {
        let store = freshStore()
        store.scheduleReviews(themeId: SampleContent.space.id,
                              pairs: Array(SampleContent.space.pairs.prefix(1)))
        let key = store.reviews.keys.first!
        store.recordReview(key: key, remembered: true)
        store.recordReview(key: key, remembered: true)
        #expect(store.reviews[key]?.stage == 2)
        store.recordReview(key: key, remembered: false)
        #expect(store.reviews[key]?.stage == 1)     // steps back, never resets to 0 harshly
    }

    @Test func retentionScoreReflectsDelayedRecall() {
        let store = freshStore()
        store.scheduleReviews(themeId: SampleContent.space.id,
                              pairs: Array(SampleContent.space.pairs.prefix(1)))
        let key = store.reviews.keys.first!
        #expect(store.retentionScore == nil)        // < 3 outcomes
        store.recordReview(key: key, remembered: true)
        store.recordReview(key: key, remembered: true)
        store.recordReview(key: key, remembered: false)
        #expect(store.retentionScore == 67)         // 2/3 rounded
    }
}
