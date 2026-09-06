//
//  ChunkingSession.swift
//  MemDoping
//
//  Drives a T03 Chunking mission: memorize a digit string by splitting it
//  into small groups, then reproduce it. Digits are used because grouping a
//  number the way you'd group a phone number is the canonical demonstration
//  of the effect (Miller, 1956) and needs no themed content.
//
//  See docs/techniques/chunking.md.
//

import Foundation
import Observation

@Observable
final class ChunkingSession {

    enum Phase: Equatable {
        case intro
        case group      // decide where the breaks go
        case study      // hold the chunked number
        case recall     // type it back
        case feedback
        case summary
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    /// The digits to memorize, one per element.
    private(set) var digits: [Int] = []
    /// Indices the player has broken the sequence at: a break at `i` means a
    /// new chunk starts before `digits[i]`.
    private(set) var breaks: Set<Int> = []
    /// What the player has typed back so far during recall.
    private(set) var entered: [Int] = []

    private(set) var studySecondsRemaining: Int

    init(level: GameLevel) {
        self.level = level
        self.studySecondsRemaining = level.memorizeSeconds
        digits = (0..<level.itemCount).map { _ in Int.random(in: 0...9) }
    }

    // MARK: - Chunking

    /// Chunk sizes the level nudges toward. Kept small on purpose: working
    /// memory holds roughly four chunks (Cowan, 2001), so the win comes from
    /// fewer, larger groups rather than more of them.
    var suggestedChunkSize: Int { 3 }

    var chunks: [[Int]] {
        var result: [[Int]] = []
        var current: [Int] = []
        for (i, digit) in digits.enumerated() {
            if i != 0 && breaks.contains(i) {
                result.append(current)
                current = []
            }
            current.append(digit)
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    /// A break can go anywhere except before the first digit.
    func toggleBreak(at index: Int) {
        guard phase == .group, index > 0, index < digits.count else { return }
        if breaks.contains(index) { breaks.remove(index) } else { breaks.insert(index) }
    }

    /// Grouping is the point of the exercise, so the player has to make at
    /// least one before moving on.
    var canStartStudying: Bool { !breaks.isEmpty }

    // MARK: - Recall

    var enteredChunks: [[Int]] {
        var result: [[Int]] = []
        var current: [Int] = []
        for (i, digit) in entered.enumerated() {
            if i != 0 && breaks.contains(i) {
                result.append(current)
                current = []
            }
            current.append(digit)
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    func enter(_ digit: Int) {
        guard phase == .recall, entered.count < digits.count else { return }
        entered.append(digit)
        if entered.count == digits.count { phase = .feedback }
    }

    func deleteLast() {
        guard phase == .recall, !entered.isEmpty else { return }
        entered.removeLast()
    }

    // MARK: - Scoring

    /// Scored per chunk, not per digit: recalling "497" as one unit is the
    /// skill being trained, so a chunk only counts when all of it is right.
    var correctChunks: Int {
        zip(chunks, enteredChunks).filter { $0 == $1 }.count
    }
    var totalChunks: Int { chunks.count }
    var accuracy: Double {
        totalChunks == 0 ? 0 : Double(correctChunks) / Double(totalChunks)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    /// Digit-level accuracy, shown alongside the chunk score so a near-miss
    /// doesn't read as a total loss.
    var correctDigits: Int {
        zip(digits, entered).filter { $0 == $1 }.count
    }

    // MARK: - Phase transitions

    func beginGrouping() { phase = .group }

    func beginStudying() {
        guard canStartStudying else { return }
        phase = .study
    }

    func tickStudyTimer() {
        guard phase == .study else { return }
        if studySecondsRemaining > 0 {
            studySecondsRemaining -= 1
        } else {
            phase = .recall
        }
    }

    func beginRecall() {
        guard phase == .study else { return }
        phase = .recall
    }

    func showSummary() { phase = .summary }

    func makeRetry() -> ChunkingSession { ChunkingSession(level: level) }
}
