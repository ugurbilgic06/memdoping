//
//  StorySession.swift
//  MemDoping
//
//  Drives a T08 Story Linking mission ("Zincir Hikâye"). Items are shown in
//  order; for each step the player picks an action linking the previous item to
//  the next, building one chained mini-story. Recall then tests the *order*
//  (serial recall) — the dimension Bower & Clark (1969) measured. Any sensible
//  link is fine; there's no single "right" story, which keeps it low-pressure.
//
//  See docs/techniques/story-linking.md.
//

import Foundation
import Observation

@Observable
final class StorySession {

    enum Phase: Equatable { case intro, build, recall, feedback, summary }

    /// One link between consecutive items, with its action choices.
    struct Link: Identifiable {
        let id = UUID()
        let from: MemoryPair
        let to: MemoryPair
        let options: [String]
        var chosen: String?
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    /// The ordered sequence to learn.
    private(set) var items: [MemoryPair] = []
    private(set) var links: [Link] = []
    private(set) var linkIndex: Int = 0

    // Recall (serial order reconstruction).
    private(set) var tray: [MemoryPair] = []
    private(set) var rebuilt: [MemoryPair] = []

    init(level: GameLevel) {
        self.level = level
        buildRun()
    }

    private func buildRun() {
        items = Array(level.theme.pairs.shuffled().prefix(max(2, level.itemCount)))
        links = (1..<items.count).map { i in
            let opts = Array(SampleContent.storyActions.shuffled().prefix(3))
            return Link(from: items[i - 1], to: items[i], options: opts)
        }
        tray = items.shuffled()
    }

    // MARK: - Build phase

    var currentLink: Link? {
        links.indices.contains(linkIndex) ? links[linkIndex] : nil
    }
    var buildProgress: Double {
        links.isEmpty ? 0 : Double(linkIndex) / Double(links.count)
    }

    func beginBuilding() { phase = .build }

    func chooseAction(_ action: String) {
        guard phase == .build, links.indices.contains(linkIndex),
              links[linkIndex].chosen == nil else { return }
        links[linkIndex].chosen = action
    }

    func advanceAfterLink() {
        if linkIndex + 1 < links.count {
            linkIndex += 1
        } else {
            phase = .recall
        }
    }

    // MARK: - Recall phase (serial order)

    func isUsed(_ pair: MemoryPair) -> Bool { rebuilt.contains { $0.id == pair.id } }

    var nextPosition: Int { rebuilt.count }
    var recallProgress: Double {
        items.isEmpty ? 0 : Double(rebuilt.count) / Double(items.count)
    }

    func placeNext(_ pair: MemoryPair) {
        guard phase == .recall, !isUsed(pair), rebuilt.count < items.count else { return }
        rebuilt.append(pair)
        if rebuilt.count == items.count { phase = .feedback }
    }

    func undoLast() {
        guard phase == .recall, !rebuilt.isEmpty else { return }
        rebuilt.removeLast()
    }

    /// Was the item at recall position `i` the correct one for that spot?
    func isPositionCorrect(_ i: Int) -> Bool {
        rebuilt.indices.contains(i) && items.indices.contains(i)
            && rebuilt[i].id == items[i].id
    }

    // MARK: - Scoring

    var correctCount: Int {
        (0..<rebuilt.count).filter { isPositionCorrect($0) }.count
    }
    var totalItems: Int { items.count }
    var accuracy: Double {
        totalItems == 0 ? 0 : Double(correctCount) / Double(totalItems)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    func showSummary() { phase = .summary }
    func makeRetry() -> StorySession { StorySession(level: level) }
}
