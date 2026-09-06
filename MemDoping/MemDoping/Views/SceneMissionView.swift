//
//  SceneMissionView.swift
//  MemDoping
//
//  T02 Association & Imagery ("Canlı Sahne"). The player builds a vivid image
//  for each pair by choosing a silly modifier, then recalls the pairing. The
//  generation is the point — and the exit note is honest about the technique's
//  modest, conditional benefit (§9).
//

import SwiftUI

struct SceneMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: SceneSession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var revealed = false

    init(level: GameLevel) {
        _session = State(initialValue: SceneSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground()

            Group {
                switch session.phase {
                case .intro:    introPhase
                case .build:    buildPhase
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
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    // MARK: Intro

    private var introPhase: some View {
        MissionIntro(
            level: session.level,
            stats: [
                MissionStat("\(session.level.itemCount)", "to picture", "sparkles"),
                MissionStat("\(session.level.questionCount)", "to recall", "checklist"),
                MissionStat("🎬", "you build it", "hand.draw")
            ],
            onStart: { session.beginBuilding() }
        )
    }

    // MARK: Build — choose a twist to form a scene

    private var buildPhase: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Build the scene", systemImage: "sparkles")
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Text("\(session.buildIndex + 1)/\(session.studyPairs.count)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Brand.accent)
            }

            ProgressView(value: session.buildProgress).tint(Brand.accent)

            if let card = session.currentCard {
                Spacer()

                VStack(spacing: 8) {
                    Text(card.pair.symbol).font(.system(size: 72))
                    Text(card.pair.word.localizedContent)
                        .font(.largeTitle.bold()).foregroundStyle(.white)
                }
                .id(card.id)

                if let chosen = card.chosen {
                    // The scene the player just made.
                    HStack(spacing: 8) {
                        Text(chosen.emoji).font(.title)
                        Text("\(card.pair.word.localizedContent) \(chosen.text.localizedContent)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 14).padding(.horizontal, 18)
                    .frame(maxWidth: .infinity)
                    .background(Brand.accent.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.accent, lineWidth: 1))
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))

                    Spacer()
                    PrimaryButton(
                        title: session.buildIndex + 1 < session.studyPairs.count ? "Next scene" : "Now recall",
                        systemImage: "arrow.right"
                    ) {
                        session.advanceAfterChoice()
                    }
                } else {
                    Text("Pick a twist and picture it:")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.75))
                    VStack(spacing: 10) {
                        ForEach(card.options) { modifier in
                            modifierButton(card: card, modifier: modifier)
                        }
                    }
                    Spacer()
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: session.currentCard?.chosen)
    }

    private func modifierButton(card: SceneSession.SceneCard, modifier: SceneModifier) -> some View {
        Button {
            if store.soundEnabled { SoundPlayer.shared.play(.tap) }
            if store.hapticsEnabled { HapticsPlayer.shared.tap() }
            session.choose(modifier)
        } label: {
            GameTile(cornerRadius: 14) {
                HStack(spacing: 12) {
                    Text(modifier.emoji).font(.title2)
                    Text("\(card.pair.word.localizedContent) \(modifier.text.localizedContent)")
                        .foregroundStyle(.white).fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Recall — multiple choice

    private var recallPhase: some View {
        VStack(spacing: 20) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("Which word goes here?")
                .font(.title3.weight(.semibold)).foregroundStyle(.white)

            if let q = session.currentQuestion {
                Text(q.prompt.symbol).font(.system(size: 90)).padding(.vertical, 8)

                VStack(spacing: 12) {
                    ForEach(q.options, id: \.self) { option in
                        answerButton(option, question: q)
                    }
                }

                Spacer()

                if revealed {
                    PrimaryButton(
                        title: session.currentQuestionIndex + 1 < session.totalQuestions ? "Next" : "Finish",
                        systemImage: "arrow.right"
                    ) {
                        revealed = false
                        session.advanceAfterAnswer()
                    }
                }
            }
        }
        .id(session.currentQuestionIndex)
    }

    private func answerButton(_ option: String, question q: RecallQuestion) -> some View {
        let isChosen = q.chosen == option
        let isCorrectAnswer = option == q.prompt.word
        var base = Color(hue: 0.72, saturation: 0.35, brightness: 0.30)
        if revealed {
            if isCorrectAnswer { base = Brand.success }
            else if isChosen { base = Brand.danger }
        }
        return Button {
            guard !revealed else { return }
            session.answerCurrent(option)
            revealed = true
            if store.soundEnabled { SoundPlayer.shared.play(isCorrectAnswer ? .pop : .incorrect) }
            if store.hapticsEnabled { HapticsPlayer.shared.notify(success: isCorrectAnswer) }
        } label: {
            GameTile(base: base, cornerRadius: 14) {
                HStack {
                    Text(option.localizedContent).foregroundStyle(.white).fontWeight(.medium)
                    Spacer()
                    if revealed && isCorrectAnswer {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.white)
                    } else if revealed && isChosen {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.white)
                    }
                }
                .padding().frame(maxWidth: .infinity)
            }
            .scaleEffect(isChosen && revealed ? 1.05 : 1.0)
            .modifier(ShakeEffect(animatableData:
                (revealed && isChosen && !isCorrectAnswer && !reduceMotion) ? 1 : 0))
            .overlay { if revealed && isCorrectAnswer && !reduceMotion { SparkBurst(color: .white) } }
        }
        .buttonStyle(TileButtonStyle())
        .disabled(revealed)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.55), value: revealed)
    }

    // MARK: Feedback

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("Did your scenes hold?")
                .font(.title2.bold()).foregroundStyle(.white)
            Text("\(session.correctCount) of \(session.totalQuestions) recalled")
                .foregroundStyle(.white.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(session.questions) { q in
                        HStack(spacing: 12) {
                            Text(q.prompt.symbol).font(.title)
                            Text(q.prompt.word.localizedContent)
                                .font(.headline).foregroundStyle(.white)
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
                    Text("Building your own image helps — but it's not magic. It works better for some people and some material. When it clicks, lean in.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                } icon: {
                    Image(systemName: "sparkles").foregroundStyle(Brand.accent)
                }
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

#Preview("Scene — association & imagery") {
    SceneMissionView(level: SampleLevels.level(at: 3)!)
        .environment(GameStore())
}
