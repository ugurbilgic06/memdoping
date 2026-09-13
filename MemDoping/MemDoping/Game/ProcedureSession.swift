//
//  ProcedureSession.swift
//  MemDoping
//
//  PACER **P** — Procedural knowledge, whose operation is *Practice*.
//
//  The guide (p.3) is specific about what learning a procedure means:
//    • don't just underline it — carry it out as soon as you can,
//    • treat mistakes as part of learning, because feedback is what corrects
//      procedural knowledge,
//    • the real test is performing it *without looking at the source*.
//
//  So this mission shows the procedure once, takes it away, and asks the player
//  to run it. A wrong move isn't a lost point and a red cross: the step explains
//  why it belongs where it does, and the player tries again. Only steps placed
//  right on the first attempt count toward the score, so the corrective is
//  genuinely free but not free of consequence.
//
//  The tray also holds "traps" — plausible moves borrowed from a different job.
//  Knowing what is *not* part of a procedure is part of knowing the procedure.
//
//  SAMPLE CONTENT: the procedures are everyday ones (see SampleContent), chosen
//  because their order is causal and can therefore be explained, not a final
//  curriculum.
//

import Foundation
import Observation

@Observable
final class ProcedureSession {

    enum Phase: Equatable {
        case intro
        case study      // watch the procedure once
        case perform    // run it from memory
        case feedback
        case summary
    }

    /// A wrong move, kept for the debrief.
    struct Misstep: Identifiable {
        let id = UUID()
        let step: ProcedureStep
        /// The position the player was trying to fill (0-based).
        let position: Int
        /// True when the step isn't part of this procedure at all.
        let isTrap: Bool
        /// What should have gone here.
        let expected: ProcedureStep
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    private(set) var procedure: Procedure
    /// The ordered steps this run asks for (a prefix — order is never shuffled).
    private(set) var steps: [ProcedureStep] = []
    /// Steps still available to pick, shuffled, traps mixed in.
    private(set) var tray: [ProcedureStep] = []
    /// What the player has carried out so far, in the order they chose.
    private(set) var placed: [ProcedureStep] = []

    private(set) var missteps: [Misstep] = []
    /// Steps placed correctly at the first attempt — the score.
    private(set) var firstTryCount: Int = 0
    /// The correction currently on screen; nil when the player may continue.
    private(set) var correction: Misstep?

    /// Seconds left in the one look at the procedure. Owned here rather than in
    /// the view, matching the other timed mechanics.
    private(set) var secondsLeft: Int = 0

    private var erredHere = false
    private var trapIDs: Set<UUID> = []

    init(level: GameLevel) {
        self.level = level
        self.procedure = level.procedure ?? SampleContent.procedures[0]
        buildRun()
    }

    private func buildRun() {
        // prefix, never shuffled: a procedure's order is the content.
        let wanted = min(procedure.steps.count, max(3, level.itemCount))
        steps = Array(procedure.steps.prefix(wanted))

        let traps = Array(procedure.traps.shuffled().prefix(2))
        trapIDs = Set(traps.map(\.id))
        tray = (steps + traps).shuffled()
    }

    // MARK: - Study

    func beginStudy() {
        phase = .study
        secondsLeft = max(6, level.memorizeSeconds)
    }

    /// Drives the study countdown; the view only supplies the tick.
    func tickStudyTimer() {
        guard phase == .study else { return }
        if secondsLeft > 1 {
            secondsLeft -= 1
        } else {
            secondsLeft = 0
            beginPerforming()
        }
    }

    /// Hides the procedure and starts the unaided run (guide p.3: the test is
    /// performing it without the source in front of you).
    func beginPerforming() {
        guard phase == .study else { return }
        phase = .perform
    }

    // MARK: - Perform

    /// The step the procedure expects next, or nil once it's complete.
    var expectedStep: ProcedureStep? {
        steps.indices.contains(placed.count) ? steps[placed.count] : nil
    }

    var nextPosition: Int { placed.count }
    var progress: Double {
        steps.isEmpty ? 0 : Double(placed.count) / Double(steps.count)
    }

    func isTrap(_ step: ProcedureStep) -> Bool { trapIDs.contains(step.id) }

    /// Tries to carry out `step` at the current position.
    /// Correct → it's placed and removed from the tray.
    /// Wrong → nothing moves, and a correction is raised explaining the step
    /// that *should* come next. The player keeps going from the same position.
    @discardableResult
    func attempt(_ step: ProcedureStep) -> Bool {
        guard phase == .perform, correction == nil,
              let expected = expectedStep else { return false }

        if step.id == expected.id {
            if !erredHere { firstTryCount += 1 }
            erredHere = false
            placed.append(step)
            tray.removeAll { $0.id == step.id }
            if placed.count == steps.count { phase = .feedback }
            return true
        }

        missteps.append(
            Misstep(step: step, position: placed.count,
                    isTrap: isTrap(step), expected: expected)
        )
        correction = missteps.last
        erredHere = true
        return false
    }

    /// Dismisses the corrective and lets the player try the same position again.
    func acknowledgeCorrection() { correction = nil }

    // MARK: - Scoring

    /// Only unaided placements count (guide p.3).
    var correctCount: Int { firstTryCount }
    var totalSteps: Int { steps.count }
    var accuracy: Double {
        totalSteps == 0 ? 0 : Double(correctCount) / Double(totalSteps)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    /// Wrong moves that were never part of the procedure at all.
    var trapsTaken: Int { missteps.filter(\.isTrap).count }

    func showSummary() { phase = .summary }
    func makeRetry() -> ProcedureSession { ProcedureSession(level: level) }
}
