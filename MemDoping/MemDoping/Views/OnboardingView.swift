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

    private let lastPage = 2

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
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif

                pageDots

                PrimaryButton(
                    title: page == lastPage ? "Start playing" : "Next",
                    systemImage: page == lastPage ? "play.fill" : "arrow.right"
                ) {
                    if page == lastPage {
                        store.completeOnboarding()
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .padding()
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

    // MARK: Art

    private var brandArt: some View {
        ZStack {
            Circle().fill(Brand.primary.opacity(0.35)).frame(width: 150, height: 150)
            Image(systemName: "brain.head.profile")
                .font(.system(size: 72))
                .foregroundStyle(Brand.accent)
        }
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
                        .foregroundStyle(Brand.accent)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.08), in: Circle())
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
            Circle().fill(Brand.success.opacity(0.25)).frame(width: 150, height: 150)
            Image(systemName: "building.columns.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white)
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
