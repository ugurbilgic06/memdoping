//
//  V2WorldsView.swift
//  MemDoping
//
//  The V2 entry: three age worlds, each with three scenes, shown with the story
//  arc, the six-phase flow and the animated micro-tutorial. Every scene plays one
//  of the app's existing mechanics, taking its content from the ladder level named
//  in `sourceLevel`. Separate from the 100-level ladder — nothing there is touched.
//

import SwiftUI

struct V2WorldsView: View {
    @Environment(GameStore.self) private var store
    @State private var worldIndex = 0
    @State private var route: Route?
    @State private var activeLevel: GameLevel?

    private struct Route: Hashable { let w: Int; let s: Int }
    private var world: V2World { V2Content.worlds[worldIndex] }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                worldTabs
                Text(world.hint)
                    .font(.subheadline).foregroundStyle(Brand.text.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(Array(world.scenes.enumerated()), id: \.element.id) { i, scene in
                    Button { route = Route(w: worldIndex, s: i) } label: { sceneCard(i, scene) }
                        .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(BrandBackground().ignoresSafeArea())
        .navigationTitle("V2 Worlds")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $route) { r in sceneDetail(r) }
        .navigationDestination(item: $activeLevel) { level in missionView(level) }
    }

    // MARK: World tabs

    private var worldTabs: some View {
        HStack(spacing: 8) {
            ForEach(Array(V2Content.worlds.enumerated()), id: \.element.id) { i, w in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { worldIndex = i }
                    if store.hapticsEnabled { HapticsPlayer.shared.tap() }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.label).font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10).padding(.horizontal, 12)
                    .background(LinearGradient(colors: w.sky, startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.5),
                             lineWidth: i == worldIndex ? 2 : 0))
                    .scaleEffect(i == worldIndex ? 1.0 : 0.94)
                    .shadow(color: .black.opacity(i == worldIndex ? 0.22 : 0), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Scene card

    private func sceneCard(_ i: Int, _ scene: V2Scene) -> some View {
        HStack(spacing: 14) {
            Text(scene.obj).font(.system(size: 34))
                .frame(width: 54, height: 54)
                .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(i + 1). \(scene.title)").font(.headline).foregroundStyle(Brand.text)
                Text(scene.tech).font(.caption).foregroundStyle(Brand.accentText)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Brand.text.opacity(0.4))
        }
        .padding(14)
        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Brand.edgeHighlight, lineWidth: 1))
    }

    // MARK: Scene detail

    @ViewBuilder
    private func sceneDetail(_ r: Route) -> some View {
        let w = V2Content.worlds[r.w]
        let scene = w.scenes[r.s]
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Story arc line.
                HStack(alignment: .top, spacing: 8) {
                    Text("📖")
                    Text(w.arc[r.s]).font(.subheadline).foregroundStyle(Brand.text)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: w.sky.map { $0.opacity(0.25) },
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 14))

                // Six-phase flow.
                phaseBar

                // Animated micro-tutorial (reuses per-mechanic animation).
                MechanicDemo(mechanic: scene.mechanic, tint: Brand.accent,
                             caption: SampleLevels.level(at: scene.sourceLevel)?.tip ?? "")

                // Hook line.
                Label {
                    Text(scene.hook).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                } icon: {
                    Image(systemName: "bolt.fill").foregroundStyle(Brand.accentText)
                }

                Spacer(minLength: 8)

                PrimaryButton(title: "Play", systemImage: "play.fill") {
                    // Each scene names the ladder level that supplies its content,
                    // so the world stays a presentation layer over existing levels.
                    if let level = SampleLevels.level(at: scene.sourceLevel) {
                        store.setAgeBand(w.band)
                        activeLevel = store.adapted(level)
                    }
                }
            }
            .padding()
        }
        .background(BrandBackground().ignoresSafeArea())
        .navigationTitle(scene.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var phaseBar: some View {
        HStack(spacing: 4) {
            ForEach(Array(V2Phase.allCases.enumerated()), id: \.offset) { i, p in
                Text(p.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Brand.text.opacity(0.7))
                    .padding(.vertical, 5).frame(maxWidth: .infinity)
                    .background(Brand.text.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
                if i < V2Phase.allCases.count - 1 {
                    Image(systemName: "chevron.right").font(.system(size: 7)).foregroundStyle(Brand.text.opacity(0.35))
                }
            }
        }
    }

    // MARK: Launch an existing mechanic (reuses the 12 mechanics)

    @ViewBuilder
    private func missionView(_ l: GameLevel) -> some View {
        Group {
            switch l.mechanic {
            case .pairRecall:   MissionView(level: l)
            case .chunking:     ChunkingMissionView(level: l)
            case .retrieval:    RetrievalMissionView(level: l)
            case .loci:         LociMissionView(level: l)
            case .scene:        SceneMissionView(level: l)
            case .interleaving: InterleavingMissionView(level: l)
            case .elaboration:  ElaborationMissionView(level: l)
            case .story:        StoryMissionView(level: l)
            case .numberShape:  NumberShapeMissionView(level: l)
            }
        }
        .doorReveal()
    }
}

#Preview {
    NavigationStack { V2WorldsView() }
        .environment(GameStore())
}
