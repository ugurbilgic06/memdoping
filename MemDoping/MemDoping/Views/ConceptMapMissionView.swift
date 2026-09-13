//
//  ConceptMapMissionView.swift
//  MemDoping
//
//  PACER C — "Map It". Connect each idea to the centre and name the relation,
//  watching the map grow; then name the relations again with the map gone.
//  The label on the link is the knowledge, so the label is what's tested.
//

import SwiftUI

struct ConceptMapMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: ConceptMapSession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var revealed = false

    init(level: GameLevel) {
        _session = State(initialValue: ConceptMapSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(seed: session.level.index, quiet: true)

            Group {
                switch session.phase {
                case .intro:    introPhase
                case .map:      mapPhase
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
                MissionStat("\(session.mappedTotal)", "to connect", "point.topleft.down.curvedto.point.bottomright.up"),
                MissionStat("\(session.totalQuestions)", "to recall", "checklist"),
                MissionStat("1", "centre", "circle.circle.fill")
            ],
            onStart: { session.beginMapping() }
        )
    }

    // MARK: The centre, always on screen while mapping

    private var centreBadge: some View {
        VStack(spacing: 4) {
            Symbol3DTile(symbol: session.deck.centerIcon, tint: session.level.tileBase, size: 84)
            Text(session.deck.center.localizedContent)
                .font(.headline).foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
        }
    }

    /// The spokes labelled so far, so the player sees a map rather than a quiz.
    private var builtSpokes: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(session.builtLinks) { link in
                    VStack(spacing: 2) {
                        Text(link.node.icon).font(.title3)
                        Text(link.node.relation.label.localizedContent)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.text.opacity(0.75))
                    }
                    .padding(8)
                    .background(
                        (link.isCorrect ? Brand.success : Brand.accent).opacity(0.28),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: 60)
    }

    // MARK: Map — name each connection

    private var mapPhase: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Build the map", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(session.mapIndex + 1)/\(session.mappedTotal)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Brand.accentText)
            }

            ProgressView(value: session.mapProgress).tint(Brand.accent)

            centreBadge

            if !session.builtLinks.isEmpty { builtSpokes }

            if let link = session.currentLink {
                HStack(spacing: 10) {
                    Text(link.node.icon).font(.title2)
                    Text(link.node.name.localizedContent)
                        .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                }

                Text("How does this connect to \(session.deck.center.localizedContent)?")
                    .font(.subheadline).foregroundStyle(Brand.text.opacity(0.75))
                    .multilineTextAlignment(.center)

                if link.isAnswered {
                    noteCard(link)
                    Spacer()
                    PrimaryButton(
                        title: session.mapIndex + 1 < session.mappedTotal ? "Next" : "Now recall",
                        systemImage: "arrow.right"
                    ) {
                        session.advanceAfterLink()
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(link.options.enumerated()), id: \.element) { i, relation in
                            relationButton(relation, link: link).dealIn(i)
                        }
                    }
                    Spacer()
                }
            }
        }
        .id(session.mapIndex)
    }

    private func relationButton(_ relation: RelationKind,
                                link: ConceptMapSession.MapLink) -> some View {
        Button {
            session.chooseRelation(relation)
            let ok = relation == link.node.relation
            if store.soundEnabled { SoundPlayer.shared.play(ok ? .correct : .incorrect) }
            if store.hapticsEnabled { HapticsPlayer.shared.notify(success: ok) }
        } label: {
            GameTile(base: session.level.tileBase, cornerRadius: 14) {
                HStack(spacing: 10) {
                    Image(systemName: relation.icon).foregroundStyle(Brand.text.opacity(0.8))
                    Text(relation.label.localizedContent)
                        .foregroundStyle(Brand.text).fontWeight(.medium)
                    Spacer(minLength: 8)
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(TileButtonStyle())
    }

    private func noteCard(_ link: ConceptMapSession.MapLink) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: link.isCorrect ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(link.isCorrect ? Brand.successText : Brand.accent)
                Text("\(link.node.name.localizedContent) — \(link.node.relation.label.localizedContent) — \(session.deck.center.localizedContent)")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
            }
            Text(link.node.note.localizedContent)
                .font(.caption).foregroundStyle(Brand.text.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Brand.primary.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.text.opacity(0.15), lineWidth: 1))
    }

    // MARK: Recall — the map is gone

    private var recallPhase: some View {
        VStack(spacing: 16) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("What was the link?")
                .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)

            if let q = session.currentQuestion {
                HStack(spacing: 10) {
                    Text(q.node.icon).font(.largeTitle)
                    Image(systemName: "arrow.left.and.right")
                        .foregroundStyle(Brand.text.opacity(0.45))
                    Text(session.deck.centerIcon).font(.largeTitle)
                }

                Text("\(q.node.name.localizedContent)  …  \(session.deck.center.localizedContent)")
                    .font(.headline).foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(Array(q.options.enumerated()), id: \.element) { i, relation in
                        recallButton(relation, question: q).dealIn(i)
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

    private func recallButton(_ relation: RelationKind,
                              question q: ConceptMapSession.RecallQ) -> some View {
        let isChosen = q.chosen == relation
        let isCorrectAnswer = relation == q.node.relation
        var base = session.level.tileBase
        if revealed {
            if isCorrectAnswer { base = Brand.success }
            else if isChosen { base = Brand.danger }
        }
        return Button {
            guard !revealed else { return }
            session.answerCurrent(relation)
            revealed = true
            if store.soundEnabled { SoundPlayer.shared.play(isCorrectAnswer ? .correct : .incorrect) }
            if store.hapticsEnabled { HapticsPlayer.shared.notify(success: isCorrectAnswer) }
        } label: {
            GameTile(base: base, cornerRadius: 14) {
                HStack(spacing: 10) {
                    Image(systemName: relation.icon).foregroundStyle(Brand.text.opacity(0.8))
                    Text(relation.label.localizedContent)
                        .foregroundStyle(Brand.text).fontWeight(.medium)
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
            Text(session.deck.title.localizedContent)
                .font(.title2.bold()).foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
            Text("\(session.correctCount) of \(session.totalQuestions) links recalled · \(session.mappedCorrect)/\(session.mappedTotal) mapped")
                .font(.subheadline).foregroundStyle(Brand.text.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.questions.enumerated()), id: \.element.id) { i, q in
                        HStack(spacing: 10) {
                            Text(q.node.icon).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(q.node.name.localizedContent)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Brand.text)
                                Text("\(q.node.relation.label.localizedContent) \(session.deck.center.localizedContent)")
                                    .font(.caption).foregroundStyle(Brand.text.opacity(0.7))
                            }
                            Spacer(minLength: 6)
                            Image(systemName: q.isCorrect ? "checkmark.circle.fill"
                                                          : "xmark.circle.fill")
                                .foregroundStyle(q.isCorrect ? Brand.successText : Brand.danger)
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
                    Text("A line between two ideas says almost nothing. Naming it — increases, requires, is an example of — is what makes the map worth having.")
                        .font(.subheadline).foregroundStyle(Brand.text.opacity(0.85))
                } icon: {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .foregroundStyle(Brand.accentText)
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

#Preview("Concept map — name the link") {
    ConceptMapMissionView(level: SampleLevels.level(at: 15)!)
        .environment(GameStore())
}
