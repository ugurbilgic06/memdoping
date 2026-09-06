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
                case .learn:    LearnPhaseView(session: session)
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

    // MARK: Intro

    private var introPhase: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("Level \(session.level.index)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Brand.accent)
            Text(session.level.title.localizedContent)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label(session.level.technique.localizedContent, systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(session.level.tip.localizedContent)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            HStack(spacing: 12) {
                miniStat("\(session.level.itemCount)", "to learn", "square.stack.3d.up")
                miniStat("\(session.level.questionCount)", "to recall", "checklist")
                miniStat("\(session.level.memorizeSeconds)s", "to study", "timer")
            }

            Spacer()
            Text("Sample content — a prototype mission, not final curriculum.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            PrimaryButton(title: "Start", systemImage: "play.fill") {
                session.beginLearning()
            }
        }
    }

    private func miniStat(_ value: String, _ label: LocalizedStringKey, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(Brand.accent)
            Text(value).font(.headline).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
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

            PrimaryButton(title: "See results", systemImage: "arrow.right") {
                outcome = store.complete(
                    level: session.level,
                    correct: session.correctCount,
                    total: session.totalQuestions
                )
                session.showSummary()
            }
        }
    }

    // MARK: Summary (XP, Memory Score, clear stopping point)

    private var summaryPhase: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: session.passedMastery ? "star.circle.fill" : "arrow.counterclockwise.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(session.passedMastery ? Brand.accent : .white.opacity(0.8))

            Text(session.passedMastery ? "Level cleared!" : "Good effort")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            if let outcome {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        StatChip(title: "MemDoping XP", value: "+\(outcome.xpEarned)",
                                 systemImage: "bolt.fill", tint: Brand.accent)
                        StatChip(title: "Accuracy",
                                 value: "\(Int(session.accuracy * 100))%",
                                 systemImage: "target")
                        StatChip(title: "Memory Score",
                                 value: outcome.memoryScore.map { "\($0)" } ?? "—",
                                 systemImage: "brain.head.profile")
                    }
                    if outcome.unlockedNextLevel {
                        badge("New level unlocked!", "lock.open.fill", Brand.success)
                    }
                    if outcome.isNewBest {
                        badge("New personal best", "rosette", Brand.accent)
                    }
                    if outcome.memoryScore == nil {
                        Text("Play \(GameStore.minSessionsForScore) missions to reveal your Memory Score.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
            }

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "Play again", systemImage: "arrow.counterclockwise") {
                    session = session.makeRetry()
                    outcome = nil
                }
                Button("Back to home") { dismiss() }
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.vertical, 8)
            }
        }
    }

    private func badge(_ text: LocalizedStringKey, _ icon: String, _ tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(tint.opacity(0.25), in: Capsule())
            .overlay(Capsule().stroke(tint, lineWidth: 1))
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
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }
}
