//
//  WorldLevelsView.swift
//  MemDoping
//
//  One world, shown as a path rather than a list: the level you're on is a big
//  card you can start straight away, and the rest of the world is a compact row
//  of numbered stones. Twenty full-width rows (nineteen of them locked) read as
//  a wall of homework, which is exactly what this app is not.
//

import SwiftUI

struct WorldLevelsView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.goToStart) private var goToStart
    let world: LadderWorld
    /// Launching a level is owned by the home screen, which already hosts the
    /// mission navigation destination.
    let onPick: (GameLevel) -> Void

    private var levels: [GameLevel] { SampleLevels.all.filter { world.range.contains($0.index) } }
    private var unlockedCount: Int { levels.filter { $0.index <= store.highestUnlockedLevel }.count }

    /// The level to lead with: the first one not yet mastered, else the last.
    private var current: GameLevel? {
        levels.first { $0.index > store.highestUnlockedLevel - 1 && $0.index <= store.highestUnlockedLevel }
            ?? levels.first { $0.index <= store.highestUnlockedLevel }
            ?? levels.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                arcCard
                if let current, current.index <= store.highestUnlockedLevel {
                    currentCard(current)
                }
                stonesSection
            }
            .padding()
        }
        .background(BrandBackground(seed: world.id).ignoresSafeArea())
        .navigationTitle(world.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Straight back to where the app opens, not just one step back.
            ToolbarItem(placement: .topBarTrailing) {
                Button { goToStart() } label: {
                    // A plain nav-bar glyph was too faint to notice, so it
                    // sits on a solid capsule.
                    Image(systemName: "house.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11).padding(.vertical, 7)
                        .background(Brand.accent, in: Capsule())
                        .shadow(color: Brand.accent.opacity(0.45), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Back to home"))
            }
        }
    }

    // MARK: The world's story

    private var arcCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Brand.gloss(world.tint))
                    .frame(width: 58, height: 58)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
                    .shadow(color: world.tint.opacity(0.45), radius: 6, y: 3)
                Text(world.emoji).font(.system(size: 30))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(world.arc)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text)
                    .fixedSize(horizontal: false, vertical: true)
                // What this world trains, in the chosen audience's terms — the
                // same line the world card showed, so entering confirms rather
                // than surprises.
                Text(world.blurb(for: store.ageBand))
                    .font(.caption)
                    .foregroundStyle(Brand.text.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(unlockedCount)/\(levels.count)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Brand.accentText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.6),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
    }

    // MARK: The one you're on

    private func currentCard(_ level: GameLevel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Symbol3DTile(symbol: level.theme.pairs.first?.symbol ?? "🧠",
                             tint: level.tileBase, size: 84)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Level \(level.index)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Brand.accentText)
                    Text(level.title.localizedContent)
                        .font(.title3.bold())
                        .foregroundStyle(Brand.text)
                    Text(level.technique.localizedContent)
                        .font(.caption)
                        .foregroundStyle(Brand.text.opacity(0.7))
                }
                Spacer(minLength: 0)
            }
            Text(level.techniqueBenefit(for: store.ageBand))
                .font(.caption)
                .foregroundStyle(Brand.text.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Play", systemImage: "play.fill") { onPick(level) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.62),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
    }

    // MARK: The rest of the world, as stones

    private var stonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("The road ahead")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.text.opacity(0.8))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5),
                      spacing: 10) {
                ForEach(levels) { level in
                    stone(level)
                }
            }
        }
    }

    private func stone(_ level: GameLevel) -> some View {
        let unlocked = level.index <= store.highestUnlockedLevel
        let best = store.bestAccuracy[level.index]
        let mastered = (best ?? 0) >= level.masteryPercent

        return Button {
            if unlocked { onPick(level) }
        } label: {
            ZStack {
                Circle()
                    .fill(unlocked ? Brand.gloss(level.tileBase)
                                   : Brand.gloss(Brand.text.opacity(0.07)))
                    .overlay(Circle().strokeBorder(Brand.edgeHighlight, lineWidth: 1))
                    .shadow(color: unlocked ? level.tileBase.opacity(0.4) : .clear, radius: 4, y: 2)
                if unlocked {
                    Text(verbatim: "\(level.index)")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(Brand.text.opacity(0.35))
                }
                if mastered {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(Brand.successText)
                        .background(Circle().fill(.white).frame(width: 14, height: 14))
                        .offset(x: 16, y: -16)
                }
            }
            .frame(height: 52)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel(Text(level.title.localizedContent))
    }
}
