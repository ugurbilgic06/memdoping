//
//  Symbol3DTile.swift
//  MemDoping
//
//  The recall prompt as a real 3D object: a glossy, tinted cube that floats and
//  spins on a transparent background (no white plate) — the emoji "character"
//  rides its four side faces, so one always turns to face you. Filling the frame
//  makes the character read large. Tinted by the level's evolving motif.
//

import SwiftUI
import SceneKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct Symbol3DTile: View {
    let symbol: String
    var tint: Color
    var size: CGFloat = 168
    /// When true, the tile emits a 3D spark burst (e.g. on a correct answer).
    var celebrate: Bool = false
    /// Seconds for one full spin — larger is calmer (Night Doping uses a slow one).
    var spinDuration: Double = 13

    var body: some View {
        TransparentSceneView(scene: Symbol3DTile.makeScene(symbol: symbol, tint: tint,
                                                           burst: celebrate, spinDuration: spinDuration))
            .frame(width: size, height: size)
            .id("\(symbol)-\(celebrate)")   // rebuild on prompt change or celebration
            .shadow(color: tint.opacity(0.45), radius: 12, y: 8)
            .accessibilityLabel(Text(symbol))
    }

    // MARK: - Scene

    static func makeScene(symbol: String, tint: Color, burst: Bool = false,
                          spinDuration: Double = 13) -> SCNScene {
        let scene = SCNScene()
        // No background — the view is transparent, so the app's own backdrop
        // shows through instead of a white box.
        scene.background.contents = nil

        let env = environmentImage()
        if let env {
            scene.lightingEnvironment.contents = env
            scene.lightingEnvironment.intensity = 1.2
        }

        // The character cube — big, glossy, tinted. Fills the frame.
        let box = SCNBox(width: 2.6, height: 2.6, length: 2.6, chamferRadius: 0.45)
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = cgColor(tint.brightness(1.12))
        mat.metalness.contents = 0.2
        mat.roughness.contents = 0.15
        if let env {
            mat.reflective.contents = env
            mat.reflective.intensity = 0.62
        }
        mat.fresnelExponent = 1.5
        // A glossy clear-coat gives it a glassy, candy-like sheen.
        mat.clearCoat.contents = 0.7
        mat.clearCoatRoughness.contents = 0.08
        box.materials = [mat]

        let cube = SCNNode(geometry: box)
        cube.name = "cube"
        cube.eulerAngles = SCNVector3(0.12, 0.5, 0)   // slight tilt for depth

        // The emoji on each of the four side faces, so a character always faces
        // the camera and turns with the cube.
        if let image = symbolImage(symbol) {
            let d: Float = 1.315
            let faces: [(SCNVector3, SCNVector3)] = [
                (SCNVector3(0, 0, d),  SCNVector3(0, 0, 0)),           // front
                (SCNVector3(0, 0, -d), SCNVector3(0, 3.14159, 0)),     // back
                (SCNVector3(d, 0, 0),  SCNVector3(0, 1.5708, 0)),      // right
                (SCNVector3(-d, 0, 0), SCNVector3(0, -1.5708, 0))      // left
            ]
            for (pos, rot) in faces {
                let plane = SCNPlane(width: 2.0, height: 2.0)
                let pm = SCNMaterial()
                pm.diffuse.contents = image
                pm.lightingModel = .constant
                pm.isDoubleSided = false
                pm.blendMode = .alpha
                plane.materials = [pm]
                let node = SCNNode(geometry: plane)
                node.position = pos
                node.eulerAngles = rot
                cube.addChildNode(node)
            }
        }

        // Pop in on a fresh prompt (skip while sparks fly so it doesn't re-pop).
        if !burst {
            cube.scale = SCNVector3(0.02, 0.02, 0.02)
            let pop = SCNAction.scale(to: 1, duration: 0.42)
            pop.timingMode = .easeOut
            cube.runAction(pop)
        }
        // Endless calm spin so the character turns without being dizzying…
        cube.runAction(.repeatForever(.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: spinDuration)),
                       forKey: "spin")
        // …and a gentle float up and down, like a living character.
        let up = SCNAction.moveBy(x: 0, y: 0.11, z: 0, duration: 1.7)
        up.timingMode = .easeInEaseOut
        cube.runAction(.repeatForever(.sequence([up, up.reversed()])))
        scene.rootNode.addChildNode(cube)

        // Camera — close enough that the cube fills the frame.
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 3.75)   // closer, so the cube is big and fills the frame
        scene.rootNode.addChildNode(camera)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1050
        key.light?.color = cg(1.0, 0.97, 0.92)
        key.eulerAngles = SCNVector3(-0.6, -0.5, 0)
        scene.rootNode.addChildNode(key)

        // Coloured rim light for a lively, glassy edge (Vita-Mahjong style).
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .omni
        rim.light?.intensity = 700
        rim.light?.color = cgColor(tint.brightness(1.6))
        rim.position = SCNVector3(-3.5, 2.5, -2)
        scene.rootNode.addChildNode(rim)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 450
        ambient.light?.color = cg(0.72, 0.78, 0.9)
        scene.rootNode.addChildNode(ambient)

        // A 3D spark burst on a correct answer.
        if burst {
            let sparks = SCNParticleSystem()
            sparks.loops = false
            sparks.birthRate = 240
            sparks.emissionDuration = 0.12
            sparks.particleLifeSpan = 0.9
            sparks.particleLifeSpanVariation = 0.4
            sparks.particleVelocity = 3.8
            sparks.particleVelocityVariation = 2.4
            sparks.spreadingAngle = 180
            sparks.particleSize = 0.05
            sparks.particleSizeVariation = 0.03
            sparks.acceleration = SCNVector3(0, -5, 0)
            sparks.blendMode = .additive
            sparks.isAffectedByGravity = false
            #if canImport(UIKit)
            sparks.particleColor = UIColor(cgColor: cgColor(tint.brightness(1.7)))
            #elseif canImport(AppKit)
            sparks.particleColor = NSColor(cgColor: cgColor(tint.brightness(1.7))) ?? .white
            #endif
            let emitter = SCNNode()
            emitter.position = SCNVector3(0, 0, 0)
            emitter.addParticleSystem(sparks)
            scene.rootNode.addChildNode(emitter)
        }

        return scene
    }

    // MARK: - Helpers

    /// Renders an emoji/symbol string to a transparent image for texturing.
    private static func symbolImage(_ symbol: String) -> Any? {
        #if canImport(UIKit)
        let side: CGFloat = 256
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { _ in
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let font = UIFont.systemFont(ofSize: side * 0.8)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: paragraph]
            let str = symbol as NSString
            let bounds = str.boundingRect(with: CGSize(width: side, height: side),
                                          options: .usesLineFragmentOrigin,
                                          attributes: attrs, context: nil)
            str.draw(at: CGPoint(x: (side - bounds.width) / 2,
                                 y: (side - bounds.height) / 2), withAttributes: attrs)
        }
        #else
        return nil
        #endif
    }

    /// A cheap gradient environment map — bright top to dark bottom gives the
    /// glossy cube a believable window-like reflection without an HDR asset.
    private static func environmentImage() -> Any? {
        #if canImport(UIKit)
        let size = CGSize(width: 256, height: 256)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor(white: 0.98, alpha: 1).cgColor,
                          UIColor(red: 0.35, green: 0.34, blue: 0.55, alpha: 1).cgColor,
                          UIColor(white: 0.05, alpha: 1).cgColor]
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray, locations: [0, 0.55, 1])!
            ctx.cgContext.drawLinearGradient(
                grad, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
        #else
        return nil
        #endif
    }

    private static func cg(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
        CGColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    private static func cgColor(_ c: Color) -> CGColor {
        #if canImport(UIKit)
        return UIColor(c).cgColor
        #else
        return CGColor(srgbRed: 0.3, green: 0.25, blue: 0.6, alpha: 1)
        #endif
    }
}

/// A SceneKit view with a transparent background, so 3D content floats directly
/// on the app's backdrop (SwiftUI's `SceneView` is always opaque).
private struct TransparentSceneView {
    let scene: SCNScene
}

#if canImport(UIKit)
extension TransparentSceneView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.backgroundColor = .clear
        v.isOpaque = false
        v.antialiasingMode = .multisampling4X
        v.rendersContinuously = true
        v.scene = scene
        // Drag to spin the cube yourself — a plain rotation, no camera zoom.
        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        v.addGestureRecognizer(pan)
        context.coordinator.view = v
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        if v.scene !== scene {
            v.scene = scene
            context.coordinator.view = v
        }
    }

    final class Coordinator: NSObject {
        weak var view: SCNView?

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let cube = view?.scene?.rootNode.childNode(withName: "cube", recursively: false)
            else { return }
            let t = g.translation(in: view)
            switch g.state {
            case .began:
                cube.removeAction(forKey: "spin")           // stop auto-spin while held
            case .changed:
                let k: Float = 0.01
                cube.eulerAngles.y += Float(t.x) * k
                cube.eulerAngles.x += Float(t.y) * k
                g.setTranslation(.zero, in: view)
            case .ended, .cancelled:
                cube.runAction(.repeatForever(
                    .rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 13)), forKey: "spin")
            default:
                break
            }
        }
    }
}
#elseif canImport(AppKit)
extension TransparentSceneView: NSViewRepresentable {
    func makeNSView(context: Context) -> SCNView {
        let v = SCNView()
        v.backgroundColor = .clear
        v.antialiasingMode = .multisampling4X
        v.rendersContinuously = true
        v.scene = scene
        return v
    }
    func updateNSView(_ v: SCNView, context: Context) {
        if v.scene !== scene { v.scene = scene }
    }
}
#endif
