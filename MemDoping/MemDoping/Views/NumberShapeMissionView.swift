//
//  NumberShapeMissionView.swift
//  MemDoping
//
//  T11 Number-Shape ("Şekil-Sayı Kod"). Memorize a code shown as shapes, then
//  type it back. The digit→shape legend stays visible as a learning aid. Framed
//  honestly (weak evidence): no "never forget a number" claims.
//

import SwiftUI

struct NumberShapeMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: NumberShapeSession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var studyTimer: Timer?

    init(level: GameLevel) {
        _session = State(initialValue: NumberShapeSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(tint: session.level.tileBase)

            Group {
                switch session.phase {
                case .intro:    introPhase
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
                MissionStat("\(session.total)", "digits", "number"),
                MissionStat("10", "shapes", "square.on.circle"),
                MissionStat("\(session.level.memorizeSeconds)s", "to study", "timer")
            ],
            onStart: { session.beginStudying() }
        )
    }

    // MARK: Legend strip (digit → shape)

    private var legendStrip: some View {
        VStack(spacing: 6) {
            Text("The shape code")
                .font(.caption).foregroundStyle(.white.opacity(0.6))
            FlowRow(spacing: 8) {
                ForEach(session.legend, id: \.digit) { entry in
                    HStack(spacing: 3) {
                        Text("\(entry.digit)")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(Brand.accent)
                        Text(entry.shape).font(.body)
                    }
                    .padding(.horizontal, 7).padding(.vertical, 5)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: Study

    private var studyPhase: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Picture the shapes", systemImage: "eye.fill")
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Text("\(session.studySecondsRemaining)s")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(Brand.accent)
            }
            ProgressView(value: Double(session.studySecondsRemaining),
                         total: Double(max(session.level.memorizeSeconds, 1)))
                .tint(Brand.accent)

            Spacer()
            // The code as shapes.
            HStack(spacing: 12) {
                ForEach(Array(session.digits.enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 4) {
                        Text(session.shape(for: d)).font(.system(size: 46))
                        Text("\(d)").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.vertical, 12).padding(.horizontal, 10)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            Spacer()

            legendStrip

            PrimaryButton(title: "I'm ready", systemImage: "checkmark") {
                session.beginRecall()
            }
        }
        .onAppear { startTimer() }
        .onChange(of: session.phase) { _, p in if p != .study { stopTimer() } }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        stopTimer()
        studyTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            session.tickStudyTimer()
        }
    }
    private func stopTimer() { studyTimer?.invalidate(); studyTimer = nil }

    // MARK: Recall

    private var recallPhase: some View {
        VStack(spacing: 16) {
            Text("Type the code back")
                .font(.title3.weight(.semibold)).foregroundStyle(.white)

            // Entry slots.
            HStack(spacing: 10) {
                ForEach(0..<session.total, id: \.self) { i in
                    let typed = session.entered.indices.contains(i) ? session.entered[i] : nil
                    Text(typed.map(String.init) ?? "•")
                        .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(typed == nil ? .white.opacity(0.25) : .white)
                        .frame(width: 40, height: 52)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            legendStrip

            Spacer()
            keypad
        }
    }

    private var keypad: some View {
        VStack(spacing: 10) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 10) { ForEach(row, id: \.self) { keypadButton($0) } }
            }
            HStack(spacing: 10) {
                Color.clear.frame(maxWidth: .infinity)
                keypadButton(0)
                Button {
                    if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                    session.deleteLast()
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title2).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .disabled(session.entered.isEmpty)
            }
        }
    }

    private func keypadButton(_ digit: Int) -> some View {
        Button {
            if store.soundEnabled { SoundPlayer.shared.play(.pop) }
            if store.hapticsEnabled { HapticsPlayer.shared.tap() }
            session.enter(digit)
        } label: {
            GameTile(base: session.level.tileBase, cornerRadius: 16) {
                VStack(spacing: 2) {
                    Text("\(digit)")
                        .font(.system(size: 24, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                    Text(session.shape(for: digit)).font(.caption)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
            }
        }
        .buttonStyle(TileButtonStyle())
    }

    // MARK: Feedback

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("How did the code hold?")
                .font(.title2.bold()).foregroundStyle(.white)
            Text("\(session.correctCount) of \(session.total) digits correct")
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 10) {
                comparisonRow("You typed", session.entered)
                comparisonRow("The code", session.digits)
            }

            Card {
                Label {
                    Text("Turning digits into shapes gives your memory a picture to hold. A handy trick for short codes — not a magic guarantee.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                } icon: {
                    Image(systemName: "square.on.circle.fill").foregroundStyle(Brand.accent)
                }
            }

            PrimaryButton(title: "See results", systemImage: "arrow.right") {
                let result = store.complete(level: session.level,
                                            correct: session.correctCount, total: session.total)
                outcome = result
                if store.soundEnabled { SoundPlayer.shared.play(result.mastered ? .levelUp : .correct) }
                if store.hapticsEnabled { HapticsPlayer.shared.notify(success: result.mastered) }
                session.showSummary()
            }
        }
    }

    private func comparisonRow(_ label: LocalizedStringKey, _ seq: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 8) {
                ForEach(Array(seq.enumerated()), id: \.offset) { i, d in
                    let ok = session.digits.indices.contains(i) && session.digits[i] == d
                    VStack(spacing: 2) {
                        Text(session.shape(for: d)).font(.title3)
                        Text("\(d)").font(.caption.monospacedDigit()).foregroundStyle(.white)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background((ok ? Brand.success : Brand.danger).opacity(0.3),
                                in: RoundedRectangle(cornerRadius: 10))
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
            onRetry: { session = session.makeRetry(); outcome = nil },
            onExit: { dismiss() }
        )
    }
}

#Preview("Number shapes — secret code") {
    NumberShapeMissionView(level: SampleLevels.level(at: 12)!)
        .environment(GameStore())
}
