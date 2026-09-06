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
#if canImport(UIKit)
import UIKit
#endif

struct Hero3DView: View {
    var size: CGFloat = 190
    /// Let the player orbit the object by dragging.
    var interactive: Bool = true

    var body: some View {
        ZStack {
            // Halo behind the pod — bright and cheerful.
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.20, green: 0.85, blue: 0.95).opacity(0.7), .clear],
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
        scene.background.contents = cg(0.90, 0.95, 0.99)   // light, airy pod

        // Bright, glassy rounded cube — a happy colour, see-through so the brain
        // inside shows.
        let box = SCNBox(width: 2.2, height: 2.2, length: 2.2, chamferRadius: 0.5)
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = cg(0.16, 0.82, 0.90)        // vivid turquoise
        mat.metalness.contents = 0.15
        mat.roughness.contents = 0.18
        box.materials = [mat]

        let cube = SCNNode(geometry: box)
        cube.eulerAngles = SCNVector3(0.3, 0.6, 0)
        cube.runAction(.repeatForever(
            .rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 10)))

        // A brain on each of the four side faces, so one always faces the camera
        // and turns with the cube.
        if let brain = brainImage() {
            let faces: [(SCNVector3, SCNVector3)] = [
                (SCNVector3(0, 0, 1.12),  SCNVector3(0, 0, 0)),          // front
                (SCNVector3(0, 0, -1.12), SCNVector3(0, 3.14159, 0)),    // back
                (SCNVector3(1.12, 0, 0),  SCNVector3(0, 1.5708, 0)),     // right
                (SCNVector3(-1.12, 0, 0), SCNVector3(0, -1.5708, 0))     // left
            ]
            for (pos, rot) in faces {
                let plane = SCNPlane(width: 1.5, height: 1.5)
                let pm = SCNMaterial()
                pm.diffuse.contents = brain
                pm.lightingModel = .constant
                pm.blendMode = .alpha
                plane.materials = [pm]
                let node = SCNNode(geometry: plane)
                node.position = pos
                node.eulerAngles = rot
                cube.addChildNode(node)
            }
        }
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
        rim.light?.intensity = 650
        rim.light?.color = cg(0.35, 0.95, 1.0)             // bright cyan rim
        rim.position = SCNVector3(-4, 2, -3)
        scene.rootNode.addChildNode(rim)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 420
        ambient.light?.color = cg(0.75, 0.85, 1.0)
        scene.rootNode.addChildNode(ambient)

        return scene
    }

    /// Renders the brain emoji to an image for the inner faces.
    private static func brainImage() -> Any? {
        #if canImport(UIKit)
        let side: CGFloat = 256
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            let p = NSMutableParagraphStyle(); p.alignment = .center
            let f = UIFont.systemFont(ofSize: side * 0.66)
            let attrs: [NSAttributedString.Key: Any] = [.font: f, .paragraphStyle: p]
            let str = "🧠" as NSString
            let b = str.boundingRect(with: CGSize(width: side, height: side),
                                     options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            str.draw(at: CGPoint(x: (side - b.width) / 2, y: (side - b.height) / 2), withAttributes: attrs)
        }
        #else
        return nil
        #endif
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
