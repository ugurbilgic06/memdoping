//
//  ContentView.swift
//  MemDoping
//
//  Root view. Hosts the home hub; the shared GameStore is injected from the app.
//

import SwiftUI

/// Jumps all the way back to the opening screen (the audience gate), from any
/// depth. Passed down so a world or a mission can offer one "home" that means
/// the same thing everywhere: where the app starts.
private struct GoToStartKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var goToStart: () -> Void {
        get { self[GoToStartKey.self] }
        set { self[GoToStartKey.self] = newValue }
    }
}

struct ContentView: View {
    @Environment(GameStore.self) private var store
    @State private var showSplash = true
    /// Every launch opens on the audience screen — it carries the three groups'
    /// explanations — and this flips once the player picks one or continues.
    @State private var didEnter = false

    var body: some View {
        ZStack {
            Group {
                if !store.hasOnboarded {
                    OnboardingView()
                } else if !didEnter {
                    // Who's playing, every launch: the band sets tone and
                    // starting difficulty, and this screen is where the three
                    // groups explain themselves. Returning players can skip it.
                    AudienceGateView(
                        onPick: { _ in didEnter = true },
                        onContinue: store.ageBand == nil ? nil : { didEnter = true }
                    )
                } else {
                    HomeView()
                }
            }
            // A rounded typeface across the whole app — friendlier and more
            // game-like than the default, and it keeps Dynamic Type working
            // because it only changes the design, not the sizes.
            .fontDesign(.rounded)
            .environment(\.cartoonLevel, cartoonLevel)
            .environment(\.locale, AppLocale.locale)
            .environment(\.goToStart) { didEnter = false }
            .id(store.languageCode ?? "system")   // rebuild content on language change
            .animation(.easeInOut, value: store.hasOnboarded)
            .animation(.easeInOut, value: didEnter)

            // Impressive "gate of intelligence" intro before the first screen.
            if showSplash {
                SplashView(playSound: store.soundEnabled) { showSplash = false }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }

    /// Younger players get a more cartoonish symbol treatment.
    private var cartoonLevel: Double {
        switch store.ageBand {
        case .child:  return 1.0
        case .teen:   return 0.5
        case .adult:  return 0.2
        case .none:   return 0.6
        }
    }
}

#Preview {
    ContentView()
        .environment(GameStore())
}
