//
//  OnboardingView.swift
//  MemDoping
//
//  First-run welcome. Three short pages that set up the core loop
//  (Play → Learn → Remember → Level Up, §1) and the honest expectations from §9
//  before the player reaches the hub. Kept skippable and calm.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(GameStore.self) private var store
    @State private var page = 0

    private let lastPage = 3

    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if page < lastPage {
                        Button("Skip") { store.completeOnboarding() }
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                .frame(height: 44)

                TabView(selection: $page) {
                    welcomePage.tag(0)
                    loopPage.tag(1)
                    honestPage.tag(2)
                    agePage.tag(3)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif

                pageDots

                // The age page's own buttons are the call to action.
                if page < lastPage {
                    PrimaryButton(title: "Next", systemImage: "arrow.right") {
                        withAnimation { page += 1 }
                    }
                    .padding()
                } else {
                    Color.clear.frame(height: 1).padding()
                }
            }
        }
    }

    // MARK: Pages

    private var welcomePage: some View {
        pageLayout(
            art: { brandArt },
            title: "MemDoping",
            subtitle: "Hafıza Dopingi",
            body: "Science-based memory techniques, turned into short, playful games. Don't add games to learning — make learning the game."
        )
    }

    private var loopPage: some View {
        pageLayout(
            art: { loopArt },
            title: "How it works",
            subtitle: "Play · Learn · Remember · Level Up",
            body: "Each mission is a few minutes: pick it up, learn through play, recall what stuck, and level up. Stop any time — your progress is saved."
        )
    }

    private var honestPage: some View {
        pageLayout(
            art: { honestArt },
            title: "It's a skill, not a talent",
            subtitle: "What to expect",
            body: "Regular use may support memory, focus, and recall. Results vary by person; there's no 100% guarantee. These are learnable strategies — anyone can pick them up."
        )
    }

    private var agePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("👥")
                .font(.system(size: 72))
            VStack(spacing: 8) {
                Text("Who's playing?")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("We'll set a comfortable starting difficulty — you can change it any time in your profile.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            VStack(spacing: 12) {
                ageChoice(.child, "Child", "🧒", "Gentle pace, more time")
                ageChoice(.teen, "Teen", "🧑", "Balanced")
                ageChoice(.adult, "Adult", "🧑‍💼", "A little more challenge")
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func ageChoice(_ band: GameStore.AgeBand, _ title: LocalizedStringKey,
                           _ emoji: String, _ subtitle: LocalizedStringKey) -> some View {
        Button {
            store.setAgeBand(band)
            store.completeOnboarding()
        } label: {
            GameTile(base: Brand.primary, cornerRadius: 16) {
                HStack(spacing: 14) {
                    Text(emoji).font(.largeTitle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.headline).foregroundStyle(.white)
                        Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.6))
                }
                .padding()
            }
        }
        .buttonStyle(TileButtonStyle())
    }

    // MARK: Art

    private var brandArt: some View {
        Hero3DView(size: 200)
    }

    private var loopArt: some View {
        let steps: [(String, LocalizedStringKey)] = [
            ("play.fill", "Play"),
            ("book.fill", "Learn"),
            ("brain.head.profile", "Remember"),
            ("arrow.up.circle.fill", "Level Up")
        ]
        return VStack(spacing: 14) {
            ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                HStack(spacing: 14) {
                    Image(systemName: step.0)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Brand.gloss(Brand.accent), in: Circle())
                        .overlay(Circle().strokeBorder(Brand.edgeHighlight, lineWidth: 1))
                        .shadow(color: Brand.accent.opacity(0.4), radius: 6, y: 3)
                    Text(step.1)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                }
                if i < steps.count - 1 {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 14)
                }
            }
        }
        .padding(.horizontal, 40)
    }

    private var honestArt: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Brand.success.opacity(0.55), .clear],
                                     center: .center, startRadius: 6, endRadius: 130))
                .frame(width: 200, height: 200)
            Image(systemName: "building.columns.fill")
                .font(.system(size: 72))
                .foregroundStyle(Brand.gloss(Brand.success))
                .shadow(color: Brand.success.opacity(0.5), radius: 16)
        }
    }

    // MARK: Layout helpers

    private func pageLayout<Art: View>(
        @ViewBuilder art: () -> Art,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        body: LocalizedStringKey
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()
            art()
            VStack(spacing: 8) {
                Text(subtitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Brand.accent)
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            Text(body)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0...lastPage, id: \.self) { i in
                Circle()
                    .fill(i == page ? Brand.accent : Color.white.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    OnboardingView().environment(GameStore())
}
