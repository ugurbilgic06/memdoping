//
//  ElaborationMissionView.swift
//  MemDoping
//
//  T07 Elaboration ("Neden Böyle?"). Pick the plausible reason for each fact,
//  then recall which reason went with which fact. The intro/feedback are honest
//  that this helps most on familiar material for players with some background
//  (§9 conditional benefit).
//

import SwiftUI

struct ElaborationMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.goToStart) private var goToStart
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: ElaborationSession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var revealed = false

    init(level: GameLevel) {
        _session = State(initialValue: ElaborationSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(seed: session.level.index, quiet: true)

            Group {
                switch session.phase {
                case .intro:     introPhase
                case .elaborate: elaboratePhase
                case .recall:    recallPhase
                case .feedback:  feedbackPhase
                case .summary:   summaryPhase
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
            // Straight back to the worlds from anywhere in the mission.
            ToolbarItem(placement: .topBarTrailing) {
                Button { goToStart() } label: {
                    // A plain nav-bar glyph was too faint to notice, so it
                    // sits on a solid capsule.
                    Image(systemName: "house.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11).padding(.vertical, 7)
                        .background(Brand.accent, in: Capsule())
                        .shadow(color: Brand.accent.opacity(0.45), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Back to home"))
            }
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
                MissionStat("\(session.level.itemCount)", "reasons", "questionmark.bubble"),
                MissionStat("\(session.level.questionCount)", "to recall", "checklist"),
                MissionStat("?", "not just what", "lightbulb")
            ],
            onStart: { session.beginElaborating() }
        )
    }

    // MARK: Elaborate — pick the plausible reason

    private var elaboratePhase: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Ask why", systemImage: "questionmark.bubble.fill")
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(session.elaborateIndex + 1)/\(session.cards.count)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Brand.accentText)
            }

            ProgressView(value: session.elaborateProgress).tint(Brand.accent)

            if let card = session.currentCard {
                Spacer()
                VStack(spacing: 10) {
                    Symbol3DTile(symbol: card.fact.symbol, tint: session.level.tileBase, size: 116)
                    Text("\(card.fact.subject.localizedContent)…")
                        .font(.title3.bold())
                        .foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                    Text("…because?")
                        .font(.subheadline).foregroundStyle(Brand.text.opacity(0.7))
                }

                if card.chosen == nil {
                    VStack(spacing: 10) {
                        ForEach(card.options, id: \.self) { option in
                            reasonButton(card: card, option: option)
                        }
                    }
                    Spacer()
                } else {
                    chosenReasonCard(card)
                    Spacer()
                    PrimaryButton(
                        title: session.elaborateIndex + 1 < session.cards.count ? "Next" : "Now recall",
                        systemImage: "arrow.right"
                    ) {
                        revealed = false
                        session.advanceAfterReason()
                    }
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: session.currentCard?.chosen)
    }

    private func reasonButton(card: ElaborationSession.ReasonCard, option: String) -> some View {
        Button {
            session.chooseReason(option)
            let ok = option == card.fact.because
            if store.soundEnabled { SoundPlayer.shared.play(ok ? .correct : .incorrect) }
            if store.hapticsEnabled { HapticsPlayer.shared.notify(success: ok) }
        } label: {
            GameTile(base: session.level.tileBase, cornerRadius: 14) {
                HStack {
                    Text(option.localizedContent).foregroundStyle(Brand.text).fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func chosenReasonCard(_ card: ElaborationSession.ReasonCard) -> some View {
        let correct = card.chosenCorrectly
        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: correct ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(correct ? Brand.successText : Brand.accent)
                Text("\(card.fact.subject.localizedContent) because \(card.fact.because.localizedContent).")
                    .font(.subheadline).foregroundStyle(Brand.text)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
            }
            if !correct {
                Text("You picked another reason — the one above is the sound one.")
                    .font(.caption).foregroundStyle(Brand.text.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Brand.primary.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.text.opacity(0.15), lineWidth: 1))
    }

    // MARK: Recall — which reason went with which fact

    private var recallPhase: some View {
        VStack(spacing: 18) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("Why was it?")
                .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)

            if let q = session.currentQuestion {
                VStack(spacing: 8) {
                    Symbol3DTile(symbol: q.fact.symbol, tint: session.level.tileBase, size: 116,
                                 celebrate: revealed && q.isCorrect)
                    Text(q.fact.subject.localizedContent)
                        .font(.headline).foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    ForEach(Array(q.options.enumerated()), id: \.element) { i, option in
                        answerButton(option, question: q).dealIn(i)
                    }
                }

                Spacer()

                if revealed {
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

    private func answerButton(_ option: String, question q: ElaborationSession.RecallQ) -> some View {
        let isChosen = q.chosen == option
        let isCorrectAnswer = option == q.fact.because
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
                    Text(option.localizedContent).foregroundStyle(Brand.text).fontWeight(.medium)
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
            .scaleEffect(isChosen && revealed ? 1.05 : 1.0)
            .flipReveal(revealed && isChosen && isCorrectAnswer && !reduceMotion)
            .modifier(ShakeEffect(animatableData:
                (revealed && isChosen && !isCorrectAnswer && !reduceMotion) ? 1 : 0))
            .overlay { if revealed && isCorrectAnswer && !reduceMotion { ConfettiBurst() } }
        }
        .buttonStyle(TileButtonStyle())
        .disabled(revealed)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.55), value: revealed)
    }

    // MARK: Feedback

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("The reasons that stuck")
                .font(.title2.bold()).foregroundStyle(Brand.text)
            Text("\(session.correctCount) of \(session.totalQuestions) recalled")
                .foregroundStyle(Brand.text.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.questions.enumerated()), id: \.element.id) { i, q in
                        HStack(spacing: 12) {
                            Text(q.fact.symbol).font(.title)
                            Text(q.fact.subject.localizedContent)
                                .font(.subheadline).foregroundStyle(Brand.text)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 6)
                            Image(systemName: q.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(q.isCorrect ? Brand.successText : Brand.danger)
                        }
                        .padding(12)
                        .background(Brand.text.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .dealIn(i)
                    }
                }
            }

            Card {
                Label {
                    Text("Asking \"why\" ties a fact to what you already know. It helps most on familiar topics — and less when the material is brand new.")
                        .font(.subheadline).foregroundStyle(Brand.text.opacity(0.85))
                } icon: {
                    Image(systemName: "lightbulb.fill").foregroundStyle(Brand.accentText)
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

#Preview("Elaboration — why is that?") {
    ElaborationMissionView(level: SampleLevels.level(at: 10)!)
        .environment(GameStore())
}
