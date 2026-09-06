//
//  Symbol3DTile.swift
//  MemDoping
//
//  The recall prompt as a real 3D object: the symbol textured onto the face of
//  a glossy SceneKit tile that pops in and gently sways. One SceneView per
//  screen (the prompt is the star of each question), so it stays performant.
//  Tinted by the level's evolving tile motif.
//

import SwiftUI
import SceneKit

struct Symbol3DTile: View {
    let symbol: String
    var tint: Color
    var size: CGFloat = 168
    /// When true, the tile emits a 3D spark burst (e.g. on a correct answer).
    var celebrate: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(tint.brightness(0.5).opacity(0.35))
                .blur(radius: 6)
                .frame(width: size * 1.05, height: size * 1.05)

            SceneView(scene: Symbol3DTile.makeScene(symbol: symbol, tint: tint, burst: celebrate),
                      options: [])
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Brand.edgeHighlight, lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 12, y: 7)
                .id("\(symbol)-\(celebrate)")   // rebuild on prompt change or celebration
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text(symbol))
    }

    // MARK: - Scene

    static func makeScene(symbol: String, tint: Color, burst: Bool = false) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = cg(0.93, 0.96, 0.99)

        // Image-based lighting so the glossy tile has something to reflect.
        let env = environmentImage()
        if let env {
            scene.lightingEnvironment.contents = env
            scene.lightingEnvironment.intensity = 1.3
        }

        // The tile body — glossy, lightly reflective, with a fresnel edge sheen.
        let box = SCNBox(width: 2.4, height: 2.4, length: 0.5, chamferRadius: 0.2)
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = cgColor(tint.brightness(1.15))
        mat.metalness.contents = 0.5
        mat.roughness.contents = 0.28
        if let env {
            mat.reflective.contents = env
            mat.reflective.intensity = 0.45
        }
        mat.fresnelExponent = 1.6
        box.materials = [mat]
        let tile = SCNNode(geometry: box)

        // The symbol, drawn to an image and mapped onto a plane on the face so
        // it turns with the tile.
        if let image = symbolImage(symbol) {
            let plane = SCNPlane(width: 2.05, height: 2.05)
            let pm = SCNMaterial()
            pm.diffuse.contents = image
            pm.isDoubleSided = true
            pm.lightingModel = .constant
            plane.materials = [pm]
            let planeNode = SCNNode(geometry: plane)
            planeNode.position = SCNVector3(0, 0, 0.26)
            tile.addChildNode(planeNode)
        }

        // On a fresh prompt, pop in; on a celebration rebuild, stay put so the
        // tile doesn't re-pop while sparks fly.
        if burst {
            tile.scale = SCNVector3(1, 1, 1)
        } else {
            tile.scale = SCNVector3(0.02, 0.02, 0.02)
            let pop = SCNAction.scale(to: 1, duration: 0.4)
            pop.timingMode = .easeOut
            tile.runAction(pop)
        }

        let swayRight = SCNAction.rotateBy(x: 0.12, y: 0.5, z: 0, duration: 2.2)
        let swayLeft = SCNAction.rotateBy(x: -0.12, y: -0.5, z: 0, duration: 2.2)
        swayRight.timingMode = .easeInEaseOut
        swayLeft.timingMode = .easeInEaseOut
        tile.runAction(.repeatForever(.sequence([swayRight, swayLeft])))
        scene.rootNode.addChildNode(tile)

        // Camera + lighting.
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 4.1)
        scene.rootNode.addChildNode(camera)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1100
        key.light?.color = cg(1.0, 0.97, 0.92)
        key.eulerAngles = SCNVector3(-0.6, -0.5, 0)
        scene.rootNode.addChildNode(key)

        // Coloured rim light for a lively, glassy edge (Vita-Mahjong style).
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .omni
        rim.light?.intensity = 650
        rim.light?.color = cgColor(tint.brightness(1.6))
        rim.position = SCNVector3(-3.5, 2.5, -2)
        scene.rootNode.addChildNode(rim)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 320
        ambient.light?.color = cg(0.6, 0.6, 0.85)
        scene.rootNode.addChildNode(ambient)

        // A 3D spark burst on a correct answer.
        if burst {
            let sparks = SCNParticleSystem()
            sparks.loops = false
            sparks.birthRate = 220
            sparks.emissionDuration = 0.12
            sparks.particleLifeSpan = 0.9
            sparks.particleLifeSpanVariation = 0.4
            sparks.particleVelocity = 3.6
            sparks.particleVelocityVariation = 2.2
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
            emitter.position = SCNVector3(0, 0, 0.3)
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
            let font = UIFont.systemFont(ofSize: side * 0.78)
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
    /// glossy tile a believable window-like reflection without an HDR asset.
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
