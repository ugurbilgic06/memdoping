//
//  ReviewMissionView.swift
//  MemDoping
//
//  T05 spaced-review mini-mission. A short, welcoming pass over due items,
//  tested with free-recall letter tiles. Records each outcome to the store,
//  which reschedules the item and updates the Retention indicator.
//

import SwiftUI

struct ReviewMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: ReviewSession
    @State private var revealed = false

    init(items: [ReviewRecord]) {
        _session = State(initialValue: ReviewSession(items: items))
    }

    var body: some View {
        ZStack {
            BrandBackground()

            Group {
                switch session.phase {
                case .intro:   introPhase
                case .recall:  recallPhase
                case .summary: summaryPhase
                }
            }
            .padding()
            .transition(reduceMotion ? .opacity : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity))
        }
        .animation(reduceMotion ? nil : .easeInOut, value: session.phase)
        .navigationBarBackButtonHidden(session.phase == .recall)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if session.phase == .recall {
                    Button("Quit") { dismiss() }
                        .foregroundStyle(Color.primary.opacity(0.8))
                }
            }
        }
    }

    // MARK: Intro

    private var introPhase: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Label("Spaced review", systemImage: "clock.arrow.circlepath")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Brand.accentText)
            Text("Still there?")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Card {
                Text("You learned these a while ago. Let's see what's stuck — no study first, just recall. A little rust is normal.")
                    .foregroundStyle(Color.primary.opacity(0.85))
            }

            HStack(spacing: 12) {
                statTile("\(session.items.count)", "to review", "list.bullet")
                statTile("~\(max(1, session.items.count) / 2 + 1) min", "quick", "timer")
            }

            Spacer()
            PrimaryButton(title: "Start review", systemImage: "play.fill") {
                session.begin()
            }
        }
    }

    private func statTile(_ value: String, _ label: LocalizedStringKey, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(Brand.accentText)
            Text(value).font(.headline).foregroundStyle(.primary)
            Text(label).font(.caption2).foregroundStyle(Color.primary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Recall

    private var recallPhase: some View {
        VStack(spacing: 18) {
            ProgressView(value: session.progress).tint(Brand.accent)

            Text("Do you still remember this one?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let item = session.currentItem {
                Text(item.symbol)
                    .font(.system(size: 84))
                    .padding(.vertical, 4)

                answerSlots

                if !revealed {
                    letterTray
                    controlRow
                } else {
                    revealFeedback
                    Spacer()
                    PrimaryButton(
                        title: session.index + 1 < session.items.count ? "Next" : "Finish",
                        systemImage: "arrow.right"
                    ) {
                        revealed = false
                        session.advance()
                    }
                }
            }
        }
        .onChange(of: session.built) { _, _ in
            if session.isWordComplete, session.lastOutcome != nil { showReveal() }
        }
    }

    private var answerSlots: some View {
        let builtChars = Array(session.built)
        let count = session.target.count
        return HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                let char = i < builtChars.count ? String(builtChars[i]) : ""
                Text(char)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .frame(width: 34, height: 44)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(slotColor, lineWidth: 1.5))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var slotColor: Color {
        guard revealed, let out = session.lastOutcome else { return Color.primary.opacity(0.15) }
        return out.remembered ? Brand.success : Brand.danger
    }

    private var letterTray: some View {
        FlowRow(spacing: 10) {
            ForEach(session.tray) { tile in
                Button {
                    if store.soundEnabled { SoundPlayer.shared.play(.tap) }
                    if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                    session.place(tileID: tile.id)
                } label: {
                    GameTile(cornerRadius: 12) {
                        Text(String(tile.letter))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .frame(width: 46, height: 52)
                            .foregroundStyle(.primary)
                    }
                    .opacity(tile.used ? 0.3 : 1)
                }
                .buttonStyle(.plain)
                .disabled(tile.used)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button {
                if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                session.removeLast()
            } label: {
                Label("Delete", systemImage: "delete.left.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Color.primary.opacity(0.85))
            }
            .buttonStyle(.plain)
            .disabled(session.built.isEmpty)

            Button {
                if store.soundEnabled { SoundPlayer.shared.play(.tap) }
                if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                session.useHint()
            } label: {
                Label("Hint", systemImage: "lightbulb.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Brand.accent.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .disabled(!session.canUseHint)
        }
    }

    @ViewBuilder
    private var revealFeedback: some View {
        if let out = session.lastOutcome, let item = session.currentItem {
            VStack(spacing: 6) {
                Label(out.remembered ? "Still there!" : "It slipped — now refreshed",
                      systemImage: out.remembered ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                    .font(.headline)
                    .foregroundStyle(out.remembered ? Brand.successText : Brand.accent)
                if !out.remembered {
                    Text("It was \(item.word.localizedContent).")
                        .font(.subheadline).foregroundStyle(Color.primary.opacity(0.8))
                }
            }
            .padding(.top, 4)
        }
    }

    private func showReveal() {
        guard !revealed, let out = session.lastOutcome else { return }
        revealed = true
        store.recordReview(key: out.key, remembered: out.remembered)
        if store.soundEnabled { SoundPlayer.shared.play(out.remembered ? .correct : .incorrect) }
        if store.hapticsEnabled { HapticsPlayer.shared.notify(success: out.remembered) }
    }

    // MARK: Summary

    private var summaryPhase: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 68))
                .foregroundStyle(Brand.accentText)
            Text("Review done")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("\(session.rememberedCount) of \(session.items.count) still remembered")
                .font(.headline)
                .foregroundStyle(Color.primary.opacity(0.85))

            if let retention = store.retentionScore {
                StatChip(title: "Retention", value: "\(retention)",
                         systemImage: "clock.arrow.circlepath", tint: Brand.accent)
                    .frame(maxWidth: 160)
            }

            Text("Refreshed items come back a little later next time. Nothing to keep up with — just drop by when they're due.")
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.6))
                .multilineTextAlignment(.center)

            Spacer()
            PrimaryButton(title: "Back to home", systemImage: "house.fill") { dismiss() }
        }
    }
}
