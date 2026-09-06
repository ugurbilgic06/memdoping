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

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        statsRow
                        dailyMissionCard
                        reviewCard
                        continueCard
                        levelLadder
                        nightCard
                        disclaimer
                    }
                    .padding()
                }
            }
            .navigationDestination(item: $activeLevel) { level in
                // Apply adaptive difficulty (§7) at launch, preserving identity.
                let l = store.adapted(level)
                switch l.mechanic {
                case .pairRecall: MissionView(level: l)
                case .chunking:   ChunkingMissionView(level: l)
                case .retrieval:  RetrievalMissionView(level: l)
                case .loci:       LociMissionView(level: l)
                case .scene:      SceneMissionView(level: l)
                case .interleaving: InterleavingMissionView(level: l)
                case .elaboration: ElaborationMissionView(level: l)
                case .story:      StoryMissionView(level: l)
                }
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
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MemDoping")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Memory Doping · Play, Learn, Remember")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                NavigationLink { ProfileView() } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.title)
                        .foregroundStyle(.white)
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
        Card {
            HStack(spacing: 14) {
                Image(systemName: store.isDailyMissionDone ? "checkmark.seal.fill" : "sun.max.fill")
                    .font(.title)
                    .foregroundStyle(store.isDailyMissionDone ? Brand.success : Brand.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily mission")
                        .font(.headline).foregroundStyle(.white)
                    Text(store.isDailyMissionDone
                         ? "Done for today — nice work."
                         : "Today's memory doping takes just a few minutes.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
            }
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
                            .foregroundStyle(Brand.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(store.dueReviewCount) items due for review")
                                .font(.headline).foregroundStyle(.white)
                            Text("You learned these earlier — let's see if they stuck.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .buttonStyle(.plain)
        } else if let next = store.nextReviewDate {
            Card {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Brand.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All caught up on reviews")
                            .font(.headline).foregroundStyle(.white)
                        Text("Next review \(next.formatted(.relative(presentation: .named))).")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
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
                                .font(.headline).foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Continue your training")
                            .font(.headline).foregroundStyle(.white)
                        Text("Level \(store.currentLevel.index): \(store.currentLevel.title.localizedContent)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                        Label(difficultyLabel, systemImage: "slider.horizontal.3")
                            .font(.caption2)
                            .foregroundStyle(Brand.accent)
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

    private var levelLadder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Levels")
                .font(.title3.bold())
                .foregroundStyle(.white)
            ForEach(SampleLevels.all) { level in
                levelRow(level)
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
                        .fill(unlocked ? Brand.primary : Color.white.opacity(0.08))
                        .frame(width: 40, height: 40)
                    Image(systemName: unlocked ? "\(level.index).circle.fill" : "lock.fill")
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title.localizedContent)
                        .font(.headline)
                        .foregroundStyle(unlocked ? .white : .white.opacity(0.5))
                    Text(level.technique.localizedContent)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if let best {
                    Text("\(Int(best * 100))%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(best >= level.masteryPercent ? Brand.success : .white.opacity(0.7))
                } else if unlocked {
                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(14)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
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
                            .font(.headline).foregroundStyle(.white)
                        Text("A calm, untimed wind-down — no score, no rush.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Disclaimer (§9)

    private var disclaimer: some View {
        Text("Regular use may support memory performance, focus, and recall. Results vary by person; there is no 100% improvement guarantee.")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}
