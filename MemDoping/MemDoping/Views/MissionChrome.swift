//
//  MissionChrome.swift
//  MemDoping
//
//  The parts of a mission that look the same whichever technique it teaches:
//  the briefing screen and the results screen. Each mechanic supplies its own
//  middle (study/recall) but shares this frame, so a new mechanic doesn't
//  bring another copy of the same layout with it.
//

import SwiftUI

/// One tile in the intro's stats row (e.g. "4 to learn").
struct MissionStat: Identifiable {
    let id = UUID()
    let value: String
    let label: LocalizedStringKey
    let icon: String

    init(_ value: String, _ label: LocalizedStringKey, _ icon: String) {
        self.value = value
        self.label = label
        self.icon = icon
    }
}

/// Mission briefing: what this level teaches, and one rule to hold on to.
struct MissionIntro: View {
    let level: GameLevel
    let stats: [MissionStat]
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("Level \(level.index)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Brand.accent)
            Text(level.title.localizedContent)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label(level.technique.localizedContent, systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(level.tip.localizedContent)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            HStack(spacing: 12) {
                ForEach(stats) { stat in
                    VStack(spacing: 4) {
                        Image(systemName: stat.icon).foregroundStyle(Brand.accent)
                        Text(stat.value).font(.headline).foregroundStyle(.white)
                        Text(stat.label).font(.caption2).foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .combine)
                }
            }

            Spacer()
            Text("Sample content — a prototype mission, not final curriculum.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            PrimaryButton(title: "Start", systemImage: "play.fill", action: onStart)
        }
    }
}

/// Mission results: XP, Memory Score, and a clear stopping point (§2).
struct MissionSummary: View {
    let passedMastery: Bool
    let accuracy: Double
    let outcome: GameStore.SessionOutcome?
    let onRetry: () -> Void
    let onExit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrationScale: CGFloat = 0.6
    @State private var badgesVisible = false

    var body: some View {
        ZStack {
            if passedMastery && !reduceMotion {
                ConfettiView().allowsHitTesting(false)
            }
            content
        }
    }

    private var content: some View {
        VStack(spacing: 20) {
            Spacer()
            Group {
                if passedMastery {
                    Celebration3DView(size: 150, spins: !reduceMotion)
                } else {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.white.opacity(0.8))
                        .scaleEffect(celebrationScale)
                }
            }
            .onAppear(perform: revealCelebration)

            Text(passedMastery ? "Level cleared!" : "Good effort")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            if let outcome {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        StatChip(title: "MemDoping XP", value: "+\(outcome.xpEarned)",
                                 systemImage: "bolt.fill", tint: Brand.accent)
                        StatChip(title: "Accuracy",
                                 value: "\(Int(accuracy * 100))%",
                                 systemImage: "target")
                        StatChip(title: "Memory Score",
                                 value: outcome.memoryScore.map { "\($0)" } ?? "—",
                                 systemImage: "brain.head.profile")
                    }
                    if outcome.unlockedNextLevel {
                        badge("New level unlocked!", "lock.open.fill", Brand.success)
                            .scaleEffect(badgesVisible ? 1 : 0.7)
                            .opacity(badgesVisible ? 1 : 0)
                    }
                    if outcome.isNewBest {
                        badge("New personal best", "rosette", Brand.accent)
                            .scaleEffect(badgesVisible ? 1 : 0.7)
                            .opacity(badgesVisible ? 1 : 0)
                    }
                    if outcome.memoryScore == nil {
                        Text("Play \(GameStore.minSessionsForScore) missions to reveal your Memory Score.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
            }

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "Play again", systemImage: "arrow.counterclockwise", action: onRetry)
                Button("Back to home", action: onExit)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.vertical, 8)
            }
        }
    }

    private func revealCelebration() {
        guard !reduceMotion else {
            celebrationScale = 1
            badgesVisible = true
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
            celebrationScale = 1
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.25)) {
            badgesVisible = true
        }
    }

    private func badge(_ text: LocalizedStringKey, _ icon: String, _ tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(tint.opacity(0.25), in: Capsule())
            .overlay(Capsule().stroke(tint, lineWidth: 1))
    }
}

// MARK: - Level-up celebration

/// A short, dependency-free confetti burst for mastering a level (§4 Sensory
/// Motivation Engine: "progress reveals and satisfying completion feedback").
/// Skipped entirely under Reduce Motion by the caller, not just slowed down.
struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let color: Color
        let startX: CGFloat
        let endX: CGFloat
        let endY: CGFloat
        let rotation: Double
        let size: CGFloat
    }

    @State private var animate = false
    private let pieces: [Piece] = (0..<24).map { _ in
        Piece(
            color: [Brand.accent, Brand.success, Brand.primary, .white].randomElement()!,
            startX: CGFloat.random(in: -16...16),
            endX: CGFloat.random(in: -150...150),
            endY: CGFloat.random(in: 240...460),
            rotation: Double.random(in: 180...900),
            size: CGFloat.random(in: 6...11)
        )
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.4)
                    .rotationEffect(.degrees(animate ? piece.rotation : 0))
                    .offset(x: animate ? piece.endX : piece.startX, y: animate ? piece.endY : -30)
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                animate = true
            }
        }
        .accessibilityHidden(true)
    }
}
