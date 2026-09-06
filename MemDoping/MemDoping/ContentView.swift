//
//  ContentView.swift
//  MemDoping
//
//  Root view. Hosts the home hub; the shared GameStore is injected from the app.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environment(GameStore())
}
