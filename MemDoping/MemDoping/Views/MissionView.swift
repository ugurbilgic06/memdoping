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
            BrandBackground()

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
                        .foregroundStyle(.white.opacity(0.8))
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
                .foregroundStyle(.white)
            Text("\(session.correctCount) of \(session.totalQuestions) recalled")
                .foregroundStyle(.white.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(session.questions) { q in
                        HStack(spacing: 12) {
                            Text(q.prompt.symbol).font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(q.prompt.word.localizedContent)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                if !q.isCorrect {
                                    Text("You chose: \((q.chosen ?? "—").localizedContent)")
                                        .font(.caption)
                                        .foregroundStyle(Brand.danger)
                                }
                            }
                            Spacer()
                            Image(systemName: q.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(q.isCorrect ? Brand.success : Brand.danger)
                        }
                        .padding(12)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Card {
                Label {
                    Text("Missed one? That's the technique working. Recalling — and correcting — is how the link gets stronger.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                } icon: {
                    Image(systemName: "lightbulb.fill").foregroundStyle(Brand.accent)
                }
            }

            if session.level.orientingDepth != nil, session.orientingTotal > 0 {
                Text("You judged \(session.orientingCorrectCount) of \(session.orientingTotal) items correctly along the way.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
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
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Text("\(session.orientingIndex + 1)/\(session.studyPairs.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Brand.accent)
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
                        .foregroundStyle(.white)
                }
                .id(pair.id)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))

                Card {
                    Text(session.orientingQuestion)
                        .font(.headline)
                        .foregroundStyle(.white)
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
                .foregroundStyle(.white.opacity(0.5))
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
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .foregroundStyle(.white)
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
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Text("\(session.learnSecondsRemaining)s")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(Brand.accent)
                    .accessibilityLabel("\(session.learnSecondsRemaining) seconds left")
            }

            ProgressView(value: Double(session.learnSecondsRemaining),
                         total: Double(session.level.memorizeSeconds))
                .tint(Brand.accent)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(session.studyPairs) { pair in
                        VStack(spacing: 8) {
                            Text(pair.symbol).font(.system(size: 46))
                            Text(pair.word.localizedContent)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(.white.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }

            Text(session.level.tip.localizedContent)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.75))
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
                .foregroundStyle(.white)

            if let q = session.currentQuestion {
                Text(q.prompt.symbol)
                    .font(.system(size: 90))
                    .padding(.vertical, 8)

                VStack(spacing: 12) {
                    ForEach(q.options, id: \.self) { option in
                        answerButton(option, question: q)
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

        var fill: Color = .white.opacity(0.08)
        if revealed {
            if isCorrectAnswer { fill = Brand.success.opacity(0.35) }
            else if isChosen { fill = Brand.danger.opacity(0.35) }
        }

        return Button {
            guard !revealed else { return }
            session.answerCurrent(option)
            revealed = true
            if store.soundEnabled { SoundPlayer.shared.play(isCorrectAnswer ? .correct : .incorrect) }
            if store.hapticsEnabled { HapticsPlayer.shared.notify(success: isCorrectAnswer) }
        } label: {
            HStack {
                Text(option.localizedContent).foregroundStyle(.white).fontWeight(.medium)
                Spacer()
                if revealed && isCorrectAnswer {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.success)
                } else if revealed && isChosen {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Brand.danger)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(fill, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(isChosen && revealed ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(revealed)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.55), value: revealed)
    }
}
