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

    // Drag-to-combine state for the build phase.
    @State private var dragIndex: Int? = nil
    @State private var dragTranslation: CGSize = .zero

    init(level: GameLevel) {
        _session = State(initialValue: SceneSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(seed: session.level.index, quiet: true)

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
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(session.buildIndex + 1)/\(session.studyPairs.count)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Brand.accentText)
            }

            ProgressView(value: session.buildProgress).tint(Brand.accent)

            if let card = session.currentCard {
                Spacer()

                // The item — the drop target. The chosen twist lands on it.
                ZStack(alignment: .topTrailing) {
                    SymbolBadge(symbol: card.pair.symbol, seed: card.pair.id.hashValue, size: 124)
                    if let chosen = card.chosen {
                        Text(chosen.emoji).font(.system(size: 46))
                            .offset(x: 16, y: -8)
                            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    }
                }
                Text(card.pair.word.localizedContent)
                    .font(.largeTitle.bold()).foregroundStyle(Brand.text)
                    .id(card.id)

                if let chosen = card.chosen {
                    Text("\(card.pair.word.localizedContent) \(chosen.text.localizedContent)")
                        .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 14).padding(.horizontal, 18)
                        .frame(maxWidth: .infinity)
                        .background(Brand.accent.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.accentText.opacity(0.5), lineWidth: 1))
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))

                    Spacer()
                    PrimaryButton(
                        title: session.buildIndex + 1 < session.studyPairs.count ? "Next scene" : "Now recall",
                        systemImage: "arrow.right"
                    ) {
                        session.advanceAfterChoice()
                    }
                } else {
                    Text("Drag a twist up onto the \(card.pair.word.localizedContent):")
                        .font(.subheadline).foregroundStyle(Brand.text.opacity(0.75))
                        .multilineTextAlignment(.center)
                    VStack(spacing: 10) {
                        ForEach(Array(card.options.enumerated()), id: \.element.id) { i, modifier in
                            modifierChip(card: card, modifier: modifier, index: i)
                        }
                    }
                    Spacer()
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: session.currentCard?.chosen)
    }

    /// A draggable twist chip — drag it up onto the item to build the scene.
    private func modifierChip(card: SceneSession.SceneCard, modifier: SceneModifier, index: Int) -> some View {
        GameTile(base: session.level.tileBase, cornerRadius: 14) {
            HStack(spacing: 12) {
                Text(modifier.emoji).font(.title2)
                Text("\(card.pair.word.localizedContent) \(modifier.text.localizedContent)")
                    .foregroundStyle(Brand.text).fontWeight(.medium)
                Spacer()
                Image(systemName: "hand.draw").foregroundStyle(Brand.text.opacity(0.5))
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .offset(dragIndex == index ? dragTranslation : .zero)
        .zIndex(dragIndex == index ? 1 : 0)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                   value: dragIndex == index ? dragTranslation : .zero)
        .gesture(
            DragGesture()
                .onChanged { g in dragIndex = index; dragTranslation = g.translation }
                .onEnded { g in
                    // Dragged far enough up = dropped onto the item.
                    if g.translation.height < -120 {
                        chooseModifier(modifier)
                    } else if store.hapticsEnabled {
                        HapticsPlayer.shared.tap()
                    }
                    dragIndex = nil
                    dragTranslation = .zero
                }
        )
        .accessibilityHint(Text("Double-tap to add this twist"))
        .accessibilityAction { chooseModifier(modifier) }
    }

    /// Apply a twist to the current item (shared by drag and VoiceOver action).
    private func chooseModifier(_ modifier: SceneModifier) {
        session.choose(modifier)
        if store.soundEnabled { SoundPlayer.shared.play(.pop) }
        if store.hapticsEnabled { HapticsPlayer.shared.notify(success: true) }
    }

    // MARK: Recall — multiple choice

    private var recallPhase: some View {
        VStack(spacing: 20) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("Which word goes here?")
                .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)

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
                    Spacer()
                    if revealed && isCorrectAnswer {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.text)
                    } else if revealed && isChosen {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Brand.text)
                    }
                }
                .padding().frame(maxWidth: .infinity)
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
            Text("Did your scenes hold?")
                .font(.title2.bold()).foregroundStyle(Brand.text)
            Text("\(session.correctCount) of \(session.totalQuestions) recalled")
                .foregroundStyle(Brand.text.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.questions.enumerated()), id: \.element.id) { i, q in
                        HStack(spacing: 12) {
                            Text(q.prompt.symbol).font(.title)
                            Text(q.prompt.word.localizedContent)
                                .font(.headline).foregroundStyle(Brand.text)
                            Spacer()
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
                    Text("Building your own image helps — but it's not magic. It works better for some people and some material. When it clicks, lean in.")
                        .font(.subheadline).foregroundStyle(Brand.text.opacity(0.85))
                } icon: {
                    Image(systemName: "sparkles").foregroundStyle(Brand.accentText)
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
