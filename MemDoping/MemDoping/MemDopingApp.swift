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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.light)
                .onAppear { if store.musicEnabled { MusicPlayer.shared.start() } }
                .onChange(of: scenePhase) { _, phase in
                    // Stop the music when the app leaves the screen, resume it on
                    // return — so it never keeps playing on the home screen.
                    switch phase {
                    case .active:     if store.musicEnabled { MusicPlayer.shared.start() }
                    case .background: MusicPlayer.shared.stop()
                    default:          break
                    }
                }
        }
    }
}
