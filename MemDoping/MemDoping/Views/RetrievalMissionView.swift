//
//  RetrievalMissionView.swift
//  MemDoping
//
//  T04 Retrieval Practice ("Şimdi Sen Söyle"). No answer choices: the player
//  rebuilds each word from scrambled letter tiles. A free hint reveals the next
//  letter, and words solved without it are called out separately so unaided
//  recall feels like the win it is (self-efficacy, §7).
//

import SwiftUI

struct RetrievalMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: RetrievalSession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var revealed = false
    @State private var learnTimer: Timer?
    @State private var dragTileId: UUID? = nil
    @State private var dragOffset: CGSize = .zero

    init(level: GameLevel) {
        _session = State(initialValue: RetrievalSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(tint: session.level.tileBase)

            Group {
                switch session.phase {
                case .intro:    introPhase
                case .learn:    learnPhase
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
                MissionStat("\(session.level.itemCount)", "to learn", "square.stack.3d.up"),
                MissionStat("\(session.level.questionCount)", "to recall", "keyboard"),
                MissionStat("\(session.level.memorizeSeconds)s", "to study", "timer")
            ],
            onStart: { session.beginLearning() }
        )
    }

    // MARK: Learn — study the deck against a timer

    private var learnPhase: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Memorize", systemImage: "eye.fill")
                    .font(.headline).foregroundStyle(.primary)
                Spacer()
                Text("\(session.learnSecondsRemaining)s")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(Brand.accent)
                    .accessibilityLabel("\(session.learnSecondsRemaining) seconds left")
            }

            ProgressView(value: Double(session.learnSecondsRemaining),
                         total: Double(max(session.level.memorizeSeconds, 1)))
                .tint(Brand.accent)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(session.studyPairs) { pair in
                        GameTile(base: session.level.tileBase) {
                            VStack(spacing: 8) {
                                Text(pair.symbol).font(.system(size: 46))
                                Text(pair.word.localizedContent)
                                    .font(.headline).foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                        .gentleFloat(abs(pair.id.hashValue))
                    }
                }
            }

            Text("Try to recall each word yourself in a moment — even if it feels hard, that's what makes it stick.")
                .font(.footnote)
                .foregroundStyle(Color.primary.opacity(0.75))
                .multilineTextAlignment(.center)

            PrimaryButton(title: "I'm ready", systemImage: "checkmark") {
                session.beginRecall()
            }
        }
        .onAppear {
            learnTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                session.tickLearnTimer()
            }
        }
        .onChange(of: session.phase) { _, newValue in
            if newValue != .learn { learnTimer?.invalidate(); learnTimer = nil }
        }
        .onDisappear { learnTimer?.invalidate(); learnTimer = nil }
    }

    // MARK: Recall — rebuild the word from letter tiles

    private var recallPhase: some View {
        VStack(spacing: 18) {
            ProgressView(value: session.recallProgress).tint(Brand.accent)

            Text("Spell the word for this symbol")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            if let pair = session.currentPair {
                Text(pair.symbol)
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
                        title: session.promptIndex + 1 < session.totalQuestions ? "Next" : "Finish",
                        systemImage: "arrow.right"
                    ) {
                        revealed = false
                        session.advanceAfterWord()
                    }
                }
            }
        }
        .onChange(of: session.built) { _, _ in
            // A word auto-evaluates once every slot is filled.
            if session.isWordComplete, session.lastRecall != nil { showReveal() }
        }
    }

    /// One box per letter of the target; filled left-to-right as tiles are placed.
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(revealColor(for: i), lineWidth: 1.5)
                    )
                    .foregroundStyle(.primary)
            }
        }
    }

    private func revealColor(for index: Int) -> Color {
        guard revealed, let last = session.lastRecall else { return Color.primary.opacity(0.15) }
        return last.correct ? Brand.success : Brand.danger
    }

    private var letterTray: some View {
        FlowRow(spacing: 10) {
            ForEach(session.tray) { tile in
                GameTile(base: session.level.tileBase, cornerRadius: 12) {
                    Text(String(tile.letter))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .frame(width: 46, height: 52)
                        .foregroundStyle(.primary)
                }
                .opacity(tile.used ? 0.3 : 1)
                .offset(dragTileId == tile.id ? dragOffset : .zero)
                .zIndex(dragTileId == tile.id ? 1 : 0)
                .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                           value: dragTileId == tile.id ? dragOffset : .zero)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            guard !tile.used else { return }
                            dragTileId = tile.id; dragOffset = g.translation
                        }
                        .onEnded { g in
                            if !tile.used, g.translation.height < -80 {
                                session.place(tileID: tile.id)
                                if store.soundEnabled { SoundPlayer.shared.play(.pop) }
                                if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                            } else if !tile.used {
                                // A tap-like short drag still places it, for ease.
                                let moved = abs(g.translation.width) + abs(g.translation.height)
                                if moved < 8 {
                                    session.place(tileID: tile.id)
                                    if store.soundEnabled { SoundPlayer.shared.play(.tap) }
                                }
                            }
                            dragTileId = nil; dragOffset = .zero
                        }
                )
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Brand.accent.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .disabled(!session.canUseHint)
        }
    }

    @ViewBuilder
    private var revealFeedback: some View {
        if let last = session.lastRecall {
            VStack(spacing: 6) {
                Label(
                    last.correct ? (last.usedHint ? "Right — with a hint" : "Nailed it, on your own!") : "Not quite",
                    systemImage: last.correct ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.headline)
                .foregroundStyle(last.correct ? Brand.success : Brand.danger)

                if !last.correct {
                    Text("It was \(last.pair.word.localizedContent).")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.8))
                }
            }
            .padding(.top, 4)
        }
    }

    private func showReveal() {
        guard !revealed, let last = session.lastRecall else { return }
        revealed = true
        if store.soundEnabled { SoundPlayer.shared.play(last.correct ? .correct : .incorrect) }
        if store.hapticsEnabled { HapticsPlayer.shared.notify(success: last.correct) }
    }

    // MARK: Feedback

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("How did recall go?")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text("\(session.correctCount) of \(session.totalQuestions) recalled · \(session.unaidedCount) with no hint")
                .foregroundStyle(Color.primary.opacity(0.8))
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(session.recalls) { r in
                        HStack(spacing: 12) {
                            Text(r.pair.symbol).font(.title)
                            Text(r.pair.word.localizedContent)
                                .font(.headline).foregroundStyle(.primary)
                            Spacer()
                            if r.correct && !r.usedHint {
                                Image(systemName: "star.fill").foregroundStyle(Brand.accent)
                            }
                            Image(systemName: r.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(r.correct ? Brand.success : Brand.danger)
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Card {
                Label {
                    Text("Testing yourself works harder than re-reading — especially the words that felt tough to pull up.")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.85))
                } icon: {
                    Image(systemName: "lightbulb.fill").foregroundStyle(Brand.accent)
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

#Preview("Retrieval — letter tiles") {
    RetrievalMissionView(level: SampleLevels.level(at: 5)!)
        .environment(GameStore())
}
