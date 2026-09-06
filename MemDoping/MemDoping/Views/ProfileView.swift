//
//  ProfileView.swift
//  MemDoping
//
//  Progress overview, comfort settings (§4), and the required evidence
//  boundary disclaimer (§9).
//

import SwiftUI

struct ProfileView: View {
    @Environment(GameStore.self) private var store
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            BrandBackground()
            ScrollView {
                VStack(spacing: 20) {
                    scoreCard
                    settingsCard
                    privacyCard
                    aboutCard
                    resetButton
                }
                .padding()
            }
        }
        .navigationTitle("Your Progress")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
    }

    private var scoreCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Memory Score")
                    .font(.headline).foregroundStyle(.white)

                if let score = store.memoryScore {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(score)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        trendLabel
                    }
                } else {
                    Text("Not enough data yet")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Complete at least \(GameStore.minSessionsForScore) missions to see a score.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Divider().overlay(.white.opacity(0.2))

                HStack {
                    stat("MemDoping XP", "\(store.xp)")
                    stat("Retention", store.retentionScore.map { "\($0)" } ?? "—")
                    stat("Levels", "\(store.highestUnlockedLevel)/\(store.totalLevels)")
                }
                HStack {
                    stat("Missions", "\(store.recentResults.count)")
                    stat("Reviews", "\(store.retentionHistory.count)")
                    stat("Difficulty", difficultyText)
                }

                Text("Retention tracks delayed recall in spaced reviews. Both are in-game indicators from recent tasks — not an IQ or clinical score.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var trendLabel: some View {
        let (text, icon, color): (LocalizedStringKey, String, Color) = switch store.memoryScoreTrend {
        case .up:      ("Rising", "arrow.up.right", Brand.success)
        case .down:    ("Dipping", "arrow.down.right", Brand.danger)
        case .steady:  ("Steady", "arrow.right", .white.opacity(0.7))
        }
        return Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
    }

    private func stat(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).foregroundStyle(.white)
            Text(title).font(.caption2).foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func bandLabel(_ band: GameStore.AgeBand) -> LocalizedStringKey {
        switch band {
        case .child: "Child"
        case .teen:  "Teen"
        case .adult: "Adult"
        }
    }

    private var difficultyText: String {
        switch store.difficultyState {
        case .eased:    String(localized: "Eased")
        case .standard: String(localized: "Standard")
        case .ramped:   String(localized: "Ramped")
        }
    }

    private var settingsCard: some View {
        @Bindable var store = store
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Comfort")
                    .font(.headline).foregroundStyle(.white)
                Toggle("Music", isOn: $store.musicEnabled)
                Toggle("Sound", isOn: $store.soundEnabled)
                Toggle("Haptics", isOn: $store.hapticsEnabled)

                Divider().overlay(.white.opacity(0.15))
                Text("Audience").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                HStack(spacing: 8) {
                    ForEach(GameStore.AgeBand.allCases, id: \.self) { band in
                        Button { store.setAgeBand(band) } label: {
                            Text(bandLabel(band))
                                .font(.caption.weight(.medium))
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(store.ageBand == band ? Brand.accent : .white.opacity(0.08),
                                            in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Reduced motion follows your system accessibility setting.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .tint(Brand.accent)
            .foregroundStyle(.white)
        }
    }

    private var privacyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Label("Privacy", systemImage: "lock.shield.fill")
                    .font(.headline).foregroundStyle(.white)
                Text("Your progress is stored on this device only. MemDoping doesn't collect, track, or send your personal data, and there are no accounts or ads.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var aboutCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("About")
                    .font(.headline).foregroundStyle(.white)
                Text("MemDoping turns science-based memory techniques into short, playful missions. This build is an early prototype using clearly-labeled sample content.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Divider().overlay(.white.opacity(0.2))
                Text("Regular use may support memory performance, focus, and recall. Results vary by person; there is no 100% improvement guarantee.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            showResetConfirm = true
        } label: {
            Text("Reset progress")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Brand.danger)
        }
        .buttonStyle(.plain)
        .confirmationDialog("Reset all progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) { store.resetProgress() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your XP, Memory Score, and unlocked levels. It cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
        .environment(GameStore())
        .preferredColorScheme(.dark)
}
