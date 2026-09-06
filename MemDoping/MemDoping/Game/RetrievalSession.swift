//
//  RetrievalSession.swift
//  MemDoping
//
//  Drives a T04 Retrieval Practice mission ("Şimdi Sen Söyle"): after studying
//  the deck, the player is shown a symbol with NO options and must reconstruct
//  the word from scrambled letter tiles. This is free recall, not recognition —
//  the testing effect is strongest when the answer is produced, not picked
//  (Roediger & Karpicke, 2006). A free, unpenalized hint reveals the next
//  letter so a hard word never becomes a shaming dead end (§2).
//
//  See docs/techniques/retrieval-practice.md.
//

import Foundation
import Observation

/// One scrambled letter the player can place. Carries an id so duplicate
/// letters (e.g. the two T's in "BUTTERFLY") stay independently tappable.
struct LetterTile: Identifiable, Equatable {
    let id = UUID()
    let letter: Character
    var used = false
}

/// How one word was recalled — used both for scoring and for showing the
/// player which words they got entirely on their own (self-efficacy, §7).
struct WordRecall: Identifiable {
    let id = UUID()
    let pair: MemoryPair
    let correct: Bool
    let usedHint: Bool
}

@Observable
final class RetrievalSession {

    enum Phase: Equatable {
        case intro
        case learn      // study the deck against a timer
        case recall     // rebuild each word from letter tiles
        case feedback   // per-word review + testing-effect note
        case summary
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    private(set) var studyPairs: [MemoryPair] = []
    private(set) var learnSecondsRemaining: Int

    // MARK: Recall state

    /// The pairs actually quizzed (subset of the studied deck).
    private(set) var prompts: [MemoryPair] = []
    private(set) var promptIndex: Int = 0

    /// Scrambled tiles for the current word.
    private(set) var tray: [LetterTile] = []
    /// Ids of tiles the player has placed, in order.
    private(set) var placed: [UUID] = []
    /// Whether the hint was used on the current word.
    private(set) var hintUsedThisWord: Bool = false

    private(set) var recalls: [WordRecall] = []

    init(level: GameLevel) {
        self.level = level
        self.learnSecondsRemaining = level.memorizeSeconds
        buildRun()
    }

    private func buildRun() {
        let pool = level.theme.pairs.shuffled()
        studyPairs = Array(pool.prefix(level.itemCount))
        prompts = Array(studyPairs.shuffled().prefix(level.questionCount))
    }

    // MARK: - Current word

    var currentPair: MemoryPair? {
        prompts.indices.contains(promptIndex) ? prompts[promptIndex] : nil
    }

    /// The word to reconstruct, in the display language and upper-cased — the
    /// player memorized the localized word, so that's what they rebuild.
    var target: String {
        (currentPair?.word.localizedContent ?? "").uppercased()
    }

    /// The letters the player has committed so far.
    var built: String {
        String(placed.compactMap { id in tray.first { $0.id == id }?.letter })
    }

    var isWordComplete: Bool { built.count >= target.count }

    /// The next letter the hint would reveal, if any remain.
    private var nextNeededLetter: Character? {
        let idx = built.count
        return idx < target.count ? Array(target)[idx] : nil
    }

    var canUseHint: Bool { phase == .recall && nextNeededLetter != nil }

    // MARK: - Progress helpers

    var recallProgress: Double {
        prompts.isEmpty ? 0 : Double(promptIndex) / Double(prompts.count)
    }
    var correctCount: Int { recalls.filter(\.correct).count }
    var unaidedCount: Int { recalls.filter { $0.correct && !$0.usedHint }.count }
    var totalQuestions: Int { prompts.count }
    var accuracy: Double {
        totalQuestions == 0 ? 0 : Double(correctCount) / Double(totalQuestions)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    // MARK: - Phase transitions

    func beginLearning() { phase = .learn }

    func tickLearnTimer() {
        guard phase == .learn else { return }
        if learnSecondsRemaining > 0 { learnSecondsRemaining -= 1 }
        else { beginRecall() }
    }

    func beginRecall() {
        guard phase == .learn else { return }
        phase = .recall
        loadCurrentWord()
    }

    private func loadCurrentWord() {
        placed = []
        hintUsedThisWord = false
        tray = target.map { LetterTile(letter: $0) }.shuffled()
        // Guard against a scramble that accidentally equals the answer.
        if tray.map(\.letter) == Array(target) && target.count > 1 {
            tray.reverse()
        }
    }

    // MARK: - Player actions

    func place(tileID: UUID) {
        guard phase == .recall,
              let i = tray.firstIndex(where: { $0.id == tileID }),
              !tray[i].used else { return }
        tray[i].used = true
        placed.append(tileID)
        if isWordComplete { evaluateCurrentWord() }
    }

    func removeLast() {
        guard phase == .recall, let last = placed.popLast(),
              let i = tray.firstIndex(where: { $0.id == last }) else { return }
        tray[i].used = false
    }

    /// Places the next correct letter for the player, free of charge, and marks
    /// the word as hint-assisted.
    func useHint() {
        guard let needed = nextNeededLetter,
              let i = tray.firstIndex(where: { !$0.used && $0.letter == needed }) else { return }
        hintUsedThisWord = true
        tray[i].used = true
        placed.append(tray[i].id)
        if isWordComplete { evaluateCurrentWord() }
    }

    private func evaluateCurrentWord() {
        guard let pair = currentPair else { return }
        recalls.append(WordRecall(pair: pair, correct: built == target, usedHint: hintUsedThisWord))
    }

    /// Moves to the next word, or into feedback when the deck is done.
    func advanceAfterWord() {
        if promptIndex + 1 < prompts.count {
            promptIndex += 1
            loadCurrentWord()
        } else {
            phase = .feedback
        }
    }

    /// The just-finished word's outcome, for the reveal on the recall screen.
    var lastRecall: WordRecall? { recalls.last }

    func showSummary() { phase = .summary }

    func makeRetry() -> RetrievalSession { RetrievalSession(level: level) }
}
