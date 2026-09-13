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

    // MARK: Adaptive difficulty (§7)

    @Test func adaptiveOffsetRampsUpAndEasesWithinBounds() {
        let store = freshStore()
        #expect(store.adaptiveOffset == 0)
        for _ in 0..<6 { _ = store.complete(level: level(5), correct: 4, total: 4) }
        #expect(store.adaptiveOffset == GameStore.adaptiveRange.upperBound)  // capped
        for _ in 0..<10 { _ = store.complete(level: level(5), correct: 0, total: 4) }
        #expect(store.adaptiveOffset == GameStore.adaptiveRange.lowerBound)  // floored
    }

    @Test func adaptedLevelKeepsIdentityAndFloors() {
        let store = freshStore()
        for _ in 0..<6 { _ = store.complete(level: level(5), correct: 4, total: 4) }
        let ramped = store.adapted(level(5))
        #expect(ramped.index == 5 && ramped.mechanic == .retrieval)
        #expect(ramped.memorizeSeconds >= 6)              // never below the floor
        #expect(ramped.itemCount > level(5).itemCount)    // harder = more items

        // A timerless mechanic never gains a study timer.
        #expect(store.adapted(level(1)).memorizeSeconds == 0)
    }

    // MARK: PACER levels were appended, not spliced in

    /// The original twelve keep their index *and* their mechanic, so a saved
    /// highestUnlockedLevel still means what it meant before.
    @Test func addingPacerLevelsDidNotRenumberTheExistingLadder() {
        let expected: [LevelMechanic] = [
            .pairRecall, .chunking, .scene, .scene, .retrieval, .retrieval,
            .interleaving, .pairRecall, .loci, .elaboration, .story, .numberShape
        ]
        for (i, mechanic) in expected.enumerated() {
            #expect(level(i + 1).mechanic == mechanic)
        }
        #expect(SampleLevels.all.count == 100)
    }

    @Test func pacerLevelsCarryTheirContent() {
        #expect(level(13).mechanic == .procedure)
        #expect(level(13).procedure != nil)
        #expect(level(14).mechanic == .analogy)
        #expect((level(14).analogies ?? []).isEmpty == false)
        #expect(level(15).mechanic == .conceptMap)
        #expect(level(15).conceptMap != nil)
    }

    /// Difficulty-scaled clones and adaptive variants must keep the wired
    /// content — dropping it would make a generated PACER level fall back to
    /// the default deck and silently change the mission.
    @Test func scalingAndAdaptingPreservePacerContent() {
        let store = freshStore()

        let scaled = level(13).scaled(toIndex: 28, step: 1)
        #expect(scaled.procedure?.id == level(13).procedure?.id)

        let adaptedAnalogy = store.adapted(level(14))
        #expect((adaptedAnalogy.analogies ?? []).count == (level(14).analogies ?? []).count)

        let adaptedMap = store.adapted(level(15))
        #expect(adaptedMap.conceptMap?.id == level(15).conceptMap?.id)
    }

    /// Production-heavy PACER work must not weigh less than recognition.
    @Test func pacerMechanicsWeighAboveMultipleChoice() {
        #expect(level(13).memoryDifficulty > level(1).memoryDifficulty)   // perform > recognise
        #expect(level(15).memoryDifficulty > level(10).memoryDifficulty)  // map > single why
        #expect(level(14).memoryDifficulty > level(1).memoryDifficulty)
    }
}
