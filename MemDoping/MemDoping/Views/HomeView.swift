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
    @State private var activeWorld: LadderWorld?
    @State private var showAudience = false
    @Environment(\.goToStart) private var goToStart

    private func bandLabel(_ band: GameStore.AgeBand) -> LocalizedStringKey {
        switch band {
        case .child: "Child"
        case .teen:  "Teen"
        case .adult: "Adult"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground()
                // The entry is the worlds, nothing else: the age band is chosen
                // before this screen, so each world explains itself for that
                // audience. Stats and the resume card live in the profile.
                ScrollView {
                    VStack(spacing: 20) {
                        header.dealIn(0)
                        statsRow.dealIn(1)
                        reviewBanner.dealIn(2)
                        levelLadder.dealIn(3)
                        nightCard.dealIn(4)
                    }
                    .padding()
                }
            }
            .confirmationDialog("Who's playing?", isPresented: $showAudience, titleVisibility: .visible) {
                ForEach(GameStore.AgeBand.allCases, id: \.self) { band in
                    Button(bandLabel(band)) { store.setAgeBand(band) }
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
            .navigationDestination(item: $activeWorld) { world in
                WorldLevelsView(world: world) { level in
                    activeWorld = nil
                    activeLevel = level
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                // Tapping the cube opens the audience picker — a quick way to
                // switch Child / Teen / Adult.
                Button {
                    if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                    showAudience = true
                } label: {
                    Hero3DView(size: 58, interactive: false)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change audience")
                VStack(alignment: .leading, spacing: 2) {
                    Text("MemDoping")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Brand.text)
                    Text("Memory Doping · Play, Learn, Remember")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text.opacity(0.7))
                }
                Spacer()
                // Same corner as everywhere else: back to the opening screen.
                Button { goToStart() } label: {
                    Image(systemName: "house.fill")
                        .font(.title3)
                        .foregroundStyle(Brand.text)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Back to home"))
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

    // MARK: Spaced review

    /// Only appears when something is actually due, so the entry stays clean —
    /// but the spaced-repetition loop keeps a way in. Stats moved to the
    /// profile, which already shows all of them.
    @ViewBuilder
    private var reviewBanner: some View {
        let due = store.dueReviewCount
        if due > 0 {
            Button { showReview = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundStyle(Brand.accentText)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Ready to recall")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.text)
                        Text("\(due) things you learned are waiting.")
                            .font(.caption)
                            .foregroundStyle(Brand.text.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Brand.text.opacity(0.45))
                }
                .padding(12)
                .background(Color.white.opacity(0.6),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Level ladder

    /// Five story worlds over the 100-level ladder. Opening the app shows these
    /// five, not a wall of a hundred levels — you pick a world and its twenty
    /// levels live inside it. Everyone can play all of them; the age band still
    /// only shifts tone and difficulty.
    private var levelLadder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Worlds")
                .font(.title3.bold())
                .foregroundStyle(Brand.text)

            ForEach(LadderWorld.all) { world in
                worldRow(world)
                    .id("\(world.id)-\(store.ageBand?.rawValue ?? "none")")
            }
        }
    }

    private func worldRow(_ world: LadderWorld) -> some View {
        let levels = SampleLevels.all.filter { world.range.contains($0.index) }
        let unlocked = levels.filter { $0.index <= store.highestUnlockedLevel }.count
        let locked = world.range.lowerBound > store.highestUnlockedLevel

        let progress = levels.isEmpty ? 0 : Double(unlocked) / Double(levels.count)

        return Button {
            if !locked { activeWorld = world }
        } label: {
            HStack(spacing: 14) {
                // The world's emblem on its own colour — a place, not a row.
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Brand.gloss(locked ? Brand.text.opacity(0.10) : world.tint))
                        .frame(width: 58, height: 58)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
                        .shadow(color: locked ? .clear : world.tint.opacity(0.45), radius: 6, y: 3)
                    Text(world.emoji).font(.system(size: 30))
                        .opacity(locked ? 0.45 : 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(world.title)
                            .font(.headline)
                            .foregroundStyle(locked ? Brand.text.opacity(0.5) : Brand.text)
                        Spacer(minLength: 0)
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.footnote)
                                .foregroundStyle(Brand.text.opacity(0.4))
                        } else {
                            Text("\(unlocked)/\(levels.count)")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(unlocked == levels.count ? Brand.successText : Brand.accentText)
                        }
                    }
                    // What this world trains, in the chosen audience's terms —
                    // shown for locked worlds too, so you can see what you're
                    // working towards, not just that it's shut.
                    Text(world.blurb(for: store.ageBand))
                        .font(.caption)
                        .foregroundStyle(Brand.text.opacity(locked ? 0.55 : 0.75))
                        .fixedSize(horizontal: false, vertical: true)
                    if locked {
                        Text("Opens at level \(world.range.lowerBound)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.text.opacity(0.5))
                    }

                    // How far through this world you are.
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Brand.text.opacity(0.10))
                            Capsule().fill(world.tint)
                                .frame(width: max(0, geo.size.width * progress))
                        }
                    }
                    .frame(height: 5)
                    .opacity(locked ? 0.35 : 1)
                    .padding(.top, 2)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.62),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Brand.edgeHighlight, lineWidth: 1))
            .shadow(color: .black.opacity(locked ? 0 : 0.06), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .accessibilityElement(children: .combine)
    }

    func levelRow(_ level: GameLevel) -> some View {
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

    private var nightBlurb: LocalizedStringKey {
        switch store.ageBand {
        case .child:      "A sleepy round before bed — soft, slow, no score."
        case .adult:      "Wind down after the day: quiet recall, no timer, no score."
        case .teen, .none: "A calm, untimed wind-down — no score, no rush."
        }
    }

    private var nightCard: some View {
        Button { showNight = true } label: {
            Card {
                HStack(spacing: 14) {
                    Text("🌙").font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Night Doping")
                            .font(.headline).foregroundStyle(Brand.text)
                        // Worded for whoever is playing, like the worlds above.
                        Text(nightBlurb)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
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
