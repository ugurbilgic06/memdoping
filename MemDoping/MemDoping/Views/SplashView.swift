//
//  SplashView.swift
//  MemDoping
//
//  An impressive first-launch intro: a motif-covered gate opens like double
//  doors — with a grand rising sound — to reveal the ".Pixselsius" wordmark,
//  then hands off to the app. Shown before onboarding/home on every launch.
//

import SwiftUI

struct SplashView: View {
    var playSound: Bool = true
    var onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var doorsOpen = false
    @State private var emblemScale: CGFloat = 0.4
    @State private var glow = false
    @State private var wordmarkIn = false
    @State private var fadeOut = false

    /// Temple ornament motifs — like entering a serene temple gate.
    private let doorGlyphs = ["🪷","☸️","🏮","🕉️","🛕","✦","❁","🔶"]
    private let gold = Color(red: 1.0, green: 0.82, blue: 0.36)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backdrop

                // Revealed behind the gate: a glowing lotus + wordmark.
                VStack(spacing: 20) {
                    Text("🪷")
                        .font(.system(size: 104))
                        .scaleEffect(emblemScale)
                        .shadow(color: gold.opacity(glow ? 0.95 : 0.4),
                                radius: glow ? 34 : 12)
                    VStack(spacing: 4) {
                        Text(".Pixselsius")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: gold.opacity(0.7), radius: 10)
                        Text("presents")
                            .font(.footnote.weight(.semibold))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .opacity(wordmarkIn ? 1 : 0)
                    .offset(y: wordmarkIn ? 0 : 14)
                }

                // The gate — two motif-covered doors that slide apart.
                HStack(spacing: 0) {
                    door(seamOnRight: true)
                        .frame(width: geo.size.width / 2 + 1)
                        .offset(x: doorsOpen ? -(geo.size.width / 2 + 2) : 0)
                    door(seamOnRight: false)
                        .frame(width: geo.size.width / 2 + 1)
                        .offset(x: doorsOpen ? (geo.size.width / 2 + 2) : 0)
                }
                .ignoresSafeArea()
            }
            .opacity(fadeOut ? 0 : 1)
            .onAppear { run() }
        }
    }

    // MARK: Pieces

    private var backdrop: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.12, green: 0.04, blue: 0.05),   // deep temple maroon
                                    Color(red: 0.06, green: 0.03, blue: 0.05)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [gold.opacity(0.30), .clear],
                           center: .center, startRadius: 0, endRadius: 360)
                .scaleEffect(glow ? 1.1 : 0.9)
        }
        .ignoresSafeArea()
    }

    /// One temple gate door — deep lacquered wood with gilded ornament and a
    /// glowing golden seam, like the entrance to a temple.
    private func door(seamOnRight: Bool) -> some View {
        LinearGradient(colors: [Color(red: 0.28, green: 0.09, blue: 0.09),   // lacquer red
                                Color(red: 0.14, green: 0.05, blue: 0.06)],
                       startPoint: .top, endPoint: .bottom)
            .overlay { doorMotifs }
            // A gilded stud border down the inner seam.
            .overlay(alignment: seamOnRight ? .trailing : .leading) {
                VStack(spacing: 22) {
                    ForEach(0..<16, id: \.self) { _ in
                        Circle().fill(gold.opacity(0.8))
                            .frame(width: 7, height: 7)
                            .shadow(color: gold.opacity(0.6), radius: 2)
                    }
                }
                .padding(seamOnRight ? .trailing : .leading, 12)
            }
            // Glowing golden seam edge.
            .overlay(alignment: seamOnRight ? .trailing : .leading) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: seamOnRight ? [.clear, gold] : [gold, .clear],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: 10)
                    .shadow(color: gold.opacity(0.85), radius: 10)
            }
    }

    /// A gilded pattern of temple ornaments (lotus, dharma wheel, lanterns) so
    /// the gate reads as a serene temple entrance.
    private var doorMotifs: some View {
        GeometryReader { g in
            let cols = 3
            let rows = 13
            VStack(spacing: max(10, g.size.height / CGFloat(rows) - 24)) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: max(10, g.size.width / CGFloat(cols) - 22)) {
                        ForEach(0..<cols, id: \.self) { c in
                            Text(doorGlyphs[(r * cols + c) % doorGlyphs.count])
                                .font(.system(size: 22))
                                .foregroundStyle(gold.opacity(0.22))
                                .opacity(0.5)
                        }
                    }
                }
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .allowsHitTesting(false)
    }

    // MARK: Sequence

    private func run() {
        if playSound { SoundPlayer.shared.playIntro() }

        guard !reduceMotion else {
            emblemScale = 1; wordmarkIn = true; doorsOpen = true; glow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { onDone() }
            return
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { emblemScale = 1 }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glow = true }
        withAnimation(.easeInOut(duration: 0.9).delay(0.6)) { doorsOpen = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.1)) { wordmarkIn = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeOut(duration: 0.5)) { fadeOut = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDone() }
        }
    }
}

#Preview {
    SplashView(onDone: {})
}
