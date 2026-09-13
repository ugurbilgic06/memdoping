//
//  ProcedureMissionView.swift
//  MemDoping
//
//  PACER P — "Do It Yourself". Watch the procedure once, then run it from
//  memory. A wrong move brings up the corrective instead of a penalty screen:
//  the guide treats feedback as the thing that repairs procedural knowledge.
//

import SwiftUI

struct ProcedureMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: ProcedureSession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var studyTimer: Timer?

    init(level: GameLevel) {
        _session = State(initialValue: ProcedureSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(seed: session.level.index, quiet: true)

            Group {
                switch session.phase {
                case .intro:    introPhase
                case .study:    studyPhase
                case .perform:  performPhase
                case .feedback: feedbackPhase
                case .summary:  summaryPhase
                }
            }
            .padding()
            .transition(reduceMotion ? .opacity : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity))

            if let correction = session.correction {
                correctionOverlay(correction)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(2)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut, value: session.phase)
        .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.8),
                   value: session.correction?.id)
        .navigationBarBackButtonHidden(session.phase != .intro)
        .onChange(of: session.phase) { _, p in if p != .study { stopTimer() } }
        .onDisappear { stopTimer() }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if session.phase != .intro && session.phase != .summary {
                    Button("Quit") { dismiss() }
                        .foregroundStyle(Brand.text.opacity(0.8))
                }
            }
        }
    }

    // MARK: Intro

    private var introPhase: some View {
        MissionIntro(
            level: session.level,
            stats: [
                MissionStat("\(session.totalSteps)", "steps", "list.number"),
                MissionStat("\(session.level.memorizeSeconds)s", "to watch", "timer"),
                MissionStat("0", "notes allowed", "eye.slash")
            ],
            onStart: { startStudy() }
        )
    }

    // MARK: Study — the one look at the procedure

    private func startStudy() {
        session.beginStudy()
        stopTimer()
        studyTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            session.tickStudyTimer()
        }
    }

    private func stopTimer() {
        studyTimer?.invalidate()
        studyTimer = nil
    }

    private var studyPhase: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Watch once", systemImage: "eye.fill")
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(session.secondsLeft)s")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(session.secondsLeft <= 3 ? Brand.danger : Brand.accentText)
            }

            Text(session.procedure.title.localizedContent)
                .font(.title2.bold()).foregroundStyle(Brand.text)
            Text(session.procedure.goal.localizedContent)
                .font(.subheadline).foregroundStyle(Brand.text.opacity(0.75))
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.steps.enumerated()), id: \.element.id) { i, step in
                        HStack(spacing: 12) {
                            Text("\(i + 1)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Brand.text.opacity(0.55))
                                .frame(width: 22)
                            Text(step.icon).font(.title2)
                            Text(step.text.localizedContent)
                                .font(.subheadline).foregroundStyle(Brand.text)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 4)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Brand.text.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .dealIn(i)
                    }
                }
            }

            PrimaryButton(title: "I'm ready — hide it", systemImage: "eye.slash") {
                stopTimer()
                session.beginPerforming()
            }
        }
    }

    // MARK: Perform — run it unaided

    private var performPhase: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Your turn", systemImage: "hand.tap.fill")
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(session.placed.count)/\(session.totalSteps)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Brand.accentText)
            }

            ProgressView(value: session.progress).tint(Brand.accent)

            Text(session.procedure.goal.localizedContent)
                .font(.subheadline).foregroundStyle(Brand.text.opacity(0.75))
                .multilineTextAlignment(.center)

            if !session.placed.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(session.placed.enumerated()), id: \.element.id) { i, step in
                            VStack(spacing: 2) {
                                Text(step.icon).font(.title3)
                                Text("\(i + 1)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(Brand.text.opacity(0.6))
                            }
                            .padding(8)
                            .background(Brand.success.opacity(0.30),
                                        in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(height: 58)
            }

            Text("What comes next?")
                .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.tray.enumerated()), id: \.element.id) { i, step in
                        stepButton(step).dealIn(i)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func stepButton(_ step: ProcedureStep) -> some View {
        Button {
            let ok = session.attempt(step)
            if store.soundEnabled { SoundPlayer.shared.play(ok ? .correct : .incorrect) }
            if store.hapticsEnabled { HapticsPlayer.shared.notify(success: ok) }
        } label: {
            GameTile(base: session.level.tileBase, cornerRadius: 14) {
                HStack(spacing: 12) {
                    Text(step.icon).font(.title2)
                    Text(step.text.localizedContent)
                        .foregroundStyle(Brand.text).fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(TileButtonStyle())
        .disabled(session.correction != nil)
    }

    // MARK: The corrective — the heart of this mechanic

    private func correctionOverlay(_ correction: ProcedureSession.Misstep) -> some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: correction.isTrap
                      ? "hand.raised.fill" : "arrow.uturn.backward.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Brand.accentText)

                Text(correction.isTrap ? "That's not part of this" : "Not yet")
                    .font(.title3.bold()).foregroundStyle(Brand.text)

                Text(correction.step.why.localizedContent)
                    .font(.subheadline).foregroundStyle(Brand.text.opacity(0.85))
                    .multilineTextAlignment(.center)

                Divider().opacity(0.3)

                VStack(spacing: 6) {
                    Text("What belongs here")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.text.opacity(0.6))
                    HStack(spacing: 10) {
                        Text(correction.expected.icon).font(.title2)
                        Text(correction.expected.text.localizedContent)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                            .multilineTextAlignment(.leading)
                    }
                    Text(correction.expected.why.localizedContent)
                        .font(.caption).foregroundStyle(Brand.text.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(title: "Try again", systemImage: "arrow.clockwise") {
                    session.acknowledgeCorrection()
                }
            }
            .padding(22)
            .background {
                GlossyTile(cornerRadius: 22) { Color.clear }
            }
            .padding(28)
        }
    }

    // MARK: Feedback

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("You ran it")
                .font(.title2.bold()).foregroundStyle(Brand.text)
            Text("\(session.correctCount) of \(session.totalSteps) right first time")
                .foregroundStyle(Brand.text.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.steps.enumerated()), id: \.element.id) { i, step in
                        let stumbled = session.missteps.contains { $0.position == i }
                        HStack(spacing: 12) {
                            Text("\(i + 1)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(Brand.text.opacity(0.5))
                                .frame(width: 20)
                            Text(step.icon).font(.title3)
                            Text(step.text.localizedContent)
                                .font(.subheadline).foregroundStyle(Brand.text)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 6)
                            Image(systemName: stumbled ? "arrow.uturn.backward.circle.fill"
                                                       : "checkmark.circle.fill")
                                .foregroundStyle(stumbled ? Brand.accent : Brand.successText)
                        }
                        .padding(12)
                        .background(Brand.text.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .dealIn(i)
                    }
                }
            }

            Card {
                Label {
                    Text(session.trapsTaken > 0
                         ? "Some of those moves belonged to a different job. Spotting what isn't part of a procedure is half of knowing it."
                         : "A procedure is learned by running it, not by reading it. The steps you had to be shown are the ones to run again.")
                        .font(.subheadline).foregroundStyle(Brand.text.opacity(0.85))
                } icon: {
                    Image(systemName: "figure.walk").foregroundStyle(Brand.accentText)
                }
            }

            PrimaryButton(title: "See results", systemImage: "arrow.right") {
                let result = store.complete(
                    level: session.level,
                    correct: session.correctCount,
                    total: session.totalSteps
                )
                outcome = result
                if store.soundEnabled { SoundPlayer.shared.play(result.mastered ? .levelUp : .correct) }
                if store.hapticsEnabled { HapticsPlayer.shared.notify(success: result.mastered) }
                session.showSummary()
            }
        }
    }

    // MARK: Summary

    private var summaryPhase: some View {
        MissionSummary(
            passedMastery: session.passedMastery,
            accuracy: session.accuracy,
            outcome: outcome,
            onRetry: {
                session = session.makeRetry()
                outcome = nil
                stopTimer()
            },
            onExit: { dismiss() }
        )
    }
}

#Preview("Procedure — do it yourself") {
    ProcedureMissionView(level: SampleLevels.level(at: 13)!)
        .environment(GameStore())
}
