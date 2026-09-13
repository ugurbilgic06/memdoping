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

    // MARK: Number-Shape (T11) — digit-sequence recall

    @Test func numberShapeScoresDigitPositions() {
        let s = NumberShapeSession(level: level(12))
        s.beginStudying()
        s.beginRecall()
        for d in s.digits { s.enter(d) }            // type the code back correctly
        #expect(s.correctCount == s.total)
        #expect(s.accuracy == 1.0)
        #expect(s.legend.count == 10)               // a shape for every digit
        // Every digit maps to a non-empty shape.
        for d in 0...9 { #expect(s.shape(for: d) != "?") }
    }

    // MARK: PACER P — Procedural. Only unaided placements score, and a wrong
    // move must teach rather than simply fail.

    @Test func procedureScoresOnlyFirstTryPlacements() {
        let s = ProcedureSession(level: level(13))
        s.beginStudy()
        s.beginPerforming()
        while s.phase == .perform, let expected = s.expectedStep {
            s.attempt(expected)
        }
        #expect(s.correctCount == s.totalSteps)
        #expect(s.accuracy == 1.0)
        #expect(s.missteps.isEmpty)
    }

    @Test func procedureMisstepCorrectsInsteadOfAdvancing() {
        let s = ProcedureSession(level: level(13))
        s.beginStudy()
        s.beginPerforming()

        guard let expected = s.expectedStep,
              let wrong = s.tray.first(where: { $0.id != expected.id }) else {
            Issue.record("tray should offer at least one wrong move")
            return
        }

        let placedBefore = s.placed.count
        s.attempt(wrong)

        #expect(s.placed.count == placedBefore)      // nothing moved
        #expect(s.correction != nil)                 // the corrective is raised
        #expect(s.correction?.expected.id == expected.id)
        #expect(!(s.correction?.step.why ?? "").isEmpty)   // and it explains itself

        s.acknowledgeCorrection()
        #expect(s.correction == nil)

        // Same position, now answered correctly — but it no longer counts.
        s.attempt(expected)
        #expect(s.placed.count == placedBefore + 1)
        #expect(s.correctCount == placedBefore)
    }

    @Test func procedureTrapsAreNotPartOfTheOrder() {
        let s = ProcedureSession(level: level(13))
        let traps = s.tray.filter { s.isTrap($0) }
        #expect(!traps.isEmpty)
        // A trap is never one of the steps the procedure actually asks for.
        for trap in traps {
            #expect(!s.steps.contains { $0.id == trap.id })
        }
    }

    // MARK: PACER A — Analogous. The critique must have both sides, and recall
    // distractors must come from *other* comparisons.

    @Test func analogyOffersBothHoldingAndBreakingClaims() {
        let s = AnalogySession(level: level(14))
        for analogy in s.analogies {
            #expect(!analogy.holdingPoints.isEmpty)
            #expect(!analogy.breakingPoints.isEmpty)
        }
    }

    @Test func analogyScoresTheRecalledBreakingPoint() {
        let s = AnalogySession(level: level(14))
        s.beginCritique()
        while s.phase == .critique, let j = s.currentJudgement {
            s.judge(holds: j.aspect.holds)       // judge every claim correctly
            s.advanceAfterJudgement()
        }
        #expect(s.critiqueCorrect == s.critiqueTotal)

        while s.phase == .recall, let q = s.currentQuestion {
            s.answerCurrent(q.answer)
            s.advanceAfterAnswer()
        }
        #expect(s.correctCount == s.totalQuestions)
        #expect(s.accuracy == 1.0)
    }

    @Test func analogyDistractorsBelongToOtherComparisons() {
        let s = AnalogySession(level: level(14))
        for q in s.questions {
            let ownBreaks = Set(q.analogy.breakingPoints.map(\.text))
            let distractors = q.options.filter { $0 != q.answer }
            #expect(!distractors.isEmpty)
            for d in distractors {
                #expect(!ownBreaks.contains(d))   // never this analogy's own break
            }
        }
    }

    // MARK: PACER C — Conceptual. The relation is the answer, and the
    // confusable twin always stays on the table.

    @Test func conceptMapScoresRecalledRelations() {
        let s = ConceptMapSession(level: level(15))
        s.beginMapping()
        while s.phase == .map, let link = s.currentLink {
            s.chooseRelation(link.node.relation)
            s.advanceAfterLink()
        }
        #expect(s.mappedCorrect == s.mappedTotal)

        while s.phase == .recall, let q = s.currentQuestion {
            s.answerCurrent(q.node.relation)
            s.advanceAfterAnswer()
        }
        #expect(s.correctCount == s.totalQuestions)
        #expect(s.accuracy == 1.0)
    }

    @Test func conceptMapKeepsTheConfusableTwinInPlay() {
        let s = ConceptMapSession(level: level(15))
        let twins: [RelationKind: RelationKind] = [
            .increases: .decreases, .decreases: .increases,
            .causes: .requires, .requires: .causes
        ]
        for link in s.links {
            #expect(link.options.contains(link.node.relation))
            if let twin = twins[link.node.relation] {
                #expect(link.options.contains(twin))
            }
        }
    }

    @Test func conceptMapOptionsNeverRepeat() {
        let s = ConceptMapSession(level: level(15))
        for link in s.links {
            #expect(Set(link.options).count == link.options.count)
        }
        for q in s.questions {
            #expect(Set(q.options).count == q.options.count)
        }
    }
}
