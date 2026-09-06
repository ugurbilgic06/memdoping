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

    // Drag-to-combine state for the place phase: the location sits up top and
    // the item waits in a dock below (clearly apart at first); the player drags
    // the item up onto the location to "see them together".
    private static let locationOffset = CGSize(width: 0, height: -70)
    private static let itemStart = CGSize(width: 0, height: 150)
    @State private var itemOffset = LociMissionView.itemStart
    @State private var dragStart = LociMissionView.itemStart

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
                        .foregroundStyle(Color.primary.opacity(0.8))
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
        VStack(spacing: 14) {
            HStack {
                Label("Leave it here", systemImage: "figure.walk")
                    .font(.headline).foregroundStyle(.primary)
                Spacer()
                Text("\(session.placeIndex + 1)/\(session.totalStops)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Brand.accentText)
            }

            ProgressView(value: session.placeProgress).tint(Brand.accent)

            if let p = session.currentPlacement {
                Text("Drag the \(p.item.word.localizedContent) onto the \(p.stop.name.localizedContent) — really see them together.")
                    .font(.subheadline).foregroundStyle(Color.primary.opacity(0.8))
                    .multilineTextAlignment(.center)

                // The stage: the location up top (with a target ring), and the
                // item waiting in a dock below — drag it up onto the location.
                ZStack {
                    // Target ring at the location.
                    Circle()
                        .strokeBorder(isItemOnSpot ? Brand.accent : Color.primary.opacity(0.18),
                                      style: StrokeStyle(lineWidth: 2, dash: [7]))
                        .frame(width: 150, height: 150)
                        .offset(LociMissionView.locationOffset)

                    VStack(spacing: 6) {
                        Text(p.stop.icon).font(.system(size: 104))
                        Text(p.stop.name.localizedContent)
                            .font(.headline).foregroundStyle(Color.primary.opacity(0.85))
                    }
                    .offset(LociMissionView.locationOffset)

                    // The dock the item starts in.
                    Circle()
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 88, height: 88)
                        .offset(LociMissionView.itemStart)

                    Text(p.item.symbol)
                        .font(.system(size: 60))
                        .shadow(color: .black.opacity(0.45), radius: 7, y: 4)
                        .scaleEffect(isItemOnSpot ? 1.12 : 1)
                        .offset(itemOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { g in
                                    itemOffset = CGSize(width: dragStart.width + g.translation.width,
                                                        height: dragStart.height + g.translation.height)
                                }
                                .onEnded { _ in
                                    // Snap onto the location if it landed on the ring.
                                    if isItemOnSpot { itemOffset = LociMissionView.locationOffset }
                                    dragStart = itemOffset
                                    if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                                    if store.soundEnabled { SoundPlayer.shared.play(.pop) }
                                }
                        )
                        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6),
                                   value: itemOffset)
                        .accessibilityLabel(Text(p.item.word.localizedContent))
                }
                .frame(maxWidth: .infinity, minHeight: 340)
            }

            PrimaryButton(title: "Leave it & walk on", systemImage: "arrow.right") {
                if store.soundEnabled { SoundPlayer.shared.play(.tap) }
                session.placeCurrent()
            }
        }
        .onChange(of: session.placeIndex) { _, _ in resetItem() }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: session.placeIndex)
    }

    /// Whether the dragged item is resting over the location's target ring.
    private var isItemOnSpot: Bool {
        let dx = itemOffset.width - LociMissionView.locationOffset.width
        let dy = itemOffset.height - LociMissionView.locationOffset.height
        return dx * dx + dy * dy < 75 * 75
    }

    private func resetItem() {
        itemOffset = LociMissionView.itemStart
        dragStart = LociMissionView.itemStart
    }

    // MARK: Recall — walk again, recall what's at each stop

    private var recallPhase: some View {
        VStack(spacing: 18) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("What did you leave here?")
                .font(.title3.weight(.semibold)).foregroundStyle(.primary)

            if let stop = session.currentStop {
                VStack(spacing: 6) {
                    Text(stop.icon).font(.system(size: 64))
                    Text(stop.name.localizedContent)
                        .font(.headline).foregroundStyle(Color.primary.opacity(0.9))
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
            ForEach(Array(session.itemTray.enumerated()), id: \.element.id) { i, item in
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
                .dealIn(i)
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
                        .font(.subheadline).foregroundStyle(Color.primary.opacity(0.8))
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
                .font(.title2.bold()).foregroundStyle(.primary)
            Text("\(session.correctCount) of \(session.totalStops) stops recalled in order")
                .foregroundStyle(Color.primary.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.picks.enumerated()), id: \.element.id) { i, pick in
                        HStack(spacing: 12) {
                            Text(pick.placement.stop.icon).font(.title2)
                            Text(pick.placement.stop.name.localizedContent)
                                .font(.subheadline).foregroundStyle(Color.primary.opacity(0.8))
                            Spacer()
                            Text(pick.placement.item.symbol).font(.title3)
                            Image(systemName: pick.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(pick.correct ? Brand.success : Brand.danger)
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .dealIn(i)
                    }
                }
            }

            Card {
                Label {
                    Text("You just used a 2,000-year-old technique. It's not a talent — champions score no higher on IQ; they just walk a palace like you did.")
                        .font(.subheadline).foregroundStyle(Color.primary.opacity(0.85))
                } icon: {
                    Image(systemName: "building.columns.fill").foregroundStyle(Brand.accentText)
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
