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
    @Environment(GameStore.self) private var store
    let level: GameLevel
    let stats: [MissionStat]
    let onStart: () -> Void

    var body: some View {
        // Pin the Start button; let the briefing scroll so large Dynamic Type
        // sizes never push the call to action off-screen.
        VStack(spacing: 16) {
            ScrollView {
                briefing
            }
            PrimaryButton(title: "Start", systemImage: "play.fill", action: onStart)
        }
    }

    private var briefing: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Level \(level.index)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Brand.accentText)
            Text(level.title.localizedContent)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label(level.technique.localizedContent, systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(level.techniqueExplanation)
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)

                    // The scientific reason — richer detail for teens/adults;
                    // skipped for the child band, where it isn't needed.
                    if store.ageBand != .child {
                        Label {
                            Text(level.techniqueScience)
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.7))
                        } icon: {
                            Image(systemName: "flask.fill").foregroundStyle(Brand.primary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                    }

                    Label {
                        Text(level.tip.localizedContent)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "lightbulb.fill").foregroundStyle(Brand.accentText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                }
            }

            HStack(spacing: 12) {
                ForEach(stats) { stat in
                    VStack(spacing: 4) {
                        Image(systemName: stat.icon).foregroundStyle(Brand.accentText)
                        Text(stat.value).font(.headline).foregroundStyle(.primary)
                        Text(stat.label).font(.caption2).foregroundStyle(Color.primary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .combine)
                }
            }

            Text("Sample content — a prototype mission, not final curriculum.")
                .font(.caption2)
                .foregroundStyle(Color.primary.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
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
    @State private var titleScale: CGFloat = 0.7

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
                        .foregroundStyle(Color.primary.opacity(0.8))
                        .scaleEffect(celebrationScale)
                }
            }
            .onAppear(perform: revealCelebration)

            Text(passedMastery ? "Level cleared!" : "Good effort")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
                .scaleEffect(passedMastery ? titleScale : 1)

            if let outcome {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        StatChip(title: "MemDoping XP", value: "+\(outcome.xpEarned)",
                                 systemImage: "bolt.fill", tint: Brand.accent)
                            .dealIn(0)
                        StatChip(title: "Accuracy",
                                 value: "\(Int(accuracy * 100))%",
                                 systemImage: "target")
                            .dealIn(1)
                        StatChip(title: "Memory Score",
                                 value: outcome.memoryScore.map { "\($0)" } ?? "—",
                                 systemImage: "brain.head.profile")
                            .dealIn(2)
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
                            .foregroundStyle(Color.primary.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
            }

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "Play again", systemImage: "arrow.counterclockwise", action: onRetry)
                Button("Back to home", action: onExit)
                    .foregroundStyle(Color.primary.opacity(0.85))
                    .padding(.vertical, 8)
            }
        }
    }

    private func revealCelebration() {
        guard !reduceMotion else {
            celebrationScale = 1
            titleScale = 1
            badgesVisible = true
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
            celebrationScale = 1
        }
        // A bouncy title pop just after the trophy lands.
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.15)) {
            titleScale = 1
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.25)) {
            badgesVisible = true
        }
    }

    private func badge(_ text: LocalizedStringKey, _ icon: String, _ tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
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
        let x: CGFloat          // horizontal start, as a 0…1 fraction of width
        let drift: CGFloat      // sideways sway as it falls
        let delay: Double
        let duration: Double
        let rotation: Double
        let size: CGFloat
        let isCircle: Bool
    }

    @State private var animate = false
    private let pieces: [Piece] = (0..<64).map { _ in
        Piece(
            color: [Brand.accent, Brand.success, Brand.primary,
                    Brand.danger, Color(red: 1.0, green: 0.78, blue: 0.30)].randomElement()!,
            x: CGFloat.random(in: 0.02...0.98),
            drift: CGFloat.random(in: -60...60),
            delay: Double.random(in: 0...0.5),
            duration: Double.random(in: 1.3...2.2),
            rotation: Double.random(in: 180...1080),
            size: CGFloat.random(in: 7...13),
            isCircle: Bool.random()
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { p in
                    Group {
                        if p.isCircle {
                            Circle().fill(p.color).frame(width: p.size, height: p.size)
                        } else {
                            Rectangle().fill(p.color)
                                .frame(width: p.size, height: p.size * 0.45)
                        }
                    }
                    .rotationEffect(.degrees(animate ? p.rotation : 0))
                    .position(x: p.x * geo.size.width + (animate ? p.drift : 0),
                              y: animate ? geo.size.height + 50 : -50)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeIn(duration: p.duration).delay(p.delay), value: animate)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
        .accessibilityHidden(true)
    }
}
