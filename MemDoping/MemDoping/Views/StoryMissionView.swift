//
//  StoryMissionView.swift
//  MemDoping
//
//  T08 Story Linking ("Zincir Hikâye"). Link items with action cards into one
//  chain, then rebuild the order from memory. The chain is shown as arrowed
//  chips (not prose) so it reads naturally in any language. The summary recaps
//  the story the player built (§ self-efficacy).
//

import SwiftUI

struct StoryMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: StorySession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var dragId: UUID? = nil
    @State private var dragOffset: CGSize = .zero

    init(level: GameLevel) {
        _session = State(initialValue: StorySession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(tint: session.level.tileBase)

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
                MissionStat("\(session.items.count)", "to link", "link"),
                MissionStat("\(session.items.count)", "in order", "list.number"),
                MissionStat("1", "story", "book.pages")
            ],
            onStart: { session.beginBuilding() }
        )
    }

    // MARK: Build — link each pair with an action

    private var buildPhase: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Link the story", systemImage: "link")
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Text("\(session.linkIndex + 1)/\(session.links.count)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Brand.accent)
            }
            ProgressView(value: session.buildProgress).tint(Brand.accent)

            if let link = session.currentLink {
                Spacer()
                // The two items being linked.
                HStack(spacing: 14) {
                    itemChip(link.from)
                    Image(systemName: "arrow.right").foregroundStyle(.white.opacity(0.5))
                    itemChip(link.to)
                }

                if let chosen = link.chosen {
                    Text("\(link.from.word.localizedContent) \(chosen.localizedContent) \(link.to.word.localizedContent)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12).padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(Brand.accent.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.accent, lineWidth: 1))

                    Spacer()
                    PrimaryButton(
                        title: session.linkIndex + 1 < session.links.count ? "Next link" : "Now recall",
                        systemImage: "arrow.right"
                    ) {
                        session.advanceAfterLink()
                    }
                } else {
                    Text("How does \(link.from.word.localizedContent) meet \(link.to.word.localizedContent)?")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                    VStack(spacing: 10) {
                        ForEach(link.options, id: \.self) { action in
                            actionButton(action)
                        }
                    }
                    Spacer()
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: session.currentLink?.chosen)
    }

    private func itemChip(_ pair: MemoryPair) -> some View {
        VStack(spacing: 4) {
            Text(pair.symbol).font(.system(size: 44))
            Text(pair.word.localizedContent).font(.caption).foregroundStyle(.white)
        }
        .padding(.vertical, 10).padding(.horizontal, 14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func actionButton(_ action: String) -> some View {
        Button {
            if store.soundEnabled { SoundPlayer.shared.play(.tap) }
            if store.hapticsEnabled { HapticsPlayer.shared.tap() }
            session.chooseAction(action)
        } label: {
            GameTile(base: session.level.tileBase, cornerRadius: 14) {
                Text(action.localizedContent)
                    .foregroundStyle(.white).fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Recall — rebuild the order

    private var recallPhase: some View {
        VStack(spacing: 18) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("Retell it — drag the items up, in order")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            // Ordered slots filled so far.
            HStack(spacing: 8) {
                ForEach(0..<session.totalItems, id: \.self) { i in
                    let filled = session.rebuilt.indices.contains(i)
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.06))
                            .frame(width: 56, height: 56)
                        if filled {
                            Text(session.rebuilt[i].symbol).font(.system(size: 34))
                        } else {
                            Text("\(i + 1)").font(.headline).foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(i == session.nextPosition ? Brand.accent : .white.opacity(0.12),
                                lineWidth: i == session.nextPosition ? 2 : 1))
                }
            }

            // Remaining items — drag one up to drop it into the next slot.
            FlowRow(spacing: 12) {
                ForEach(session.tray) { pair in
                    let used = session.isUsed(pair)
                    GameTile(base: session.level.tileBase, cornerRadius: 14) {
                        Text(pair.symbol)
                            .font(.system(size: 40))
                            .frame(width: 66, height: 66)
                    }
                    .opacity(used ? 0.3 : 1)
                    .offset(dragId == pair.id ? dragOffset : .zero)
                    .zIndex(dragId == pair.id ? 1 : 0)
                    .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                               value: dragId == pair.id ? dragOffset : .zero)
                    .gesture(
                        DragGesture()
                            .onChanged { g in
                                guard !used else { return }
                                dragId = pair.id; dragOffset = g.translation
                            }
                            .onEnded { g in
                                if !used, g.translation.height < -100 {
                                    session.placeNext(pair)
                                    if store.soundEnabled { SoundPlayer.shared.play(.pop) }
                                    if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                                }
                                dragId = nil; dragOffset = .zero
                            }
                    )
                }
            }

            Spacer()

            Button {
                if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                session.undoLast()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .buttonStyle(.plain)
            .disabled(session.rebuilt.isEmpty)
        }
    }

    // MARK: Feedback + story recap

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("Your story, in order")
                .font(.title2.bold()).foregroundStyle(.white)
            Text("\(session.correctCount) of \(session.totalItems) in the right spot")
                .foregroundStyle(.white.opacity(0.8))

            // The chain the player built.
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(session.links.enumerated()), id: \.offset) { _, link in
                        HStack(spacing: 8) {
                            Text(link.from.symbol)
                            Text(link.from.word.localizedContent)
                            Text((link.chosen ?? "→").localizedContent)
                                .foregroundStyle(Brand.accent).fontWeight(.semibold)
                            Text(link.to.word.localizedContent)
                            Text(link.to.symbol)
                            Spacer()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Card {
                Label {
                    Text("A story you made yourself brings back the order — that's what makes long lists stick.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                } icon: {
                    Image(systemName: "book.pages.fill").foregroundStyle(Brand.accent)
                }
            }

            PrimaryButton(title: "See results", systemImage: "arrow.right") {
                let result = store.complete(
                    level: session.level,
                    correct: session.correctCount,
                    total: session.totalItems
                )
                outcome = result
                store.scheduleReviews(themeId: session.level.theme.id, pairs: session.items)
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
            },
            onExit: { dismiss() }
        )
    }
}

#Preview("Story linking — chain") {
    StoryMissionView(level: SampleLevels.level(at: 11)!)
        .environment(GameStore())
}
