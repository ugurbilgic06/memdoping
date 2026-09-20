//
//  MechanicDemo.swift
//  MemDoping
//
//  A short, animated "show, don't tell" micro-tutorial for a level's mechanic —
//  it plays once on the intro screen instead of a wall of text (V2 Faz 1 §1.3).
//  A little owl narrator presents it with one sentence; the long explanation
//  lives in a collapsible "How it works" section. Still/instant under Reduce
//  Motion. Every mechanic has its own bespoke animation.
//

import SwiftUI

struct MechanicDemo: View {
    let mechanic: LevelMechanic
    var tint: Color
    /// One short caption shown under the animation (a content string).
    var caption: String
    /// Read aloud (on-device TTS). Pass the player's sound setting.
    var voice: Bool = false
    /// A richer, already-localized line for the narrator to speak. Falls back to
    /// the caption when nil, so the owl says more than the short on-screen label.
    var narration: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var runID = 0
    @State private var bob = false
    @State private var didNarrate = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Brand.text.opacity(0.05))
                stage
                    .id(runID)   // rebuilding restarts the animation
                    .padding(10)
                if !reduceMotion {
                    Button { runID += 1; narrate() } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption.weight(.bold))
                            .padding(7)
                            .background(.white.opacity(0.85), in: Circle())
                            .foregroundStyle(Brand.text)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(height: 230)

            // Owl narrator + the single caption sentence.
            HStack(spacing: 10) {
                Text("🦉")
                    .font(.system(size: 34))
                    .offset(y: bob ? -3 : 2)
                    .rotationEffect(.degrees(bob ? -4 : 4), anchor: .bottom)
                Text(caption.localizedContent)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.text)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.text.opacity(0.06))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
        .onAppear {
            if !didNarrate { didNarrate = true; narrate() }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { bob = true }
        }
        .onDisappear { NarratorVoice.shared.stop(); NarratorAudio.shared.stop() }
        .accessibilityElement()
        .accessibilityLabel(Text(caption.localizedContent))
    }

    /// Speak the narrator line when voice is enabled: prefer a bundled recording
    /// for this mechanic/language, and fall back to on-device TTS if none exists.
    private func narrate() {
        guard voice else { return }
        let lang = AppLocale.locale.language.languageCode?.identifier ?? "en"
        if NarratorAudio.shared.play(mechanic: mechanic, lang: lang) { return }
        NarratorVoice.shared.speak(narration ?? caption.localizedContent)
    }

    @ViewBuilder
    private var stage: some View {
        switch mechanic {
        case .chunking:     ChunkingDemo(tint: tint)
        case .numberShape:  NumberShapeDemo()
        case .pairRecall:   PairRecallDemo()
        case .scene:        SceneDemo()
        case .retrieval:    RetrievalDemo()
        case .loci:         LociDemo()
        case .interleaving: InterleaveDemo()
        case .elaboration:  ElaborationDemo()
        case .story:        StoryDemo()
        }
    }
}

// MARK: - Shared bits

private extension View {
    /// A small white content card used across the demos.
    func demoCard(_ corner: CGFloat = 10) -> some View {
        self.background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: corner))
            .overlay(RoundedRectangle(cornerRadius: corner).strokeBorder(Brand.edgeHighlight, lineWidth: 1))
    }
}

// MARK: - Chunking

private struct ChunkingDemo: View {
    var tint: Color
    @Environment(\.accessibilityReduceMotion) private var rm
    private let digits = ["4","9","7","1","6","2"]
    @State private var split = false
    @State private var glow = false
    var body: some View {
        HStack(spacing: split ? 16 : 4) {
            group(Array(digits[0..<3])); group(Array(digits[3..<6]))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if rm { split = true; glow = true; return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) { split = true }
            withAnimation(.easeInOut(duration: 0.5).delay(1.2)) { glow = true }
        }
    }
    private func group(_ ds: [String]) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(ds.enumerated()), id: \.offset) { _, d in
                Text(d).font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Brand.text).frame(width: 44, height: 58).demoCard(8)
            }
        }
        .padding(6)
        .background((glow ? tint.opacity(0.35) : .clear), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(glow ? Brand.accentText.opacity(0.6) : .clear, lineWidth: 2))
    }
}

// MARK: - Number-Shape (digit morphs into a look-alike shape)

private struct NumberShapeDemo: View {
    @Environment(\.accessibilityReduceMotion) private var rm
    @State private var morph = false
    var body: some View {
        ZStack {
            Text("2").font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundStyle(Brand.text).opacity(morph ? 0 : 1).scaleEffect(morph ? 0.6 : 1)
            Text("🦢").font(.system(size: 98)).opacity(morph ? 1 : 0).scaleEffect(morph ? 1 : 0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if rm { morph = true; return }
            withAnimation(.easeInOut(duration: 0.7).delay(0.7)) { morph = true }
        }
    }
}

// MARK: - Pair recall (see the pair, then the word hides)

private struct PairRecallDemo: View {
    @Environment(\.accessibilityReduceMotion) private var rm
    @State private var hide = false
    var body: some View {
        HStack(spacing: 14) {
            Text("🦊").font(.system(size: 72)).frame(width: 104, height: 104).demoCard(14)
            Image(systemName: "arrow.right").foregroundStyle(Brand.text.opacity(0.4))
            ZStack {
                Text("Fox").font(.headline).foregroundStyle(Brand.text).opacity(hide ? 0 : 1)
                Text("?").font(.title.bold()).foregroundStyle(Brand.accentText).opacity(hide ? 1 : 0)
            }
            .frame(width: 104, height: 104).demoCard(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if rm { hide = true; return }
            withAnimation(.easeInOut(duration: 0.5).delay(1.1)) { hide = true }
        }
    }
}

// MARK: - Scene (a twist lands on the item)

private struct SceneDemo: View {
    @Environment(\.accessibilityReduceMotion) private var rm
    @State private var landed = false
    var body: some View {
        ZStack {
            Text("🍎").font(.system(size: 96))
            Text("🔥").font(.system(size: 56))
                .offset(x: landed ? 40 : 130, y: landed ? -44 : -110)
                .opacity(landed ? 1 : 0)
                .rotationEffect(.degrees(landed ? 0 : 40))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if rm { landed = true; return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.7)) { landed = true }
        }
    }
}

// MARK: - Retrieval (scrambled letters assemble)

private struct RetrievalDemo: View {
    @Environment(\.accessibilityReduceMotion) private var rm
    private let letters = ["F","O","X"]
    @State private var together = false
    var body: some View {
        HStack(spacing: together ? 6 : 22) {
            ForEach(Array(letters.enumerated()), id: \.offset) { i, l in
                Text(l).font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.text).frame(width: 58, height: 70).demoCard(10)
                    .rotationEffect(.degrees(together ? 0 : (i == 0 ? -14 : i == 2 ? 14 : 6)))
                    .offset(y: together ? 0 : (i == 1 ? -10 : 8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if rm { together = true; return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.7)) { together = true }
        }
    }
}

// MARK: - Loci (item travels onto a place)

private struct LociDemo: View {
    @Environment(\.accessibilityReduceMotion) private var rm
    @State private var placed = false
    var body: some View {
        ZStack {
            Text("🚪").font(.system(size: 96)).offset(x: -26, y: -10)
            // The key comes to rest beside the door, not on top of it, so both
            // stay readable at the larger size.
            Text("🔑").font(.system(size: 56))
                .offset(x: placed ? 44 : 44, y: placed ? 6 : 100)
                .rotationEffect(.degrees(placed ? -12 : 0))
                .scaleEffect(placed ? 1.05 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if rm { placed = true; return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.7)) { placed = true }
        }
    }
}

// MARK: - Interleaving (mixed themes alternate)

private struct InterleaveDemo: View {
    @Environment(\.accessibilityReduceMotion) private var rm
    private let items = ["🦊","🍎","🚀","🐢","🍇","🪐"]
    private let colors: [Color] = [Brand.accent, Brand.danger, Brand.primary,
                                   Brand.accent, Brand.danger, Brand.primary]
    @State private var mixed = false
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, s in
                Text(s).font(.system(size: 36)).frame(width: 56, height: 62)
                    .background(colors[i].opacity(0.28), in: RoundedRectangle(cornerRadius: 10))
                    .offset(y: mixed ? (i % 2 == 0 ? -6 : 6) : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if rm { mixed = true; return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.6).repeatCount(3, autoreverses: true)) { mixed = true }
        }
    }
}

// MARK: - Elaboration (fact → because)

private struct ElaborationDemo: View {
    @Environment(\.accessibilityReduceMotion) private var rm
    @State private var show = false
    var body: some View {
        HStack(spacing: 10) {
            Text("🦉").font(.system(size: 62)).frame(width: 94, height: 94).demoCard(14)
            VStack(alignment: .leading, spacing: 5) {
                Text("?").font(.title2.bold()).foregroundStyle(Brand.accentText)
                    .opacity(show ? 0 : 1)
                HStack(spacing: 5) {
                    Image(systemName: "arrow.turn.down.right").font(.caption).foregroundStyle(Brand.text.opacity(0.5))
                    Text("because…").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                }
                .opacity(show ? 1 : 0).offset(x: show ? 0 : -10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if rm { show = true; return }
            withAnimation(.easeInOut(duration: 0.5).delay(0.9)) { show = true }
        }
    }
}

// MARK: - Story (items link into a chain)

private struct StoryDemo: View {
    @Environment(\.accessibilityReduceMotion) private var rm
    @State private var link = false
    var body: some View {
        HStack(spacing: 6) {
            Text("🐢").font(.system(size: 52)).frame(width: 78, height: 78).demoCard(12)
            Image(systemName: "arrow.right").foregroundStyle(Brand.accentText).opacity(link ? 1 : 0)
            Text("🍎").font(.system(size: 52)).frame(width: 78, height: 78).demoCard(12)
            Image(systemName: "arrow.right").foregroundStyle(Brand.accentText).opacity(link ? 1 : 0)
            Text("🚀").font(.system(size: 52)).frame(width: 78, height: 78).demoCard(12)
                .opacity(link ? 1 : 0.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if rm { link = true; return }
            withAnimation(.easeInOut(duration: 0.6).delay(0.7)) { link = true }
        }
    }
}
