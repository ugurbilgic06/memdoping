//
//  MissionView.swift
//  MemDoping
//
//  Hosts one mission and its phases. The whole loop lives here:
//  intro -> learn -> recall -> feedback -> summary.
//

import SwiftUI

struct MissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: MissionSession
    @State private var outcome: GameStore.SessionOutcome?

    init(level: GameLevel) {
        _session = State(initialValue: MissionSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(seed: session.level.index)

            Group {
                switch session.phase {
                case .intro:    introPhase
                case .learn:    learnPhase
                case .recall:   RecallPhaseView(session: session)
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
                        .foregroundStyle(Color.primary.opacity(0.8))
                }
            }
        }
    }

    // MARK: Learn

    /// Levels with an orienting depth judge items one at a time (T01);
    /// everything else studies the whole deck against a timer.
    @ViewBuilder
    private var learnPhase: some View {
        if session.level.orientingDepth != nil {
            OrientingLearnPhaseView(session: session)
        } else {
            LearnPhaseView(session: session)
        }
    }

    // MARK: Intro

    private var introPhase: some View {
        MissionIntro(level: session.level, stats: introStats) {
            session.beginLearning()
        }
    }

    private var introStats: [MissionStat] {
        [
            MissionStat("\(session.level.itemCount)", "to learn", "square.stack.3d.up"),
            MissionStat("\(session.level.questionCount)", "to recall", "checklist"),
            session.level.orientingDepth != nil
                ? MissionStat("\(session.level.itemCount)", "to judge", "questionmark.circle")
                : MissionStat("\(session.level.memorizeSeconds)s", "to study", "timer")
        ]
    }

    // MARK: Feedback (per-question review, retry without shame)

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("How did the links hold?")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text("\(session.correctCount) of \(session.totalQuestions) recalled")
                .foregroundStyle(Color.primary.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.questions.enumerated()), id: \.element.id) { i, q in
                        HStack(spacing: 12) {
                            Text(q.prompt.symbol).font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(q.prompt.word.localizedContent)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                if !q.isCorrect {
                                    Text("You chose: \((q.chosen ?? "—").localizedContent)")
                                        .font(.caption)
                                        .foregroundStyle(Brand.danger)
                                }
                            }
                            Spacer()
                            Image(systemName: q.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(q.isCorrect ? Brand.successText : Brand.danger)
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .dealIn(i)
                    }
                }
            }

            Card {
                Label {
                    Text("Missed one? That's the technique working. Recalling — and correcting — is how the link gets stronger.")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.85))
                } icon: {
                    Image(systemName: "lightbulb.fill").foregroundStyle(Brand.accentText)
                }
            }

            if session.level.orientingDepth != nil, session.orientingTotal > 0 {
                Text("You judged \(session.orientingCorrectCount) of \(session.orientingTotal) items correctly along the way.")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(title: "See results", systemImage: "arrow.right") {
                let result = store.complete(
                    level: session.level,
                    correct: session.correctCount,
                    total: session.totalQuestions
                )
                outcome = result
                store.scheduleReviews(themeId: session.level.theme.id, pairs: session.studyPairs)
                if store.soundEnabled { SoundPlayer.shared.play(result.mastered ? .levelUp : .correct) }
                if store.hapticsEnabled { HapticsPlayer.shared.notify(success: result.mastered) }
                session.showSummary()
            }
        }
    }

    // MARK: Summary (XP, Memory Score, clear stopping point)

    private var summaryPhase: some View {
        MissionSummary(
            passedMastery: session.passedMastery,
            accuracy: session.accuracy,
            outcome: outcome,
            onRetry: {
                session = session.makeRetry()
                outcome = nil
            },
            onExit: { dismiss() }
        )
    }
}

// MARK: - Learn phase: orienting questions (T01)

/// One item at a time with a yes/no question about it. The judgement itself
/// isn't scored on screen — answering is what forces the deeper encoding the
/// later recall phase measures (see docs/techniques/attention-encoding.md).
private struct OrientingLearnPhaseView: View {
    @Bindable var session: MissionSession
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Label("Look closely", systemImage: "eye.fill")
                    .font(.headline).foregroundStyle(.primary)
                Spacer()
                Text("\(session.orientingIndex + 1)/\(session.studyPairs.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Brand.accentText)
            }

            ProgressView(value: Double(session.orientingIndex),
                         total: Double(max(session.studyPairs.count, 1)))
                .tint(Brand.accent)

            Spacer()

            if let pair = session.currentOrientingPair {
                VStack(spacing: 14) {
                    Text(pair.symbol).font(.system(size: 88))
                    Text(pair.word.localizedContent)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                }
                .id(pair.id)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))

                Card {
                    Text(session.orientingQuestion)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 12) {
                    judgeButton("Yes", systemImage: "hand.thumbsup.fill", answer: true)
                    judgeButton("No", systemImage: "hand.thumbsdown.fill", answer: false)
                }
            }

            Spacer()

            Text("Your answer isn't graded — deciding is what helps you remember.")
                .font(.caption2)
                .foregroundStyle(Color.primary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: session.orientingIndex)
    }

    private func judgeButton(_ title: LocalizedStringKey, systemImage: String, answer: Bool) -> some View {
        Button {
            if store.soundEnabled { SoundPlayer.shared.play(.tap) }
            if store.hapticsEnabled { HapticsPlayer.shared.tap() }
            session.judgeCurrentPair(answer)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Learn phase

private struct LearnPhaseView: View {
    @Bindable var session: MissionSession
    @State private var timer: Timer?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Memorize", systemImage: "eye.fill")
                    .font(.headline).foregroundStyle(.primary)
                Spacer()
                Text("\(session.learnSecondsRemaining)s")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(Brand.accentText)
                    .accessibilityLabel("\(session.learnSecondsRemaining) seconds left")
            }

            ProgressView(value: Double(session.learnSecondsRemaining),
                         total: Double(session.level.memorizeSeconds))
                .tint(Brand.accent)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(session.studyPairs) { pair in
                        VStack(spacing: 10) {
                            SymbolBadge(symbol: pair.symbol, seed: pair.id.hashValue, size: 92)
                            Text(pair.word.localizedContent)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.55),
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
                        .gentleFloat(abs(pair.id.hashValue))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text(pair.word.localizedContent))
                    }
                }
            }

            Text(session.level.tip.localizedContent)
                .font(.footnote)
                .foregroundStyle(Color.primary.opacity(0.75))
                .multilineTextAlignment(.center)

            PrimaryButton(title: "I'm ready", systemImage: "checkmark") {
                session.beginRecall()
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                session.tickLearnTimer()
            }
        }
        .onChange(of: session.phase) { _, newValue in
            if newValue != .learn { timer?.invalidate(); timer = nil }
        }
        .onDisappear { timer?.invalidate(); timer = nil }
    }
}

// MARK: - Recall phase

private struct RecallPhaseView: View {
    @Bindable var session: MissionSession
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("Which word goes here?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            if let q = session.currentQuestion {
                Symbol3DTile(symbol: q.prompt.symbol, tint: session.level.tileBase, size: 150,
                             celebrate: revealed && q.isCorrect)
                    .padding(.vertical, 8)

                VStack(spacing: 12) {
                    ForEach(Array(q.options.enumerated()), id: \.element) { i, option in
                        answerButton(option, question: q).dealIn(i)
                    }
                }

                Spacer()

                if revealed {
                    PrimaryButton(
                        title: session.currentQuestionIndex + 1 < session.totalQuestions
                            ? "Next" : "Finish",
                        systemImage: "arrow.right"
                    ) {
                        revealed = false
                        session.advanceAfterAnswer()
                    }
                }
            }
        }
        .id(session.currentQuestionIndex)   // reset per-question local state
    }

    private func answerButton(_ option: String, question q: RecallQuestion) -> some View {
        let isChosen = q.chosen == option
        let isCorrectAnswer = option == q.prompt.word

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
                    Text(option.localizedContent).foregroundStyle(.primary).fontWeight(.medium)
                    Spacer()
                    if revealed && isCorrectAnswer {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.primary)
                    } else if revealed && isChosen {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.primary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .scaleEffect(isChosen && revealed ? 1.05 : 1.0)
            .flipReveal(revealed && isChosen && isCorrectAnswer && !reduceMotion)
            .modifier(ShakeEffect(animatableData:
                (revealed && isChosen && !isCorrectAnswer && !reduceMotion) ? 1 : 0))
            .overlay {
                if revealed && isCorrectAnswer && !reduceMotion {
                    ConfettiBurst()
                }
            }
        }
        .buttonStyle(TileButtonStyle())
        .disabled(revealed)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.55), value: revealed)
    }
}

// MARK: - Previews

#Preview("Recall (multiple choice)") {
    let session = MissionSession(level: SampleLevels.level(at: 8)!)
    session.beginLearning()
    session.beginRecall()
    return ZStack {
        BrandBackground()
        RecallPhaseView(session: session).padding()
    }
    .environment(GameStore())
}

#Preview("Orienting (T01)") {
    let session = MissionSession(level: SampleLevels.level(at: 1)!)
    session.beginLearning()
    return ZStack {
        BrandBackground()
        OrientingLearnPhaseView(session: session).padding()
    }
    .environment(GameStore())
}
