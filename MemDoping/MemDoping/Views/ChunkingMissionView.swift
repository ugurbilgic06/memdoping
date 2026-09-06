//
//  ChunkingMissionView.swift
//  MemDoping
//
//  T03 Chunking. Split a long number into small groups, hold it, type it
//  back. Grouping is by tapping the gaps between digits rather than dragging:
//  it keeps the digit order intact and stays usable with VoiceOver.
//

import SwiftUI

struct ChunkingMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: ChunkingSession
    @State private var outcome: GameStore.SessionOutcome?

    init(level: GameLevel) {
        _session = State(initialValue: ChunkingSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(tint: session.level.tileBase)

            Group {
                switch session.phase {
                case .intro:    introPhase
                case .group:    groupPhase
                case .study:    studyPhase
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
                MissionStat("\(session.digits.count)", "digits", "number"),
                MissionStat("\(session.suggestedChunkSize)", "per group", "square.grid.3x1.below.line.grid.1x2"),
                MissionStat("\(session.level.memorizeSeconds)s", "to study", "timer")
            ],
            onStart: { session.beginGrouping() }
        )
    }

    // MARK: Group — tap the gaps to split the number

    private var groupPhase: some View {
        VStack(spacing: 20) {
            header("Split it up", systemImage: "scissors")

            Text("Tap between digits to break this number into small groups. Groups of \(session.suggestedChunkSize) are easiest to hold.")
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.8))
                .multilineTextAlignment(.center)

            Spacer()

            splittableNumber

            Text("\(session.chunks.count) groups")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.accentText)

            Spacer()

            PrimaryButton(title: "Memorize it", systemImage: "brain.head.profile") {
                if store.soundEnabled { SoundPlayer.shared.play(.tap) }
                session.beginStudying()
            }
            .opacity(session.canStartStudying ? 1 : 0.4)
            .disabled(!session.canStartStudying)
        }
    }

    /// The digits with tappable gaps between them. A gap shows a divider once
    /// it's been tapped, so the grouping the player chose stays visible.
    private var splittableNumber: some View {
        HStack(spacing: 0) {
            ForEach(Array(session.digits.enumerated()), id: \.offset) { index, digit in
                if index > 0 {
                    Button {
                        if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                        session.toggleBreak(at: index)
                    } label: {
                        Rectangle()
                            .fill(session.breaks.contains(index) ? Brand.accent : Color.primary.opacity(0.12))
                            .frame(width: session.breaks.contains(index) ? 4 : 2, height: 34)
                            .padding(.horizontal, 6)
                            .contentShape(Rectangle().inset(by: -8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(session.breaks.contains(index)
                                        ? "Remove break" : "Add break")
                }
                Text("\(digit)")
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: session.breaks)
    }

    // MARK: Study

    private var studyPhase: some View {
        VStack(spacing: 20) {
            HStack {
                Label("Memorize", systemImage: "eye.fill")
                    .font(.headline).foregroundStyle(.primary)
                Spacer()
                Text("\(session.studySecondsRemaining)s")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(Brand.accentText)
                    .accessibilityLabel("\(session.studySecondsRemaining) seconds left")
            }

            ProgressView(value: Double(session.studySecondsRemaining),
                         total: Double(max(session.level.memorizeSeconds, 1)))
                .tint(Brand.accent)

            Spacer()
            chunkRow(session.chunks, highlight: false)
            Spacer()

            Text("Say each group out loud as one number, not digit by digit.")
                .font(.footnote)
                .foregroundStyle(Color.primary.opacity(0.75))
                .multilineTextAlignment(.center)

            PrimaryButton(title: "I'm ready", systemImage: "checkmark") {
                session.beginRecall()
            }
        }
        .onAppear { startStudyTimer() }
        .onDisappear { studyTimer?.invalidate(); studyTimer = nil }
    }

    @State private var studyTimer: Timer?

    private func startStudyTimer() {
        studyTimer?.invalidate()
        studyTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            session.tickStudyTimer()
        }
    }

    // MARK: Recall

    private var recallPhase: some View {
        VStack(spacing: 18) {
            header("Type it back", systemImage: "keyboard")

            entryDisplay

            Spacer()

            keypad
        }
    }

    private var entryDisplay: some View {
        HStack(spacing: 10) {
            ForEach(Array(session.chunks.enumerated()), id: \.offset) { chunkIndex, chunk in
                HStack(spacing: 2) {
                    ForEach(Array(chunk.enumerated()), id: \.offset) { digitIndex, _ in
                        let absolute = session.chunks.prefix(chunkIndex).reduce(0) { $0 + $1.count } + digitIndex
                        let typed = session.entered.indices.contains(absolute) ? session.entered[absolute] : nil
                        Text(typed.map(String.init) ?? "•")
                            .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(typed == nil ? Color.primary.opacity(0.25) : Color.primary)
                            .frame(width: 26)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var keypad: some View {
        VStack(spacing: 10) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { digit in
                        keypadButton(digit)
                    }
                }
            }
            HStack(spacing: 10) {
                Color.clear.frame(maxWidth: .infinity)
                keypadButton(0)
                Button {
                    if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                    session.deleteLast()
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .foregroundStyle(Color.primary.opacity(0.8))
                }
                .buttonStyle(.plain)
                .disabled(session.entered.isEmpty)
            }
        }
    }

    private func keypadButton(_ digit: Int) -> some View {
        Button {
            if store.soundEnabled { SoundPlayer.shared.play(.tap) }
            if store.hapticsEnabled { HapticsPlayer.shared.tap() }
            session.enter(digit)
        } label: {
            GameTile(base: session.level.tileBase, cornerRadius: 16) {
                Text("\(digit)")
                    .font(.system(size: 26, weight: .semibold, design: .rounded).monospacedDigit())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Feedback

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("How did the groups hold?")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text("\(session.correctChunks) of \(session.totalChunks) groups recalled")
                .foregroundStyle(Color.primary.opacity(0.8))

            VStack(alignment: .leading, spacing: 10) {
                comparisonRow("You typed", session.enteredChunks, against: session.chunks)
                comparisonRow("The number", session.chunks, against: session.chunks)
            }

            Card {
                Label {
                    Text("Whole groups count, not single digits — holding \"497\" as one piece is the skill.")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.85))
                } icon: {
                    Image(systemName: "lightbulb.fill").foregroundStyle(Brand.accentText)
                }
            }

            Text("\(session.correctDigits) of \(session.digits.count) individual digits were right.")
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.6))

            PrimaryButton(title: "See results", systemImage: "arrow.right") {
                let result = store.complete(
                    level: session.level,
                    correct: session.correctChunks,
                    total: session.totalChunks
                )
                outcome = result
                if store.soundEnabled { SoundPlayer.shared.play(result.mastered ? .levelUp : .correct) }
                if store.hapticsEnabled { HapticsPlayer.shared.notify(success: result.mastered) }
                session.showSummary()
            }
        }
    }

    private func comparisonRow(_ label: LocalizedStringKey, _ groups: [[Int]], against truth: [[Int]]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(Color.primary.opacity(0.6))
            HStack(spacing: 8) {
                ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                    let isCorrect = truth.indices.contains(index) && truth[index] == group
                    Text(group.map(String.init).joined())
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(
                            (isCorrect ? Brand.success : Brand.danger).opacity(0.3),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: Shared bits

    private func header(_ title: LocalizedStringKey, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.headline).foregroundStyle(.primary)
            Spacer()
        }
    }

    /// The number shown as the player grouped it — the whole point is that
    /// they see their own chunks, not the raw digit run.
    private func chunkRow(_ groups: [[Int]], highlight: Bool) -> some View {
        HStack(spacing: 10) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                Text(group.map(String.init).joined())
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12).padding(.vertical, 12)
                    .background(
                        (highlight ? Brand.accent.opacity(0.3) : Color.primary.opacity(0.08)),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Chunking — group a number") {
    ChunkingMissionView(level: SampleLevels.level(at: 2)!)
        .environment(GameStore())
}
