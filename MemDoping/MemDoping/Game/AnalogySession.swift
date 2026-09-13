//
//  AnalogySession.swift
//  MemDoping
//
//  PACER **A** — Analogous knowledge, whose operation is *Critique*.
//
//  The guide (p.4) warns that an analogy is not the thing itself, so the work
//  isn't to remember the comparison — it's to interrogate it:
//    • in what ways are these two alike?
//    • in what ways do they differ?
//    • at what point does the comparison break down?
//    • could a better one be built?
//
//  So the mission runs in two beats. First the player sorts claims about an
//  analogy into "this holds" and "this breaks" — the critique itself. Then, with
//  the analogies out of sight, they're asked which breaking point belonged to
//  which comparison. The second beat matters because a critique you can't
//  retrieve later quietly collapses back into the analogy you started with.
//
//  The score comes from the recall beat, in line with the other mechanics; the
//  critique accuracy is reported separately so the player can see both.
//
//  SAMPLE CONTENT: familiar comparisons with well-known limits (see
//  SampleContent.analogies). The first is the guide's own worked example.
//

import Foundation
import Observation

@Observable
final class AnalogySession {

    enum Phase: Equatable {
        case intro
        case critique   // does this claim hold, or is it where it breaks?
        case recall     // which analogy broke where?
        case feedback
        case summary
    }

    /// One claim under judgement.
    struct Judgement: Identifiable {
        let id = UUID()
        let analogy: Analogy
        let aspect: AnalogyAspect
        var saidHolds: Bool?
        var isCorrect: Bool { saidHolds == aspect.holds }
        var isAnswered: Bool { saidHolds != nil }
    }

    /// Given the comparison, which was the point where it stopped fitting?
    struct RecallQ: Identifiable {
        let id = UUID()
        let analogy: Analogy
        let answer: String          // one of this analogy's breaking points
        let options: [String]       // answer + other analogies' breaking points
        var chosen: String?
        var isCorrect: Bool { chosen == answer }
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    private(set) var analogies: [Analogy] = []
    private(set) var judgements: [Judgement] = []
    private(set) var critiqueIndex: Int = 0

    private(set) var questions: [RecallQ] = []
    private(set) var recallIndex: Int = 0

    init(level: GameLevel) {
        self.level = level
        buildRun()
    }

    private func buildRun() {
        let pool = level.analogies ?? SampleContent.analogies
        analogies = Array(pool.shuffled().prefix(max(2, level.itemCount)))

        // Every analogy contributes at least one holding and one breaking claim,
        // so the sort is never trivially one-sided.
        judgements = analogies.flatMap { analogy -> [Judgement] in
            analogy.aspects.shuffled().map { Judgement(analogy: analogy, aspect: $0) }
        }

        // Distractors are other analogies' real breaking points: plausible
        // sentences that belong to the wrong comparison.
        let otherBreaks = pool.flatMap { a in
            a.breakingPoints.map { (analogyID: a.id, text: $0.text) }
        }

        questions = analogies.shuffled()
            .prefix(max(2, level.questionCount))
            .compactMap { analogy -> RecallQ? in
                guard let answer = analogy.breakingPoints.randomElement()?.text else { return nil }
                let distractors = otherBreaks
                    .filter { $0.analogyID != analogy.id }
                    .map(\.text)
                    .shuffled()
                let wanted = max(2, level.choiceCount) - 1
                let options = (Array(distractors.prefix(wanted)) + [answer]).shuffled()
                return RecallQ(analogy: analogy, answer: answer, options: options)
            }
    }

    // MARK: - Critique

    var currentJudgement: Judgement? {
        judgements.indices.contains(critiqueIndex) ? judgements[critiqueIndex] : nil
    }
    var critiqueProgress: Double {
        judgements.isEmpty ? 0 : Double(critiqueIndex) / Double(judgements.count)
    }

    /// Claims already judged for the analogy on screen — lets the UI show the
    /// critique building up rather than one isolated card at a time.
    func judgedAspects(for analogy: Analogy) -> [Judgement] {
        judgements.filter { $0.analogy.id == analogy.id && $0.isAnswered }
    }

    func beginCritique() { phase = .critique }

    func judge(holds: Bool) {
        guard phase == .critique, judgements.indices.contains(critiqueIndex),
              judgements[critiqueIndex].saidHolds == nil else { return }
        judgements[critiqueIndex].saidHolds = holds
    }

    func advanceAfterJudgement() {
        if critiqueIndex + 1 < judgements.count {
            critiqueIndex += 1
        } else {
            phase = .recall
        }
    }

    // MARK: - Recall

    var currentQuestion: RecallQ? {
        questions.indices.contains(recallIndex) ? questions[recallIndex] : nil
    }
    var recallProgress: Double {
        questions.isEmpty ? 0 : Double(recallIndex) / Double(questions.count)
    }

    func answerCurrent(_ text: String) {
        guard phase == .recall, questions.indices.contains(recallIndex),
              questions[recallIndex].chosen == nil else { return }
        questions[recallIndex].chosen = text
    }

    func advanceAfterAnswer() {
        if recallIndex + 1 < questions.count {
            recallIndex += 1
        } else {
            phase = .feedback
        }
    }

    // MARK: - Scoring

    /// How sharply the player read the analogies themselves.
    var critiqueCorrect: Int { judgements.filter(\.isCorrect).count }
    var critiqueTotal: Int { judgements.count }

    /// The score: could they retrieve which comparison failed where?
    var correctCount: Int { questions.filter(\.isCorrect).count }
    var totalQuestions: Int { questions.count }
    var accuracy: Double {
        totalQuestions == 0 ? 0 : Double(correctCount) / Double(totalQuestions)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    func showSummary() { phase = .summary }
    func makeRetry() -> AnalogySession { AnalogySession(level: level) }
}
