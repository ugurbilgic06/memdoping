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

    // MARK: Orienting questions (T01 Attention & Encoding)

    /// Index of the pair currently being judged, when the level uses orienting
    /// questions. Only meaningful while `level.orientingDepth != nil`.
    private(set) var orientingIndex: Int = 0
    /// One entry per judged pair: did the player's yes/no match the truth?
    private(set) var orientingJudgements: [Bool] = []

    var currentOrientingPair: MemoryPair? {
        studyPairs.indices.contains(orientingIndex) ? studyPairs[orientingIndex] : nil
    }

    var orientingCorrectCount: Int { orientingJudgements.filter { $0 }.count }
    var orientingTotal: Int { orientingJudgements.count }

    /// The yes/no prompt shown for the current depth. Shallow and medium ask
    /// about the word as displayed, so they're evaluated against the localized
    /// text; deep asks about the thing itself and comes from the theme.
    var orientingQuestion: String {
        switch level.orientingDepth {
        case .shallow: String(localized: "Is this word longer than 5 letters?",
                              bundle: AppLocale.bundle, locale: AppLocale.locale)
        case .medium:  String(localized: "Does this word end in a vowel?",
                              bundle: AppLocale.bundle, locale: AppLocale.locale)
        case .deep:    level.theme.deepQuestion.localizedContent
        case .none:    ""
        }
    }

    /// Ground truth for the orienting question about `pair`.
    func expectedOrientingAnswer(for pair: MemoryPair) -> Bool {
        let shown = pair.word.localizedContent
        switch level.orientingDepth {
        case .shallow:
            return shown.count > 5
        case .medium:
            let vowels = Set("aeiouAEIOUıİöÖüÜ")
            return shown.last.map { vowels.contains($0) } ?? false
        case .deep:
            return pair.deepAnswer
        case .none:
            return false
        }
    }

    /// Records the player's judgement for the current pair and moves on. When
    /// every pair has been judged, the mission continues into recall.
    ///
    /// The player is deliberately not told whether the judgement itself was
    /// right: the point of the task is that deciding forces deeper encoding,
    /// which shows up later in recall (Craik & Tulving, 1975).
    func judgeCurrentPair(_ playerSaysYes: Bool) {
        guard phase == .learn, let pair = currentOrientingPair else { return }
        orientingJudgements.append(playerSaysYes == expectedOrientingAnswer(for: pair))
        orientingIndex += 1
        if currentOrientingPair == nil { phase = .recall }
    }

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
            let distractors = allWords.filter { $0 != pair.word }.shuffled()
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
