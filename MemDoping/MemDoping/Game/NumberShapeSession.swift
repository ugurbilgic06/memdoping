//
//  NumberShapeSession.swift
//  MemDoping
//
//  Drives a T11 Number-Shape mission ("Şekil-Sayı Kod"): each digit maps to a
//  shape image (1 = candle, 2 = swan, 8 = snowman …). The player memorizes a
//  number shown as shapes, then types it back. This blends chunking and imagery;
//  the technique's own evidence is weak, so it's clearly sample content and
//  makes no exaggerated claims. See docs/techniques/number-system.md.
//

import Foundation
import Observation

@Observable
final class NumberShapeSession {

    enum Phase: Equatable { case intro, study, recall, feedback, summary }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    /// The code to memorize, one digit per element.
    private(set) var digits: [Int] = []
    /// What the player has typed back.
    private(set) var entered: [Int] = []
    private(set) var studySecondsRemaining: Int

    init(level: GameLevel) {
        self.level = level
        self.studySecondsRemaining = level.memorizeSeconds
        digits = (0..<max(3, level.itemCount)).map { _ in Int.random(in: 0...9) }
    }

    // MARK: Shape code (index = digit)

    func shape(for digit: Int) -> String {
        SampleContent.numberShapes.indices.contains(digit) ? SampleContent.numberShapes[digit] : "?"
    }
    func shapeName(for digit: Int) -> String {
        SampleContent.numberShapeNames.indices.contains(digit) ? SampleContent.numberShapeNames[digit] : ""
    }
    /// The digit-shape legend, shown as a learning aid (guided levels).
    var legend: [(digit: Int, shape: String)] {
        (0...9).map { ($0, shape(for: $0)) }
    }

    // MARK: - Phases

    func beginStudying() { phase = .study }

    func tickStudyTimer() {
        guard phase == .study else { return }
        if studySecondsRemaining > 0 { studySecondsRemaining -= 1 }
        else { phase = .recall }
    }

    func beginRecall() {
        guard phase == .study else { return }
        phase = .recall
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

    func showSummary() { phase = .summary }

    // MARK: - Scoring (correct digits in the right position)

    func isPositionCorrect(_ i: Int) -> Bool {
        entered.indices.contains(i) && digits.indices.contains(i) && entered[i] == digits[i]
    }
    var correctCount: Int { (0..<entered.count).filter { isPositionCorrect($0) }.count }
    var total: Int { digits.count }
    var accuracy: Double { total == 0 ? 0 : Double(correctCount) / Double(total) }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    func makeRetry() -> NumberShapeSession { NumberShapeSession(level: level) }
}
