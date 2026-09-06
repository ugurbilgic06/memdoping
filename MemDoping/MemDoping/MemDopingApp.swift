//
//  MemDopingApp.swift
//  MemDoping
//
//  Created by Ubilgic on 5.09.2026.
//

import SwiftUI

@main
struct MemDopingApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
                .onAppear { if store.musicEnabled { MusicPlayer.shared.start() } }
        }
    }
}
