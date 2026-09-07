//
//  ContentView.swift
//  MemDoping
//
//  Root view. Hosts the home hub; the shared GameStore is injected from the app.
//

import SwiftUI

struct ContentView: View {
    @Environment(GameStore.self) private var store
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if store.hasOnboarded {
                    HomeView()
                } else {
                    OnboardingView()
                }
            }
            .environment(\.cartoonLevel, cartoonLevel)
            .environment(\.locale, AppLocale.locale)
            .id(store.languageCode ?? "system")   // rebuild content on language change
            .animation(.easeInOut, value: store.hasOnboarded)

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
