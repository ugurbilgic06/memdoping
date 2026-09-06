//
//  SceneSession.swift
//  MemDoping
//
//  Drives a T02 Association & Imagery mission ("Canlı Sahne"). Instead of
//  passively showing pairs, the player *builds their own* vivid image for each
//  one by choosing a silly modifier — the generation is the point (dual coding,
//  Paivio 1971). Recall then tests the pairing with multiple choice.
//
//  Honesty note surfaced in the UI: this technique helps for some people and
//  some material; it's a modest, conditional benefit, not a magic formula
//  (Dunlosky et al. 2013 rated it low-utility). See docs/techniques/association-imagery.md.
//

import Foundation
import Observation

@Observable
final class SceneSession {

    enum Phase: Equatable {
        case intro
        case build      // choose a modifier per item to form a scene
        case recall     // multiple-choice recall of the pairing
        case feedback
        case summary
    }

    /// One item plus the modifier choices offered for it.
    struct SceneCard: Identifiable {
        let id = UUID()
        let pair: MemoryPair
        let options: [SceneModifier]
        var chosen: SceneModifier?
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    private(set) var studyPairs: [MemoryPair] = []
    private(set) var cards: [SceneCard] = []
    private(set) var buildIndex: Int = 0

    private(set) var questions: [RecallQuestion] = []
    private(set) var currentQuestionIndex: Int = 0

    init(level: GameLevel) {
        self.level = level
        buildRun()
    }

    private func buildRun() {
        let pool = level.theme.pairs.shuffled()
        studyPairs = Array(pool.prefix(level.itemCount))

        cards = studyPairs.map { pair in
            let options = Array(SampleContent.sceneModifiers.shuffled().prefix(3))
            return SceneCard(pair: pair, options: options)
        }

        let allWords = level.theme.pairs.map(\.word)
        questions = studyPairs.shuffled().prefix(level.questionCount).map { pair in
            let distractors = allWords.filter { $0 != pair.word }.shuffled()
            let optionCount = max(2, level.choiceCount) - 1
            let options = (Array(distractors.prefix(optionCount)) + [pair.word]).shuffled()
            return RecallQuestion(prompt: pair, options: options)
        }
    }

    // MARK: - Build phase

    var currentCard: SceneCard? {
        cards.indices.contains(buildIndex) ? cards[buildIndex] : nil
    }
    var buildProgress: Double {
        cards.isEmpty ? 0 : Double(buildIndex) / Double(cards.count)
    }

    func beginBuilding() { phase = .build }

    /// Records the player's chosen modifier for the current item and advances.
    func choose(_ modifier: SceneModifier) {
        guard phase == .build, cards.indices.contains(buildIndex) else { return }
        cards[buildIndex].chosen = modifier
    }

    func advanceAfterChoice() {
        if buildIndex + 1 < cards.count {
            buildIndex += 1
        } else {
            phase = .recall
        }
    }

    // MARK: - Recall phase

    var currentQuestion: RecallQuestion? {
        questions.indices.contains(currentQuestionIndex) ? questions[currentQuestionIndex] : nil
    }
    var recallProgress: Double {
        questions.isEmpty ? 0 : Double(currentQuestionIndex) / Double(questions.count)
    }

    func answerCurrent(_ word: String) {
        guard questions.indices.contains(currentQuestionIndex),
              questions[currentQuestionIndex].chosen == nil else { return }
        questions[currentQuestionIndex].chosen = word
    }

    func advanceAfterAnswer() {
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
        } else {
            phase = .feedback
        }
    }

    // MARK: - Scoring

    var correctCount: Int { questions.filter(\.isCorrect).count }
    var totalQuestions: Int { questions.count }
    var accuracy: Double {
        totalQuestions == 0 ? 0 : Double(correctCount) / Double(totalQuestions)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    func showSummary() { phase = .summary }
    func makeRetry() -> SceneSession { SceneSession(level: level) }
}
