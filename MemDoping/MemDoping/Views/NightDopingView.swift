//
//  NightDopingView.swift
//  MemDoping
//
//  The Relax & Unwind engine ("Gece Dopingi", §4): an optional calm mode —
//  low-intensity visuals, untimed play, a familiar easy activity, no score, no
//  competition, and an explicit, restful ending. It makes no sleep/stress/
//  hormone claims and never nudges the player to trade sleep for progress.
//

import SwiftUI

/// The calm palette used only by Night Doping.
enum NightPalette {
    static var background: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.03, green: 0.03, blue: 0.10),
                     Color(red: 0.07, green: 0.06, blue: 0.18)],
            startPoint: .top, endPoint: .bottom)
    }
    static let glow = Color(red: 0.62, green: 0.72, blue: 1.0)
    static let soft = Color(red: 0.80, green: 0.84, blue: 1.0)
}

struct NightDopingView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase { case intro, study, recall, close }

    @State private var phase: Phase = .intro
    @State private var pairs: [MemoryPair] = []
    @State private var questions: [MemoryPair] = []
    @State private var index = 0
    @State private var chosen: String? = nil
    @State private var options: [String] = []
    @State private var breathe = false

    var body: some View {
        ZStack {
            NightBackground()

            Group {
                switch phase {
                case .intro:  intro
                case .study:  study
                case .recall: recall
                case .close:  close
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(phase == .study || phase == .recall)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if phase == .study || phase == .recall {
                    Button("Rest now") { phase = .close }
                        .foregroundStyle(NightPalette.soft.opacity(0.8))
                }
            }
        }
        .onAppear {
            setup()
            if store.musicEnabled { MusicPlayer.shared.startNight() }   // sleepier loop
        }
        .onDisappear {
            if store.musicEnabled { MusicPlayer.shared.start(for: store.ageBand) }  // back to day loop
        }
        // This screen is intentionally dark; keep the app's forced light scheme
        // from turning nav/system elements dark-on-dark here.
        .preferredColorScheme(.dark)
    }

    // MARK: Setup

    /// Night Doping rotates through calm themes as its 20-level ladder.
    private var nightTheme: MemoryTheme {
        let themes = [SampleContent.nightCalm] + SampleContent.themePool
        return themes[(store.nightLevel - 1) % themes.count]
    }

    private func setup() {
        pairs = Array(nightTheme.pairs.shuffled().prefix(4))
        questions = pairs.shuffled()
        loadOptions()
        if !reduceMotion { withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { breathe = true } }
    }

    private func loadOptions() {
        guard questions.indices.contains(index) else { return }
        let correct = questions[index].word
        let others = nightTheme.pairs.map(\.word).filter { $0 != correct }.shuffled()
        options = (Array(others.prefix(2)) + [correct]).shuffled()
        chosen = nil
    }

    // MARK: Intro

    private var intro: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🌙")
                .font(.system(size: 92))
                .shadow(color: NightPalette.glow.opacity(0.6), radius: 24)
                .scaleEffect(breathe ? 1.06 : 0.98)
            Text("Night Doping")
                .font(.largeTitle.bold())
                .foregroundStyle(NightPalette.soft)
            Text(verbatim: "\(String(localized: "Night", bundle: AppLocale.bundle, locale: AppLocale.locale)) \(store.nightLevel) / \(GameStore.nightLevels)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(NightPalette.glow)
            Text("A few quiet minutes — no timer, no score. Just a gentle wind-down. When you're tired, stop; sleep matters more than any streak.")
                .font(.body)
                .foregroundStyle(NightPalette.soft.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            calmButton("Begin", systemImage: "moon.stars.fill") { phase = .study }
        }
    }

    // MARK: Study (untimed)

    private var study: some View {
        VStack(spacing: 18) {
            Text("Take your time")
                .font(.title3.weight(.semibold))
                .foregroundStyle(NightPalette.soft)
            Text("Rest your eyes on each one. There's no clock.")
                .font(.subheadline)
                .foregroundStyle(NightPalette.soft.opacity(0.7))

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(Array(pairs.enumerated()), id: \.element.id) { i, pair in
                        VStack(spacing: 10) {
                            SymbolBadge(symbol: pair.symbol, seed: i, size: 88)
                            Text(pair.word.localizedContent)
                                .font(.title3.weight(.semibold)).foregroundStyle(NightPalette.soft)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(NightPalette.glow.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text(pair.word.localizedContent))
                    }
                }
                .padding(.top, 4)
            }

            calmButton("I'm ready", systemImage: "sparkles") { phase = .recall }
        }
    }

    // MARK: Recall (gentle, unscored)

    private var recall: some View {
        VStack(spacing: 22) {
            Text("Which one was this?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(NightPalette.soft)

            if questions.indices.contains(index) {
                // A calm, slowly-turning 3D symbol you can nudge with a finger.
                Symbol3DTile(symbol: questions[index].symbol, tint: NightPalette.glow,
                             size: 150, spinDuration: 30)

                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        gentleOption(option)
                    }
                }

                Spacer()

                if chosen != nil {
                    calmButton(index + 1 < questions.count ? "Next" : "Finish",
                               systemImage: "arrow.right") {
                        if index + 1 < questions.count { index += 1; loadOptions() }
                        else { phase = .close }
                    }
                }
            }
        }
    }

    private func gentleOption(_ option: String) -> some View {
        let isCorrect = option == questions[index].word
        let revealed = chosen != nil
        // Kind reveal: highlight the right one softly; never flag "wrong" harshly.
        let fill = revealed && isCorrect ? NightPalette.glow.opacity(0.25)
            : NightPalette.glow.opacity(0.08)
        return Button {
            guard chosen == nil else { return }
            chosen = option
            if store.soundEnabled { SoundPlayer.shared.play(.correct) }
            if store.hapticsEnabled { HapticsPlayer.shared.tap() }
        } label: {
            HStack {
                Text(option.localizedContent).foregroundStyle(NightPalette.soft).fontWeight(.medium)
                Spacer()
                if revealed && isCorrect {
                    Image(systemName: "moon.fill").foregroundStyle(NightPalette.glow)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(fill, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(NightPalette.glow.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }

    // MARK: Close (explicit, restful ending)

    private var close: some View {
        VStack(spacing: 22) {
            Spacer()
            Text("🌙")
                .font(.system(size: 72))
                .shadow(color: NightPalette.glow.opacity(0.5), radius: 20)
                .scaleEffect(breathe ? 1.05 : 0.99)
            Text("That's a good place to stop")
                .font(.title.bold())
                .foregroundStyle(NightPalette.soft)
                .multilineTextAlignment(.center)
            Text("Well done winding down. Rest well — your progress will be right here tomorrow.")
                .font(.subheadline)
                .foregroundStyle(NightPalette.soft.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            calmButton("Good night", systemImage: "moon.zzz.fill") {
                store.advanceNight()
                dismiss()
            }
        }
    }

    // MARK: Calm button

    private func calmButton(_ title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            if store.soundEnabled { SoundPlayer.shared.play(.tap) }
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(NightPalette.glow.opacity(0.20),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(NightPalette.glow.opacity(0.35), lineWidth: 1))
            .foregroundStyle(NightPalette.soft)
        }
        .buttonStyle(.plain)
    }
}

/// A dim, star-flecked backdrop for Night Doping.
struct NightBackground: View {
    private let stars: [(CGPoint, CGFloat)] = (0..<28).map { _ in
        (CGPoint(x: .random(in: 0...1), y: .random(in: 0...1)), CGFloat.random(in: 1...2.5))
    }

    var body: some View {
        ZStack {
            NightPalette.background
            GeometryReader { geo in
                ForEach(Array(stars.enumerated()), id: \.offset) { _, star in
                    Circle()
                        .fill(NightPalette.soft.opacity(0.5))
                        .frame(width: star.1, height: star.1)
                        .position(x: star.0.x * geo.size.width, y: star.0.y * geo.size.height)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack { NightDopingView() }
        .environment(GameStore())
}
