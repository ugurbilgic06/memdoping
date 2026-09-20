//
//  MemDopingApp.swift
//  MemDoping
//
//  Created by Ubilgic on 5.09.2026.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct MemDopingApp: App {
    @State private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase

    init() { Self.styleNavigationBar() }

    /// Navigation bar titles are drawn by UIKit, so SwiftUI's `.fontDesign` and
    /// foreground colour don't reach them — match them to the app's rounded
    /// typeface and indigo ink here.
    private static func styleNavigationBar() {
        #if canImport(UIKit)
        let ink = UIColor(Brand.text)
        func rounded(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let d = base.fontDescriptor.withDesign(.rounded) else { return base }
            return UIFont(descriptor: d, size: size)
        }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: ink, .font: rounded(17, .semibold)]
        appearance.largeTitleTextAttributes = [.foregroundColor: ink, .font: rounded(34, .bold)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = ink
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.light)
                .onAppear { if store.musicEnabled { MusicPlayer.shared.start(for: store.ageBand) } }
                .onChange(of: scenePhase) { _, phase in
                    // Stop the music when the app leaves the screen, resume it on
                    // return — so it never keeps playing on the home screen.
                    switch phase {
                    case .active:     if store.musicEnabled { MusicPlayer.shared.start(for: store.ageBand) }
                    case .background: MusicPlayer.shared.stop()
                    default:          break
                    }
                }
        }
    }
}
