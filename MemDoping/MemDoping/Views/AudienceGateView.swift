//
//  AudienceGateView.swift
//  MemDoping
//
//  "Who's playing?" — asked before the worlds appear. Each choice is a coloured
//  card that says, in three words, how the journey goes (start → build →
//  result) and what it grows, so the player picks on substance, not a guess.
//  The band is a lens, not a separate track: it shifts tone and starting
//  difficulty (GameStore.ageOffset) while every world stays playable.
//

import SwiftUI

struct AudienceGateView: View {
    @Environment(GameStore.self) private var store
    /// Called once a band is picked, so the caller can dismiss the gate.
    var onPick: (GameStore.AgeBand) -> Void
    /// Offered only when a band was already chosen on an earlier run — skips
    /// straight back in without asking the same question again.
    var onContinue: (() -> Void)?

    var body: some View {
        ZStack {
            BrandBackground(seed: 2)

            ScrollView {
                VStack(spacing: 20) {
                    Text("🧠")
                        .font(.system(size: 64))
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
                        .padding(.top, 8)

                    VStack(spacing: 8) {
                        Text("Who's playing?")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Brand.text)
                            .multilineTextAlignment(.center)
                        Text("We'll set a comfortable starting difficulty — you can change it any time in your profile.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    if let onContinue, let band = store.ageBand {
                        continueCard(band, action: onContinue)
                            .padding(.horizontal, 20)
                    }

                    VStack(spacing: 14) {
                        card(.child).dealIn(0)
                        card(.teen).dealIn(1)
                        card(.adult).dealIn(2)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: Pick up where you left off

    private func continueCard(_ band: GameStore.AgeBand, action: @escaping () -> Void) -> some View {
        let tint = bandTint(band)
        return Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue where you left off")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Level \(store.currentLevel.index) · \(bandTitleText(band))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.gloss(tint), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
            .shadow(color: tint.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(TileButtonStyle())
    }

    /// The band's name as a plain string, for interpolation.
    private func bandTitleText(_ band: GameStore.AgeBand) -> String {
        switch band {
        case .child: "Child".localizedContent
        case .teen:  "Teen".localizedContent
        case .adult: "Adult".localizedContent
        }
    }

    // MARK: One choice

    private func card(_ band: GameStore.AgeBand) -> some View {
        let tint = bandTint(band)
        let isCurrent = store.ageBand == band

        return Button {
            store.setAgeBand(band)
            if store.hapticsEnabled { HapticsPlayer.shared.tap() }
            onPick(band)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Brand.gloss(tint))
                            .frame(width: 54, height: 54)
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
                            .shadow(color: tint.opacity(0.45), radius: 6, y: 3)
                        Text(bandEmoji(band)).font(.system(size: 28))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bandTitle(band))
                            .font(.title3.bold())
                            .foregroundStyle(Brand.text)
                        Text(bandPace(band))
                            .font(.caption)
                            .foregroundStyle(Brand.text.opacity(0.7))
                    }
                    Spacer(minLength: 0)
                    if isCurrent {
                        // Mark the band already in use, so the three cards read
                        // as "switch to" rather than "start over".
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(tint)
                            .accessibilityLabel(Text("Current"))
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Brand.text.opacity(0.45))
                }

                // start → build → result, in three words.
                HStack(spacing: 6) {
                    ForEach(Array(bandStages(band).enumerated()), id: \.offset) { i, stage in
                        Text(stage)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(tint.opacity(0.22), in: Capsule())
                            .foregroundStyle(Brand.text)
                        if i < 2 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Brand.text.opacity(0.35))
                        }
                    }
                    Spacer(minLength: 0)
                }

                // What it actually grows.
                Text(bandGain(band))
                    .font(.caption)
                    .foregroundStyle(Brand.text.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.66),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(tint.opacity(0.55), lineWidth: 1.5))
            .shadow(color: tint.opacity(0.18), radius: 8, y: 4)
        }
        .buttonStyle(TileButtonStyle())
    }

    // MARK: Per-band copy

    private func bandEmoji(_ band: GameStore.AgeBand) -> String {
        switch band {
        case .child: "🧸"
        case .teen:  "🎧"
        case .adult: "☕"
        }
    }

    private func bandTitle(_ band: GameStore.AgeBand) -> LocalizedStringKey {
        switch band {
        case .child: "Child"
        case .teen:  "Teen"
        case .adult: "Adult"
        }
    }

    private func bandPace(_ band: GameStore.AgeBand) -> LocalizedStringKey {
        switch band {
        case .child: "Gentle pace, more time"
        case .teen:  "Balanced"
        case .adult: "A little more challenge"
        }
    }

    /// start → build → result.
    private func bandStages(_ band: GameStore.AgeBand) -> [LocalizedStringKey] {
        switch band {
        case .child: ["Notice", "Picture it", "Keep it"]
        case .teen:  ["Focus", "Group it", "Recall"]
        case .adult: ["Attend", "Link it", "Retrieve"]
        }
    }

    private func bandGain(_ band: GameStore.AgeBand) -> LocalizedStringKey {
        switch band {
        case .child: "Grows attention, imagination and remembering in order."
        case .teen:  "Fewer re-reads, more that sticks — where it counts, at exam time."
        case .adult: "Names, numbers and talks — held without notes."
        }
    }

    private func bandTint(_ band: GameStore.AgeBand) -> Color {
        switch band {
        case .child: Color(hue: 0.045, saturation: 0.78, brightness: 0.97)  // warm coral
        case .teen:  Color(hue: 0.600, saturation: 0.80, brightness: 0.88)  // blue
        case .adult: Color(hue: 0.340, saturation: 0.80, brightness: 0.74)  // green
        }
    }
}
