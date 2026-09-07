//
//  SplashView.swift
//  MemDoping
//
//  An impressive first-launch intro: a "gate of intelligence" (zeka kapısı) with
//  a glowing brain opens like double doors to reveal the ".Pixselsius" wordmark,
//  then hands off to the app. Shown before the onboarding/home on every launch.
//

import SwiftUI

struct SplashView: View {
    var onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var doorsOpen = false
    @State private var brainScale: CGFloat = 0.35
    @State private var glow = false
    @State private var wordmarkIn = false
    @State private var fadeOut = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backdrop

                // Revealed behind the gate: the glowing brain + wordmark.
                VStack(spacing: 20) {
                    Text("🧠")
                        .font(.system(size: 116))
                        .scaleEffect(brainScale)
                        .shadow(color: Brand.accent.opacity(glow ? 0.95 : 0.35),
                                radius: glow ? 34 : 12)
                    VStack(spacing: 4) {
                        Text(".Pixselsius")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Brand.accent.opacity(0.6), radius: 10)
                        Text("presents")
                            .font(.footnote.weight(.semibold))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .opacity(wordmarkIn ? 1 : 0)
                    .offset(y: wordmarkIn ? 0 : 14)
                }

                // The gate — two doors that cover everything, then slide apart.
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
            LinearGradient(colors: [Color(red: 0.05, green: 0.08, blue: 0.11),
                                    Color(red: 0.09, green: 0.15, blue: 0.17)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Brand.accent.opacity(0.28), .clear],
                           center: .center, startRadius: 0, endRadius: 360)
                .scaleEffect(glow ? 1.1 : 0.9)
        }
        .ignoresSafeArea()
    }

    private func door(seamOnRight: Bool) -> some View {
        LinearGradient(colors: [Color(red: 0.10, green: 0.16, blue: 0.19),
                                Color(red: 0.05, green: 0.09, blue: 0.11)],
                       startPoint: .top, endPoint: .bottom)
        // Glowing seam edge.
        .overlay(alignment: seamOnRight ? .trailing : .leading) {
            Rectangle()
                .fill(LinearGradient(
                    colors: seamOnRight ? [.clear, Brand.accent] : [Brand.accent, .clear],
                    startPoint: .leading, endPoint: .trailing))
                .frame(width: 12)
                .shadow(color: Brand.accent.opacity(0.8), radius: 10)
        }
        // A brain crest on the gate near the seam.
        .overlay(alignment: seamOnRight ? .trailing : .leading) {
            Text("🧠").font(.system(size: 44))
                .offset(x: seamOnRight ? 26 : -26)
                .opacity(0.9)
        }
    }

    // MARK: Sequence

    private func run() {
        guard !reduceMotion else {
            brainScale = 1; wordmarkIn = true; doorsOpen = true; glow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { finish() }
            return
        }
        // Brain rises behind the closed gate.
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { brainScale = 1 }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glow = true }
        // Gate opens.
        withAnimation(.easeInOut(duration: 0.9).delay(0.6)) { doorsOpen = true }
        // Wordmark reveals as the gate parts.
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.1)) { wordmarkIn = true }
        // Hold, then fade out to the app.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            withAnimation(.easeOut(duration: 0.5)) { fadeOut = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { finish() }
        }
    }

    private func finish() { onDone() }
}

#Preview {
    SplashView(onDone: {})
}
