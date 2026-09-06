//
//  ReviewSession.swift
//  MemDoping
//
//  Drives a T05 spaced-review mini-mission: a short, low-friction pass over the
//  items that have come due, tested with the same free-recall letter tiles as
//  T04. There's no study phase — the whole point is delayed recall, so the item
//  is shown cold. Outcomes feed the Retention indicator, and each item is
//  rescheduled by GameStore. Framing is welcoming, never punitive (§6).
//
//  See docs/techniques/spaced-practice.md.
//

import Foundation
import Observation

@Observable
final class ReviewSession {

    enum Phase: Equatable { case intro, recall, summary }

    private(set) var phase: Phase = .intro

    /// The due items being reviewed this round (capped for a short session).
    let items: [ReviewRecord]
    private(set) var index: Int = 0

    // Letter-tile recall state for the current item (mirrors RetrievalSession).
    private(set) var tray: [LetterTile] = []
    private(set) var placed: [UUID] = []
    private(set) var hintUsedThisWord = false

    /// Per-item outcome: did the player remember it after the delay?
    private(set) var outcomes: [(key: String, remembered: Bool)] = []

    static let maxItemsPerRound = 5

    init(items: [ReviewRecord]) {
        self.items = Array(items.prefix(Self.maxItemsPerRound))
    }

    // MARK: - Current item

    var currentItem: ReviewRecord? {
        items.indices.contains(index) ? items[index] : nil
    }

    /// Word to rebuild, upper-cased in the display language.
    var target: String { (currentItem?.word.localizedContent ?? "").uppercased() }

    var built: String {
        String(placed.compactMap { id in tray.first { $0.id == id }?.letter })
    }
    var isWordComplete: Bool { built.count >= target.count }

    private var nextNeededLetter: Character? {
        let i = built.count
        return i < target.count ? Array(target)[i] : nil
    }
    var canUseHint: Bool { phase == .recall && nextNeededLetter != nil }

    var progress: Double {
        items.isEmpty ? 0 : Double(index) / Double(items.count)
    }
    var rememberedCount: Int { outcomes.filter { $0.remembered }.count }

    /// The just-evaluated item's outcome, for the on-screen reveal.
    var lastOutcome: (key: String, remembered: Bool)? { outcomes.last }

    // MARK: - Flow

    func begin() {
        phase = .recall
        loadCurrentWord()
    }

    private func loadCurrentWord() {
        placed = []
        hintUsedThisWord = false
        tray = target.map { LetterTile(letter: $0) }.shuffled()
        if tray.map(\.letter) == Array(target) && target.count > 1 { tray.reverse() }
    }

    func place(tileID: UUID) {
        guard phase == .recall,
              let i = tray.firstIndex(where: { $0.id == tileID }), !tray[i].used else { return }
        tray[i].used = true
        placed.append(tileID)
        if isWordComplete { evaluate() }
    }

    func removeLast() {
        guard phase == .recall, let last = placed.popLast(),
              let i = tray.firstIndex(where: { $0.id == last }) else { return }
        tray[i].used = false
    }

    func useHint() {
        guard let needed = nextNeededLetter,
              let i = tray.firstIndex(where: { !$0.used && $0.letter == needed }) else { return }
        hintUsedThisWord = true
        tray[i].used = true
        placed.append(tray[i].id)
        if isWordComplete { evaluate() }
    }

    private func evaluate() {
        guard let item = currentItem else { return }
        // A hinted answer doesn't count as "remembered from memory" for
        // retention — the point is unaided delayed recall.
        let remembered = built == target && !hintUsedThisWord
        outcomes.append((key: item.key, remembered: remembered))
    }

    func advance() {
        if index + 1 < items.count {
            index += 1
            loadCurrentWord()
        } else {
            phase = .summary
        }
    }
}
