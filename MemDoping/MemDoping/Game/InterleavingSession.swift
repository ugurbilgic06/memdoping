//
//  InterleavingSession.swift
//  MemDoping
//
//  Drives a T06 Interleaving mission ("Karışık Meydan"). Two or three themes are
//  mixed into one run so no two questions in a row share a theme. Each question
//  is two steps — first pick the category, then the word — which is what lets us
//  measure the real effect: fewer "wrong-category" errors over time (Taylor &
//  Rohrer, 2010). Short-term it feels harder; that's expected and framed as such.
//
//  See docs/techniques/interleaving.md.
//

import Foundation
import Observation

@Observable
final class InterleavingSession {

    enum Phase: Equatable { case intro, play, feedback, summary }
    enum Step: Equatable { case category, answer }

    /// One mixed question: which category, then which word.
    struct Question: Identifiable {
        let id = UUID()
        let pair: MemoryPair
        let themeID: String                 // correct category
        let categoryOptions: [MemoryTheme]  // themes in play (shuffled)
        let answerOptions: [String]         // word + same-theme distractors
        var chosenCategoryID: String?
        var chosenAnswer: String?

        var categoryCorrect: Bool { chosenCategoryID == themeID }
        var answerCorrect: Bool { chosenAnswer == pair.word }
    }

    let level: GameLevel
    let themes: [MemoryTheme]
    private(set) var phase: Phase = .intro
    private(set) var step: Step = .category

    private(set) var questions: [Question] = []
    private(set) var index: Int = 0

    init(level: GameLevel) {
        self.level = level
        self.themes = level.interleavedThemes ?? [level.theme]
        buildRun()
    }

    private func buildRun() {
        // Pull pairs per theme, then interleave round-robin so the same theme
        // never appears twice in a row.
        let perTheme = max(1, level.questionCount / themes.count + 1)
        var buckets: [[(MemoryPair, MemoryTheme)]] = themes.map { theme in
            theme.pairs.shuffled().prefix(perTheme).map { ($0, theme) }
        }

        var ordered: [(MemoryPair, MemoryTheme)] = []
        var lastThemeID: String? = nil
        while ordered.count < level.questionCount, buckets.contains(where: { !$0.isEmpty }) {
            // Prefer a bucket whose theme differs from the last one placed.
            let candidates = buckets.indices.filter { !buckets[$0].isEmpty }
            let pick = candidates.first { themes[$0].id != lastThemeID } ?? candidates.first
            guard let b = pick else { break }
            let item = buckets[b].removeFirst()
            ordered.append(item)
            lastThemeID = item.1.id
        }

        let shuffledThemes = themes.shuffled()
        questions = ordered.prefix(level.questionCount).map { pair, theme in
            let distractors = theme.pairs.map(\.word).filter { $0 != pair.word }.shuffled()
            let optionCount = max(2, level.choiceCount) - 1
            let answers = (Array(distractors.prefix(optionCount)) + [pair.word]).shuffled()
            return Question(
                pair: pair,
                themeID: theme.id,
                categoryOptions: shuffledThemes,
                answerOptions: answers
            )
        }
    }

    // MARK: - Current question

    var current: Question? {
        questions.indices.contains(index) ? questions[index] : nil
    }
    var progress: Double {
        questions.isEmpty ? 0 : Double(index) / Double(questions.count)
    }

    func theme(id: String) -> MemoryTheme? { themes.first { $0.id == id } }

    // MARK: - Flow

    func begin() {
        phase = .play
        step = .category
    }

    /// Records the category pick and moves to the answer step (whether or not
    /// the category was right — the player still answers).
    func pickCategory(_ theme: MemoryTheme) {
        guard phase == .play, step == .category,
              questions.indices.contains(index),
              questions[index].chosenCategoryID == nil else { return }
        questions[index].chosenCategoryID = theme.id
        step = .answer
    }

    func pickAnswer(_ word: String) {
        guard phase == .play, step == .answer,
              questions.indices.contains(index),
              questions[index].chosenAnswer == nil else { return }
        questions[index].chosenAnswer = word
    }

    func advance() {
        if index + 1 < questions.count {
            index += 1
            step = .category
        } else {
            phase = .feedback
        }
    }

    // MARK: - Scoring

    var correctCount: Int { questions.filter(\.answerCorrect).count }
    var totalQuestions: Int { questions.count }
    /// Wrong-category picks — the discrimination error interleaving targets.
    var categoryErrors: Int { questions.filter { $0.chosenCategoryID != nil && !$0.categoryCorrect }.count }
    var accuracy: Double {
        totalQuestions == 0 ? 0 : Double(correctCount) / Double(totalQuestions)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    /// The pairs quizzed this run, for spaced-review scheduling. Grouped by
    /// their own theme id so reviews are keyed correctly across themes.
    var reviewablePairsByTheme: [(themeID: String, pair: MemoryPair)] {
        questions.map { ($0.themeID, $0.pair) }
    }

    func showSummary() { phase = .summary }
    func makeRetry() -> InterleavingSession { InterleavingSession(level: level) }
}
