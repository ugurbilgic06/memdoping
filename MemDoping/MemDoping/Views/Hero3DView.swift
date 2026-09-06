//
//  Hero3DView.swift
//  MemDoping
//
//  First step of the real-3D art direction: an actual SceneKit object embedded
//  in the SwiftUI UI (not a flat image). A glossy, physically-lit rounded cube
//  that slowly turns — a reusable 3D "hero" for onboarding, the home header,
//  and celebration moments. SceneView is cross-platform (iOS/macOS).
//

import SwiftUI
import SceneKit

struct Hero3DView: View {
    var size: CGFloat = 190
    /// Let the player orbit the object by dragging.
    var interactive: Bool = true

    var body: some View {
        ZStack {
            // Halo behind the pod.
            Circle()
                .fill(RadialGradient(
                    colors: [Brand.primary.opacity(0.65), .clear],
                    center: .center, startRadius: 6, endRadius: size * 0.85))
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 6)

            SceneView(
                scene: Hero3DView.makeScene(),
                options: interactive ? [.allowsCameraControl] : []
            )
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Brand.edgeHighlight, lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    // MARK: - Scene

    static func makeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = cg(0.16, 0.13, 0.34)   // lit pod, reads with brand bg

        // Glossy rounded cube.
        let box = SCNBox(width: 2.2, height: 2.2, length: 2.2, chamferRadius: 0.5)
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = cg(0.98, 0.53, 0.24)        // MemDoping accent
        mat.metalness.contents = 0.35
        mat.roughness.contents = 0.25
        box.materials = [mat]

        let cube = SCNNode(geometry: box)
        cube.eulerAngles = SCNVector3(0.5, 0.6, 0)
        cube.runAction(.repeatForever(
            .rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 10)))
        scene.rootNode.addChildNode(cube)

        // Camera.
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 6)
        scene.rootNode.addChildNode(camera)

        // Key + rim + ambient lighting for a lively, glossy read.
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1000
        key.light?.color = cg(1.0, 0.95, 0.9)
        key.eulerAngles = SCNVector3(-0.7, -0.5, 0)
        scene.rootNode.addChildNode(key)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .omni
        rim.light?.intensity = 500
        rim.light?.color = cg(0.45, 0.4, 0.95)             // indigo rim
        rim.position = SCNVector3(-4, 2, -3)
        scene.rootNode.addChildNode(rim)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 320
        ambient.light?.color = cg(0.55, 0.55, 0.85)
        scene.rootNode.addChildNode(ambient)

        return scene
    }

    /// Platform-independent CGColor helper (avoids UIColor/NSColor per-platform).
    private static func cg(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
        CGColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}

#Preview {
    ZStack {
        BrandBackground()
        Hero3DView()
    }
}
