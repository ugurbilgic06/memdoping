//
//  MechanicDemo.swift
//  MemDoping
//
//  A short, animated "show, don't tell" micro-tutorial for a level's mechanic —
//  it plays once on the intro screen instead of a wall of text (V2 Faz 1 §1.3).
//  A single sentence sits under it; the long explanation lives in a collapsible
//  "How it works" section. Still and instant under Reduce Motion.
//

import SwiftUI

struct MechanicDemo: View {
    let mechanic: LevelMechanic
    var tint: Color
    /// One short caption shown under the animation (a content string).
    var caption: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var runID = 0

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.text.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Brand.edgeHighlight, lineWidth: 1))

            stage
                .id(runID)   // rebuilding restarts the animation
                .padding(.bottom, 30)

            // Caption strip.
            Text(caption.localizedContent)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.text)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Brand.text.opacity(0.06))

            // Replay.
            if !reduceMotion {
                Button {
                    runID += 1
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption.weight(.bold))
                        .padding(7)
                        .background(.white.opacity(0.8), in: Circle())
                        .foregroundStyle(Brand.text)
                }
                .buttonStyle(.plain)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(height: 172)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel(Text(caption.localizedContent))
    }

    @ViewBuilder
    private var stage: some View {
        switch mechanic {
        case .chunking:   ChunkingDemo(tint: tint, reduceMotion: reduceMotion)
        case .numberShape: ChunkingDemo(tint: tint, reduceMotion: reduceMotion)
        default:          GenericDemo(tint: tint, reduceMotion: reduceMotion)
        }
    }
}

// MARK: - Chunking: a long number splits into small groups

private struct ChunkingDemo: View {
    var tint: Color
    var reduceMotion: Bool
    private let digits = ["4", "9", "7", "1", "6", "2"]
    @State private var split = false
    @State private var glow = false

    var body: some View {
        HStack(spacing: split ? 16 : 4) {
            group(Array(digits[0..<3]))
            group(Array(digits[3..<6]))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: run)
    }

    private func group(_ ds: [String]) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(ds.enumerated()), id: \.offset) { _, d in
                Text(d)
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Brand.text)
                    .frame(width: 34, height: 44)
                    .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 9))
            }
        }
        .padding(6)
        .background((glow ? tint.opacity(0.35) : .clear),
                    in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13)
            .strokeBorder(glow ? Brand.accentText.opacity(0.6) : .clear, lineWidth: 2))
    }

    private func run() {
        guard !reduceMotion else { split = true; glow = true; return }
        split = false; glow = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) { split = true }
        withAnimation(.easeInOut(duration: 0.5).delay(1.2)) { glow = true }
    }
}

// MARK: - Default: a few tiles pop in, then a check — generic "study → recall"

private struct GenericDemo: View {
    var tint: Color
    var reduceMotion: Bool
    private let symbols = ["🍎", "🚀", "🌿"]
    @State private var shown = false
    @State private var check = false

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { i, s in
                Text(s)
                    .font(.system(size: 34))
                    .frame(width: 56, height: 56)
                    .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Brand.edgeHighlight, lineWidth: 1))
                    .scaleEffect(shown ? 1 : 0.3)
                    .opacity(shown ? 1 : 0)
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)
                        .delay(Double(i) * 0.18), value: shown)
                    .overlay(alignment: .topTrailing) {
                        if check && i == 1 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Brand.successText)
                                .background(Circle().fill(.white))
                                .offset(x: 6, y: -6)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard !reduceMotion else { shown = true; check = true; return }
            shown = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(1.0)) { check = true }
        }
    }
}
