//
//  ElaborationSession.swift
//  MemDoping
//
//  Drives a T07 Elaboration mission ("Neden Böyle?"). For each fact the player
//  chooses the plausible reason (elaborative interrogation), building a "why"
//  they reasoned out themselves. Recall then tests which reason went with which
//  fact — the technique's real promise is better recall, not just picking the
//  sensible reason (Pressley et al. 1987).
//
//  Honesty note surfaced in the UI: this works best on familiar, factual
//  material for players who already have some background; its benefit is
//  conditional (Dunlosky et al. 2013 rated it moderate). See
//  docs/techniques/elaboration.md.
//

import Foundation
import Observation

@Observable
final class ElaborationSession {

    enum Phase: Equatable {
        case intro
        case elaborate   // pick the plausible reason for each fact
        case recall      // recall which reason went with which fact
        case feedback
        case summary
    }

    /// One fact in the elaborate phase, with its shuffled reason options.
    struct ReasonCard: Identifiable {
        let id = UUID()
        let fact: WhyFact
        let options: [String]      // because + wrong, shuffled
        var chosen: String?
        var chosenCorrectly: Bool { chosen == fact.because }
    }

    /// One recall question: given the fact, which reason was it?
    struct RecallQ: Identifiable {
        let id = UUID()
        let fact: WhyFact
        let options: [String]      // because + other facts' becauses, shuffled
        var chosen: String?
        var isCorrect: Bool { chosen == fact.because }
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    private(set) var facts: [WhyFact] = []
    private(set) var cards: [ReasonCard] = []
    private(set) var elaborateIndex: Int = 0

    private(set) var questions: [RecallQ] = []
    private(set) var recallIndex: Int = 0

    init(level: GameLevel) {
        self.level = level
        buildRun()
    }

    private func buildRun() {
        let deck = level.whyDeck ?? SampleContent.whyEveryday
        facts = Array(deck.facts.shuffled().prefix(level.itemCount))

        cards = facts.map { fact in
            let opts = ([fact.because] + fact.wrong).shuffled()
            return ReasonCard(fact: fact, options: opts)
        }

        // Recall distractors are the *correct* reasons of other facts — so the
        // player must remember which reason paired with which fact.
        let allReasons = deck.facts.map(\.because)
        questions = facts.shuffled().prefix(level.questionCount).map { fact in
            let others = allReasons.filter { $0 != fact.because }.shuffled()
            let optionCount = max(2, level.choiceCount) - 1
            let opts = (Array(others.prefix(optionCount)) + [fact.because]).shuffled()
            return RecallQ(fact: fact, options: opts)
        }
    }

    // MARK: - Elaborate phase

    var currentCard: ReasonCard? {
        cards.indices.contains(elaborateIndex) ? cards[elaborateIndex] : nil
    }
    var elaborateProgress: Double {
        cards.isEmpty ? 0 : Double(elaborateIndex) / Double(cards.count)
    }

    func beginElaborating() { phase = .elaborate }

    func chooseReason(_ reason: String) {
        guard phase == .elaborate, cards.indices.contains(elaborateIndex),
              cards[elaborateIndex].chosen == nil else { return }
        cards[elaborateIndex].chosen = reason
    }

    func advanceAfterReason() {
        if elaborateIndex + 1 < cards.count {
            elaborateIndex += 1
        } else {
            phase = .recall
        }
    }

    // MARK: - Recall phase

    var currentQuestion: RecallQ? {
        questions.indices.contains(recallIndex) ? questions[recallIndex] : nil
    }
    var recallProgress: Double {
        questions.isEmpty ? 0 : Double(recallIndex) / Double(questions.count)
    }

    func answerCurrent(_ reason: String) {
        guard phase == .recall, questions.indices.contains(recallIndex),
              questions[recallIndex].chosen == nil else { return }
        questions[recallIndex].chosen = reason
    }

    func advanceAfterAnswer() {
        if recallIndex + 1 < questions.count {
            recallIndex += 1
        } else {
            phase = .feedback
        }
    }

    // MARK: - Scoring

    var reasonedCount: Int { cards.filter(\.chosenCorrectly).count }
    var correctCount: Int { questions.filter(\.isCorrect).count }
    var totalQuestions: Int { questions.count }
    var accuracy: Double {
        totalQuestions == 0 ? 0 : Double(correctCount) / Double(totalQuestions)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    func showSummary() { phase = .summary }
    func makeRetry() -> ElaborationSession { ElaborationSession(level: level) }
}
