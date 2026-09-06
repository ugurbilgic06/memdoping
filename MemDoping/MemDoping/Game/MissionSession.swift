//
//  MissionSession.swift
//  MemDoping
//
//  Drives a single mission through its phases (§ P2 playable loop):
//  intro -> learn -> recall -> feedback -> summary. Retry is always allowed
//  without penalty, favoring learning quality over speed (§2 feedback).
//

import Foundation
import Observation

/// One recall question: "which word goes with this symbol?"
struct RecallQuestion: Identifiable {
    let id = UUID()
    let prompt: MemoryPair
    let options: [String]      // shuffled words, one correct
    var chosen: String?

    var isAnswered: Bool { chosen != nil }
    var isCorrect: Bool { chosen == prompt.word }
}

@Observable
final class MissionSession {

    enum Phase: Equatable {
        case intro          // mission briefing + technique tip
        case learn          // memorize the pairs
        case recall         // answer questions
        case feedback       // per-question review
        case summary        // XP / Memory Score / next step
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    /// The pairs selected for this run (random subset of the theme).
    private(set) var studyPairs: [MemoryPair] = []
    private(set) var questions: [RecallQuestion] = []
    private(set) var currentQuestionIndex: Int = 0

    /// Seconds remaining in the Learn phase.
    private(set) var learnSecondsRemaining: Int

    init(level: GameLevel) {
        self.level = level
        self.learnSecondsRemaining = level.memorizeSeconds
        buildRun()
    }

    // MARK: - Run setup

    private func buildRun() {
        let pool = level.theme.pairs.shuffled()
        studyPairs = Array(pool.prefix(level.itemCount))

        // Build questions from the studied pairs; distractors are other words
        // from the same theme (similar context raises difficulty, §7).
        let allWords = level.theme.pairs.map(\.word)
        let questionPairs = studyPairs.shuffled().prefix(level.questionCount)

        questions = questionPairs.map { pair in
            var distractors = allWords.filter { $0 != pair.word }.shuffled()
            let optionCount = max(2, level.choiceCount) - 1
            let picked = Array(distractors.prefix(optionCount))
            let options = (picked + [pair.word]).shuffled()
            return RecallQuestion(prompt: pair, options: options)
        }
    }

    // MARK: - Progress helpers

    var currentQuestion: RecallQuestion? {
        guard questions.indices.contains(currentQuestionIndex) else { return nil }
        return questions[currentQuestionIndex]
    }

    var correctCount: Int { questions.filter(\.isCorrect).count }
    var totalQuestions: Int { questions.count }
    var accuracy: Double {
        totalQuestions == 0 ? 0 : Double(correctCount) / Double(totalQuestions)
    }
    var recallProgress: Double {
        totalQuestions == 0 ? 0 : Double(currentQuestionIndex) / Double(totalQuestions)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    // MARK: - Phase transitions

    func beginLearning() { phase = .learn }

    /// Called each second by the Learn-phase timer.
    func tickLearnTimer() {
        guard phase == .learn else { return }
        if learnSecondsRemaining > 0 {
            learnSecondsRemaining -= 1
        } else {
            beginRecall()
        }
    }

    /// Player taps "I'm ready" to skip the rest of the memorize window.
    func beginRecall() {
        guard phase == .learn else { return }
        phase = .recall
    }

    /// Records an answer for the current question and advances.
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

    func showSummary() { phase = .summary }

    /// Restart the same level from scratch (retry without shame, §2).
    func makeRetry() -> MissionSession {
        MissionSession(level: level)
    }
}
