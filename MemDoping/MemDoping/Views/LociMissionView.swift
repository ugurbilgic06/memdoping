//
//  LociMissionView.swift
//  MemDoping
//
//  T09 Method of Loci ("Hafıza Sarayı"). Walk a familiar route leaving one item
//  at each stop, then walk it back and recall what's where. Framing leans on
//  the evidence: this is a learnable strategy, not a talent (§9).
//

import SwiftUI

struct LociMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: LociSession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var revealed = false

    init(level: GameLevel) {
        _session = State(initialValue: LociSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(tint: session.level.tileBase)

            Group {
                switch session.phase {
                case .intro:    introPhase
                case .place:    placePhase
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
                MissionStat("\(session.totalStops)", "stops", "map"),
                MissionStat("\(session.totalStops)", "to place", "square.stack.3d.up"),
                MissionStat("\(session.totalStops)", "to recall", "figure.walk")
            ],
            onStart: { session.beginPlacing() }
        )
    }

    // MARK: Place — walk forward, drop an item at each stop

    private var placePhase: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Leave it here", systemImage: "figure.walk")
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Text("\(session.placeIndex + 1)/\(session.totalStops)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Brand.accent)
            }

            ProgressView(value: session.placeProgress).tint(Brand.accent)

            Spacer()

            if let p = session.currentPlacement {
                VStack(spacing: 8) {
                    Text(p.stop.icon).font(.system(size: 70))
                    Text(p.stop.name.localizedContent)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Image(systemName: "arrow.down")
                    .font(.title2).foregroundStyle(.white.opacity(0.4))

                VStack(spacing: 6) {
                    Text(p.item.symbol).font(.system(size: 56))
                    Text(p.item.word.localizedContent)
                        .font(.title2.bold()).foregroundStyle(.white)
                }
                .padding(.vertical, 16).frame(maxWidth: .infinity)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                .id(p.id)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))

                Text("Picture the \(p.item.word.localizedContent) at the \(p.stop.name.localizedContent) — the sillier the image, the better it sticks.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            PrimaryButton(title: "Leave it & walk on", systemImage: "arrow.right") {
                if store.soundEnabled { SoundPlayer.shared.play(.tap) }
                if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                session.placeCurrent()
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: session.placeIndex)
    }

    // MARK: Recall — walk again, recall what's at each stop

    private var recallPhase: some View {
        VStack(spacing: 18) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("What did you leave here?")
                .font(.title3.weight(.semibold)).foregroundStyle(.white)

            if let stop = session.currentStop {
                VStack(spacing: 6) {
                    Text(stop.icon).font(.system(size: 64))
                    Text(stop.name.localizedContent)
                        .font(.headline).foregroundStyle(.white.opacity(0.9))
                }

                itemTray

                Spacer()

                if revealed {
                    revealFeedback
                    PrimaryButton(
                        title: session.recallIndex + 1 < session.totalStops ? "Next stop" : "Finish",
                        systemImage: "arrow.right"
                    ) {
                        revealed = false
                        session.advanceAfterPick()
                    }
                }
            }
        }
    }

    private var itemTray: some View {
        FlowRow(spacing: 12) {
            ForEach(session.itemTray) { item in
                let used = session.isItemUsed(item)
                let isChosen = revealed && session.lastPick?.chosenItem.id == item.id
                let isRight = revealed && session.lastPick?.placement.item.id == item.id

                Button {
                    guard !revealed, !used else { return }
                    session.pick(item)
                    showReveal()
                } label: {
                    GameTile(base: trayBase(isChosen: isChosen, isRight: isRight), cornerRadius: 14) {
                        Text(item.symbol)
                            .font(.system(size: 40))
                            .frame(width: 66, height: 66)
                    }
                    .opacity(used && !isChosen && !isRight ? 0.3 : 1)
                    .scaleEffect(isRight && revealed ? 1.06 : 1)
                    .flipReveal(isRight && revealed && !reduceMotion)
                    .modifier(ShakeEffect(animatableData:
                        (revealed && isChosen && !isRight && !reduceMotion) ? 1 : 0))
                    .overlay { if isRight && revealed && !reduceMotion { SparkBurst(color: .white) } }
                }
                .buttonStyle(TileButtonStyle())
                .disabled(revealed || used)
            }
        }
    }

    private func trayBase(isChosen: Bool, isRight: Bool) -> Color {
        if isRight { return Brand.success }
        if isChosen { return Brand.danger }
        return session.level.tileBase
    }

    @ViewBuilder
    private var revealFeedback: some View {
        if let pick = session.lastPick {
            VStack(spacing: 4) {
                Label(pick.correct ? "That's the one!" : "Not there",
                      systemImage: pick.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(pick.correct ? Brand.success : Brand.danger)
                if !pick.correct {
                    Text("You left the \(pick.placement.item.word.localizedContent) here.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    private func showReveal() {
        guard !revealed, let pick = session.lastPick else { return }
        revealed = true
        if store.soundEnabled { SoundPlayer.shared.play(pick.correct ? .pop : .incorrect) }
        if store.hapticsEnabled { HapticsPlayer.shared.notify(success: pick.correct) }
    }

    // MARK: Feedback

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("Your walk back")
                .font(.title2.bold()).foregroundStyle(.white)
            Text("\(session.correctCount) of \(session.totalStops) stops recalled in order")
                .foregroundStyle(.white.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(session.picks) { pick in
                        HStack(spacing: 12) {
                            Text(pick.placement.stop.icon).font(.title2)
                            Text(pick.placement.stop.name.localizedContent)
                                .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text(pick.placement.item.symbol).font(.title3)
                            Image(systemName: pick.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(pick.correct ? Brand.success : Brand.danger)
                        }
                        .padding(12)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Card {
                Label {
                    Text("You just used a 2,000-year-old technique. It's not a talent — champions score no higher on IQ; they just walk a palace like you did.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                } icon: {
                    Image(systemName: "building.columns.fill").foregroundStyle(Brand.accent)
                }
            }

            PrimaryButton(title: "See results", systemImage: "arrow.right") {
                let result = store.complete(
                    level: session.level,
                    correct: session.correctCount,
                    total: session.totalStops
                )
                outcome = result
                store.scheduleReviews(themeId: session.level.theme.id, pairs: session.placedPairs)
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

#Preview("Loci — memory palace") {
    LociMissionView(level: SampleLevels.level(at: 9)!)
        .environment(GameStore())
}
