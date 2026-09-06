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
        .animation(.easeInOut, value: store.hasOnboarded)
    }
}

#Preview {
    ContentView()
        .environment(GameStore())
}
