//
//  AnalogyMissionView.swift
//  MemDoping
//
//  PACER A — "Where It Breaks". Sort each claim about a comparison into holds /
//  breaks, then recall which comparison failed where. The blind-spot line after
//  each analogy is the guide's "could a better one be built?" beat.
//

import SwiftUI

struct AnalogyMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: AnalogySession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var revealed = false

    init(level: GameLevel) {
        _session = State(initialValue: AnalogySession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(seed: session.level.index, quiet: true)

            Group {
                switch session.phase {
                case .intro:    introPhase
                case .critique: critiquePhase
                case .recall:   recallPhase
                case .feedback: feedbackPhase
                case .summary:  summaryPhase
                }
            }
            .padding()
            .transition(reduceMotion ? .opacity : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity))
        }
        .animation(reduceMotion ? nil : .easeInOut, value: session.phase)
        .navigationBarBackButtonHidden(session.phase != .intro)
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
                MissionStat("\(session.analogies.count)", "comparisons", "arrow.triangle.swap"),
                MissionStat("\(session.critiqueTotal)", "to judge", "scalemass"),
                MissionStat("\(session.totalQuestions)", "to recall", "checklist")
            ],
            onStart: { session.beginCritique() }
        )
    }

    // MARK: Critique — does this hold, or is this where it breaks?

    private var critiquePhase: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Test the comparison", systemImage: "scalemass.fill")
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(session.critiqueIndex + 1)/\(session.critiqueTotal)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Brand.accentText)
            }

            ProgressView(value: session.critiqueProgress).tint(Brand.accent)

            if let j = session.currentJudgement {
                VStack(spacing: 8) {
                    Symbol3DTile(symbol: j.analogy.symbol, tint: session.level.tileBase, size: 96)
                    Text(j.analogy.claim.localizedContent)
                        .font(.headline).foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                }

                GameTile(base: session.level.tileBase, cornerRadius: 16) {
                    Text(j.aspect.text.localizedContent)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                }

                if j.isAnswered {
                    verdictCard(j)
                    Spacer()
                    PrimaryButton(
                        title: session.critiqueIndex + 1 < session.critiqueTotal
                            ? "Next" : "Now recall",
                        systemImage: "arrow.right"
                    ) {
                        session.advanceAfterJudgement()
                    }
                } else {
                    HStack(spacing: 12) {
                        judgeButton(holds: true, title: "This holds",
                                    icon: "checkmark.circle.fill", tint: Brand.success, j: j)
                        judgeButton(holds: false, title: "Breaks here",
                                    icon: "bolt.horizontal.circle.fill", tint: Brand.danger, j: j)
                    }
                    Spacer()
                }
            }
        }
        .id(session.critiqueIndex)
    }

    private func judgeButton(holds: Bool, title: LocalizedStringKey, icon: String,
                             tint: Color, j: AnalogySession.Judgement) -> some View {
        Button {
            session.judge(holds: holds)
            let ok = holds == j.aspect.holds
            if store.soundEnabled { SoundPlayer.shared.play(ok ? .correct : .incorrect) }
            if store.hapticsEnabled { HapticsPlayer.shared.notify(success: ok) }
        } label: {
            GameTile(base: tint, cornerRadius: 16) {
                VStack(spacing: 6) {
                    Image(systemName: icon).font(.title2)
                    Text(title).font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Brand.text)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(TileButtonStyle())
    }

    private func verdictCard(_ j: AnalogySession.Judgement) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: j.isCorrect ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(j.isCorrect ? Brand.successText : Brand.accent)
                Text(j.aspect.holds
                     ? "This part of the comparison does hold."
                     : "This is where the comparison breaks.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Spacer(minLength: 4)
            }
            if !j.isCorrect {
                Text("Worth a second look — a comparison that's never tested at its edges turns into a belief.")
                    .font(.caption).foregroundStyle(Brand.text.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Brand.primary.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.text.opacity(0.15), lineWidth: 1))
    }

    // MARK: Recall — which comparison broke where?

    private var recallPhase: some View {
        VStack(spacing: 16) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("Where did this one break?")
                .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)

            if let q = session.currentQuestion {
                VStack(spacing: 8) {
                    Symbol3DTile(symbol: q.analogy.symbol, tint: session.level.tileBase,
                                 size: 96, celebrate: revealed && q.isCorrect)
                    Text(q.analogy.claim.localizedContent)
                        .font(.headline).foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                }

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(q.options.enumerated()), id: \.element) { i, option in
                            answerButton(option, question: q).dealIn(i)
                        }
                    }
                }

                if revealed {
                    Card {
                        Label {
                            Text(q.analogy.blindSpot.localizedContent)
                                .font(.subheadline).foregroundStyle(Brand.text.opacity(0.85))
                        } icon: {
                            Image(systemName: "eye.trianglebadge.exclamationmark")
                                .foregroundStyle(Brand.accentText)
                        }
                    }

                    PrimaryButton(
                        title: session.recallIndex + 1 < session.totalQuestions ? "Next" : "Finish",
                        systemImage: "arrow.right"
                    ) {
                        revealed = false
                        session.advanceAfterAnswer()
                    }
                }
            }
        }
        .id(session.recallIndex)
    }

    private func answerButton(_ option: String, question q: AnalogySession.RecallQ) -> some View {
        let isChosen = q.chosen == option
        let isCorrectAnswer = option == q.answer
        var base = session.level.tileBase
        if revealed {
            if isCorrectAnswer { base = Brand.success }
            else if isChosen { base = Brand.danger }
        }
        return Button {
            guard !revealed else { return }
            session.answerCurrent(option)
            revealed = true
            if store.soundEnabled { SoundPlayer.shared.play(isCorrectAnswer ? .correct : .incorrect) }
            if store.hapticsEnabled { HapticsPlayer.shared.notify(success: isCorrectAnswer) }
        } label: {
            GameTile(base: base, cornerRadius: 14) {
                HStack {
                    Text(option.localizedContent)
                        .foregroundStyle(Brand.text).fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    if revealed && isCorrectAnswer {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.text)
                    } else if revealed && isChosen {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Brand.text)
                    }
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
            }
            .scaleEffect(isChosen && revealed ? 1.04 : 1.0)
            .modifier(ShakeEffect(animatableData:
                (revealed && isChosen && !isCorrectAnswer && !reduceMotion) ? 1 : 0))
        }
        .buttonStyle(TileButtonStyle())
        .disabled(revealed)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.55), value: revealed)
    }

    // MARK: Feedback

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("What the comparisons couldn't carry")
                .font(.title2.bold()).foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
            Text("\(session.correctCount) of \(session.totalQuestions) recalled · \(session.critiqueCorrect)/\(session.critiqueTotal) judged")
                .font(.subheadline).foregroundStyle(Brand.text.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.questions.enumerated()), id: \.element.id) { i, q in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 10) {
                                Text(q.analogy.symbol).font(.title3)
                                Text(q.analogy.target.localizedContent)
                                    .font(.headline).foregroundStyle(Brand.text)
                                Spacer(minLength: 6)
                                Image(systemName: q.isCorrect ? "checkmark.circle.fill"
                                                              : "xmark.circle.fill")
                                    .foregroundStyle(q.isCorrect ? Brand.successText : Brand.danger)
                            }
                            Text(q.answer.localizedContent)
                                .font(.caption).foregroundStyle(Brand.text.opacity(0.75))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Brand.text.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .dealIn(i)
                    }
                }
            }

            Card {
                Label {
                    Text("An analogy is a shortcut, not the thing itself. Knowing where it stops fitting is what keeps it useful instead of misleading.")
                        .font(.subheadline).foregroundStyle(Brand.text.opacity(0.85))
                } icon: {
                    Image(systemName: "arrow.triangle.swap").foregroundStyle(Brand.accentText)
                }
            }

            PrimaryButton(title: "See results", systemImage: "arrow.right") {
                let result = store.complete(
                    level: session.level,
                    correct: session.correctCount,
                    total: session.totalQuestions
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
                revealed = false
            },
            onExit: { dismiss() }
        )
    }
}

#Preview("Analogy — where it breaks") {
    AnalogyMissionView(level: SampleLevels.level(at: 14)!)
        .environment(GameStore())
}
