//
//  ContentView.swift
//  MemDoping
//
//  Root view. Hosts the home hub; the shared GameStore is injected from the app.
//

import SwiftUI

struct ContentView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        Group {
            if store.hasOnboarded {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .environment(\.cartoonLevel, cartoonLevel)
        .animation(.easeInOut, value: store.hasOnboarded)
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
