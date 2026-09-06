//
//  MechanicsTests.swift
//  MemDopingTests
//
//  Invariants of each game mechanic's session model — the rules that make each
//  technique faithful (order, discrimination, serial recall, scoring).
//

import Testing
@testable import MemDoping

@MainActor
struct MechanicsTests {

    private func level(_ i: Int) -> GameLevel { SampleLevels.level(at: i)! }

    // MARK: Chunking (T03) — scored per group, not per digit

    @Test func chunkingScoresWholeGroups() {
        let s = ChunkingSession(level: level(2))
        s.beginGrouping()
        s.toggleBreak(at: 3)                 // at least one break
        s.beginStudying()
        s.beginRecall()
        for d in s.digits { s.enter(d) }     // type it back correctly
        #expect(s.correctChunks == s.totalChunks)
        #expect(s.accuracy == 1.0)
    }

    // MARK: Retrieval (T04) — free recall from letter tiles

    @Test func retrievalScoresBuiltWords() {
        let s = RetrievalSession(level: level(5))
        s.beginLearning()
        s.beginRecall()
        while s.phase == .recall {
            for ch in Array(s.target) {
                if let t = s.tray.first(where: { !$0.used && $0.letter == ch }) { s.place(tileID: t.id) }
            }
            s.advanceAfterWord()
        }
        #expect(s.correctCount == s.totalQuestions)
        #expect(s.unaidedCount == s.totalQuestions)   // no hints used
    }

    @Test func retrievalHintCountsAsAidedNotUnaided() {
        let s = RetrievalSession(level: level(6))
        s.beginLearning()
        s.beginRecall()
        while s.phase == .recall {
            while !s.isWordComplete { s.useHint() }    // solve entirely with hints
            s.advanceAfterWord()
        }
        #expect(s.correctCount == s.totalQuestions)     // hint places the right letters
        #expect(s.unaidedCount == 0)                    // but none unaided
    }

    // MARK: Interleaving (T06) — never two of the same theme in a row

    @Test func interleavingNeverRepeatsAThemeBackToBack() {
        let s = InterleavingSession(level: level(7))
        let order = s.questions.map(\.themeID)
        for i in 1..<order.count {
            #expect(order[i] != order[i - 1])
        }
    }

    @Test func interleavingTracksCategoryErrorsSeparately() {
        let s = InterleavingSession(level: level(7))
        s.begin()
        while s.phase == .play {
            let q = s.current!
            let wrongTheme = q.categoryOptions.first { $0.id != q.themeID }!
            s.pickCategory(wrongTheme)         // always the wrong category
            s.pickAnswer(q.pair.word)          // but the right word
            s.advance()
        }
        #expect(s.categoryErrors == s.totalQuestions)
        #expect(s.correctCount == s.totalQuestions)
    }

    // MARK: Method of Loci (T09) — serial reconstruction

    @Test func lociScoresStopItemMatches() {
        let s = LociSession(level: level(9))
        s.beginPlacing()
        while s.phase == .place { s.placeCurrent() }
        while s.phase == .recall {
            let correct = s.placements[s.recallIndex].item
            s.pick(correct)
            s.advanceAfterPick()
        }
        #expect(s.correctCount == s.totalStops)
        #expect(s.accuracy == 1.0)
    }

    // MARK: Elaboration (T07) — recall distractors are other facts' reasons

    @Test func elaborationRecallDistractorsAreRealReasons() {
        let s = ElaborationSession(level: level(10))
        let deck = SampleContent.whyEveryday.facts.map(\.because)
        for q in s.questions {
            #expect(q.options.contains(q.fact.because))
            for opt in q.options { #expect(deck.contains(opt)) }   // never a "wrong[]" reason
        }
    }

    // MARK: Story Linking (T08) — order matters

    @Test func storyScoresSerialOrder() {
        let s = StorySession(level: level(11))
        s.beginBuilding()
        while s.phase == .build {
            s.chooseAction(s.currentLink!.options.first!)
            s.advanceAfterLink()
        }
        // Rebuild in the correct order.
        for item in s.items { s.placeNext(item) }
        #expect(s.correctCount == s.totalItems)
    }

    @Test func storyWrongOrderScoresByPosition() {
        let s = StorySession(level: level(11))
        s.beginBuilding()
        while s.phase == .build {
            s.chooseAction(s.currentLink!.options.first!)
            s.advanceAfterLink()
        }
        // Reverse order: with 4 distinct items, no position matches its reverse.
        for item in s.items.reversed() { s.placeNext(item) }
        #expect(s.correctCount == 0)
    }

    // MARK: Scene (T02) — recall targets are the studied words

    @Test func sceneRecallUsesStudiedPairs() {
        let s = SceneSession(level: level(3))
        let studied = Set(s.studyPairs.map(\.word))
        for q in s.questions {
            #expect(studied.contains(q.prompt.word))
        }
    }
}
