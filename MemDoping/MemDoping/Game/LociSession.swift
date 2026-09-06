//
//  LociSession.swift
//  MemDoping
//
//  Drives a T09 Method of Loci mission ("Hafıza Sarayı"): the player walks a
//  familiar route, leaving one item at each stop, then walks it again and
//  recalls what was left where. Scored on stop→item matches in order (serial
//  recall) — the same measure Maguire (2003) and the 2025 meta-analysis use.
//  The framing is deliberately anti-"talent": this is a learnable strategy, the
//  most direct in-game support for §9's "not an IQ/ability" boundary.
//
//  See docs/techniques/method-of-loci.md.
//

import Foundation
import Observation

@Observable
final class LociSession {

    enum Phase: Equatable {
        case intro
        case place      // walk forward, drop an item at each stop
        case recall     // walk again, recall what's at each stop
        case feedback
        case summary
    }

    /// A stop with the item the player left there.
    struct Placement: Identifiable {
        let id = UUID()
        let stop: RouteStop
        let item: MemoryPair
    }

    /// One recall attempt at a stop.
    struct Pick: Identifiable {
        let id = UUID()
        let placement: Placement
        let chosenItem: MemoryPair
        var correct: Bool { chosenItem.id == placement.item.id }
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    private(set) var placements: [Placement] = []
    private(set) var placeIndex: Int = 0

    private(set) var recallIndex: Int = 0
    private(set) var usedItemIDs: Set<UUID> = []
    private(set) var picks: [Pick] = []

    /// The item pool shown during recall, in a fixed shuffled order so tiles
    /// don't jump around between stops.
    private(set) var itemTray: [MemoryPair] = []

    init(level: GameLevel) {
        self.level = level
        buildRun()
    }

    private func buildRun() {
        let route = level.route ?? SampleContent.home
        let stops = Array(route.stops.prefix(level.itemCount))
        let items = Array(level.theme.pairs.shuffled().prefix(stops.count))
        placements = zip(stops, items).map { Placement(stop: $0, item: $1) }
        itemTray = placements.map(\.item).shuffled()
    }

    // MARK: - Place phase

    var currentPlacement: Placement? {
        placements.indices.contains(placeIndex) ? placements[placeIndex] : nil
    }
    var placeProgress: Double {
        placements.isEmpty ? 0 : Double(placeIndex) / Double(placements.count)
    }

    func beginPlacing() { phase = .place }

    /// Confirms the current stop's item is "left" there and moves on.
    func placeCurrent() {
        guard phase == .place else { return }
        if placeIndex + 1 < placements.count {
            placeIndex += 1
        } else {
            phase = .recall
        }
    }

    // MARK: - Recall phase

    var currentStop: RouteStop? {
        placements.indices.contains(recallIndex) ? placements[recallIndex].stop : nil
    }
    var recallProgress: Double {
        placements.isEmpty ? 0 : Double(recallIndex) / Double(placements.count)
    }
    func isItemUsed(_ item: MemoryPair) -> Bool { usedItemIDs.contains(item.id) }

    /// Records the player's pick for the current stop.
    func pick(_ item: MemoryPair) {
        guard phase == .recall, !isItemUsed(item),
              placements.indices.contains(recallIndex) else { return }
        usedItemIDs.insert(item.id)
        picks.append(Pick(placement: placements[recallIndex], chosenItem: item))
    }

    var lastPick: Pick? { picks.last }

    /// Advances to the next stop, or into feedback when the route is done.
    func advanceAfterPick() {
        if recallIndex + 1 < placements.count {
            recallIndex += 1
        } else {
            phase = .feedback
        }
    }

    // MARK: - Scoring

    var correctCount: Int { picks.filter(\.correct).count }
    var totalStops: Int { placements.count }
    var accuracy: Double {
        totalStops == 0 ? 0 : Double(correctCount) / Double(totalStops)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    /// The pairs placed this run, for spaced-review scheduling.
    var placedPairs: [MemoryPair] { placements.map(\.item) }

    func showSummary() { phase = .summary }
    func makeRetry() -> LociSession { LociSession(level: level) }
}
