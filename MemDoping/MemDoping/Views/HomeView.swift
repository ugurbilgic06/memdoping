//
//  HomeView.swift
//  MemDoping
//
//  The hub. Surfaces the core loop entry point, progression stats, the daily
//  mission, and the level ladder. "Memory Training, Turned Into a Game."
//

import SwiftUI

struct HomeView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeLevel: GameLevel?
    @State private var showReview = false
    @State private var showNight = false
    @State private var expandedChapters: Set<Int> = []

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        header.dealIn(0)
                        statsRow.dealIn(1)
                        dailyMissionCard.dealIn(2)
                        reviewCard.dealIn(3)
                        continueCard.dealIn(4)
                        levelLadder.dealIn(5)
                        nightCard.dealIn(6)
                        disclaimer.dealIn(7)
                    }
                    .padding()
                }
            }
            .navigationDestination(item: $activeLevel) { level in
                // Apply adaptive difficulty (§7) at launch, preserving identity.
                let l = store.adapted(level)
                Group {
                    switch l.mechanic {
                    case .pairRecall: MissionView(level: l)
                    case .chunking:   ChunkingMissionView(level: l)
                    case .retrieval:  RetrievalMissionView(level: l)
                    case .loci:       LociMissionView(level: l)
                    case .scene:      SceneMissionView(level: l)
                    case .interleaving: InterleavingMissionView(level: l)
                    case .elaboration: ElaborationMissionView(level: l)
                    case .story:      StoryMissionView(level: l)
                    case .numberShape: NumberShapeMissionView(level: l)
                    }
                }
                .doorReveal()   // "doors opening" reveal on entering a level
            }
            .navigationDestination(isPresented: $showReview) {
                ReviewMissionView(items: store.dueReviews)
            }
            .navigationDestination(isPresented: $showNight) {
                NightDopingView()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Hero3DView(size: 58, interactive: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MemDoping")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Brand.text)
                    Text("Memory Doping · Play, Learn, Remember")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text.opacity(0.7))
                }
                Spacer()
                NavigationLink { ProfileView() } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.title)
                        .foregroundStyle(Brand.text)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatChip(title: "MemDoping XP", value: "\(store.xp)",
                     systemImage: "bolt.fill", tint: Brand.accent)
            StatChip(title: "Memory Score",
                     value: store.memoryScore.map { "\($0)" } ?? "—",
                     systemImage: "brain.head.profile")
            StatChip(title: "Level",
                     value: "\(store.highestUnlockedLevel)/\(store.totalLevels)",
                     systemImage: "flag.checkered")
        }
    }

    // MARK: Daily mission

    private var dailyMissionCard: some View {
        Button {
            if store.dueReviewCount > 0 { showReview = true }
            else { activeLevel = store.currentLevel }
        } label: {
            Card {
                HStack(spacing: 14) {
                    Image(systemName: store.isDailyMissionDone ? "checkmark.seal.fill" : "sun.max.fill")
                        .font(.title)
                        .foregroundStyle(store.isDailyMissionDone ? Brand.successText : Brand.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily mission")
                            .font(.headline).foregroundStyle(Brand.text)
                        dailySubtitle
                            .font(.subheadline)
                            .foregroundStyle(Brand.text.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Brand.text.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var dailySubtitle: some View {
        if store.isDailyMissionDone {
            Text("Done for today — one more if you like.")
        } else if store.dueReviewCount > 0 {
            Text("Today: refresh \(store.dueReviewCount) due items")
        } else {
            Text("Today: Level \(store.currentLevel.index) · \(store.currentLevel.title.localizedContent)")
        }
    }

    // MARK: Spaced review (T05 — quiet, opt-in, no streak pressure)

    @ViewBuilder
    private var reviewCard: some View {
        if store.dueReviewCount > 0 {
            Button {
                showReview = true
            } label: {
                Card {
                    HStack(spacing: 14) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title)
                            .foregroundStyle(Brand.accentText)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(store.dueReviewCount) items due for review")
                                .font(.headline).foregroundStyle(Brand.text)
                            Text("You learned these earlier — let's see if they stuck.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text.opacity(0.75))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Brand.text.opacity(0.5))
                    }
                }
            }
            .buttonStyle(.plain)
        } else if let next = store.nextReviewDate {
            Card {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Brand.successText)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All caught up on reviews")
                            .font(.headline).foregroundStyle(Brand.text)
                        Text("Next review \(next.formatted(.relative(presentation: .named))).")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text.opacity(0.75))
                    }
                    Spacer()
                }
            }
        }
    }

    private var difficultyLabel: LocalizedStringKey {
        switch store.difficultyState {
        case .eased:    "Eased to your pace"
        case .standard: "Adapts to you"
        case .ramped:   "Ramped up"
        }
    }

    // MARK: Continue (core loop entry)

    private var continueCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ProgressRing(progress: store.ringProgress)
                        .frame(width: 54, height: 54)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.7), value: store.ringProgress)
                        .overlay(
                            Text("\(store.ringLevel)")
                                .font(.headline).foregroundStyle(Brand.text)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Continue your training")
                            .font(.headline).foregroundStyle(Brand.text)
                        Text("Level \(store.currentLevel.index): \(store.currentLevel.title.localizedContent)")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text.opacity(0.75))
                        Label(difficultyLabel, systemImage: "slider.horizontal.3")
                            .font(.caption2)
                            .foregroundStyle(Brand.accentText)
                    }
                    Spacer()
                }
                PrimaryButton(title: "Play", systemImage: "play.fill") {
                    activeLevel = store.currentLevel
                }
            }
        }
    }

    // MARK: Level ladder

    /// Ten themed chapters of ten levels each, so the ladder reads as chapters
    /// with headings + emoji instead of one long list.
    private struct Chapter {
        let title: LocalizedStringKey
        let emoji: String
        let range: ClosedRange<Int>
    }

    private let chapters: [Chapter] = [
        .init(title: "Warm-up",      emoji: "🌱", range: 1...10),
        .init(title: "Explorer",     emoji: "🧭", range: 11...20),
        .init(title: "Focus",        emoji: "🎯", range: 21...30),
        .init(title: "Momentum",     emoji: "🚀", range: 31...40),
        .init(title: "Sharp",        emoji: "⚡️", range: 41...50),
        .init(title: "Deep Dive",    emoji: "🌊", range: 51...60),
        .init(title: "Master Steps", emoji: "🧠", range: 61...70),
        .init(title: "Challenge",    emoji: "🔥", range: 71...80),
        .init(title: "Expert",       emoji: "💎", range: 81...90),
        .init(title: "Legend",       emoji: "👑", range: 91...100)
    ]

    private var levelLadder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Levels")
                .font(.title3.bold())
                .foregroundStyle(Brand.text)
            ForEach(Array(chapters.enumerated()), id: \.offset) { i, chapter in
                chapterSection(i, chapter)
            }
        }
        .onAppear {
            // Open the chapter that holds the current level by default.
            if expandedChapters.isEmpty,
               let i = chapters.firstIndex(where: { $0.range.contains(store.currentLevel.index) }) {
                expandedChapters.insert(i)
            }
        }
    }

    @ViewBuilder
    private func chapterSection(_ index: Int, _ chapter: Chapter) -> some View {
        let levels = SampleLevels.all.filter { chapter.range.contains($0.index) }
        let unlocked = levels.filter { $0.index <= store.highestUnlockedLevel }.count
        let chapterLocked = chapter.range.lowerBound > store.highestUnlockedLevel
        let isOpen = expandedChapters.contains(index)

        VStack(spacing: 8) {
            Button {
                if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                withAnimation(.easeInOut(duration: 0.22)) {
                    if isOpen { expandedChapters.remove(index) } else { expandedChapters.insert(index) }
                }
            } label: {
                HStack(spacing: 12) {
                    Text(chapter.emoji).font(.title)
                        .opacity(chapterLocked ? 0.5 : 1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(chapter.title)
                            .font(.headline)
                            .foregroundStyle(chapterLocked ? Brand.text.opacity(0.5) : Brand.text)
                        Text(verbatim: "\(chapter.range.lowerBound)–\(chapter.range.upperBound)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Brand.text.opacity(0.55))
                    }
                    Spacer()
                    if chapterLocked {
                        Image(systemName: "lock.fill").foregroundStyle(Brand.text.opacity(0.4))
                    } else {
                        Text("\(unlocked)/\(levels.count)")
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(unlocked == levels.count ? Brand.successText : Brand.accentText)
                    }
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Brand.text.opacity(0.5))
                        .rotationEffect(.degrees(isOpen ? 0 : -90))
                }
                .padding(14)
                .background(Color.white.opacity(0.55),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
            }
            .buttonStyle(.plain)

            if isOpen {
                ForEach(levels) { level in
                    levelRow(level)
                }
                .padding(.leading, 6)
            }
        }
    }

    private func levelRow(_ level: GameLevel) -> some View {
        let unlocked = level.index <= store.highestUnlockedLevel
        let best = store.bestAccuracy[level.index]

        return Button {
            if unlocked { activeLevel = level }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(unlocked ? Brand.gloss(level.tileBase) : Brand.gloss(Brand.text.opacity(0.08)))
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(Brand.edgeHighlight, lineWidth: 1))
                        .shadow(color: unlocked ? level.tileBase.opacity(0.5) : .clear, radius: 5, y: 2)
                    Image(systemName: unlocked ? "\(level.index).circle.fill" : "lock.fill")
                        .foregroundStyle(Brand.text)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title.localizedContent)
                        .font(.headline)
                        .foregroundStyle(unlocked ? Brand.text : Brand.text.opacity(0.5))
                    Text(level.technique.localizedContent)
                        .font(.caption)
                        .foregroundStyle(Brand.text.opacity(0.6))
                }
                Spacer()
                if let best {
                    Text("\(Int(best * 100))%")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(best >= level.masteryPercent ? Brand.successText : Brand.text.opacity(0.7))
                } else if unlocked {
                    Image(systemName: "chevron.right").foregroundStyle(Brand.text.opacity(0.5))
                }
            }
            .padding(14)
            .background(Brand.text.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    // MARK: Night Doping (§4 — optional calm mode)

    private var nightCard: some View {
        Button { showNight = true } label: {
            Card {
                HStack(spacing: 14) {
                    Text("🌙").font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Night Doping")
                            .font(.headline).foregroundStyle(Brand.text)
                        Text("A calm, untimed wind-down — no score, no rush.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Brand.text.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Disclaimer (§9)

    private var disclaimer: some View {
        Text("Regular use may support memory performance, focus, and recall. Results vary by person; there is no 100% improvement guarantee.")
            .font(.caption2)
            .foregroundStyle(Brand.text.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}

#Preview {
    HomeView()
        .environment(GameStore())
        .preferredColorScheme(.light)
}
