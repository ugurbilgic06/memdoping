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
    var size: CGFloat = 150

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(tint.brightness(0.5).opacity(0.35))
                .blur(radius: 6)
                .frame(width: size * 1.05, height: size * 1.05)

            SceneView(scene: Symbol3DTile.makeScene(symbol: symbol, tint: tint), options: [])
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Brand.edgeHighlight, lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 12, y: 7)
                .id(symbol)   // rebuild + re-pop when the prompt changes
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text(symbol))
    }

    // MARK: - Scene

    static func makeScene(symbol: String, tint: Color) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = cg(0.13, 0.10, 0.27)

        // The tile body.
        let box = SCNBox(width: 2.4, height: 2.4, length: 0.5, chamferRadius: 0.2)
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = cgColor(tint.brightness(1.15))
        mat.metalness.contents = 0.2
        mat.roughness.contents = 0.4
        box.materials = [mat]
        let tile = SCNNode(geometry: box)

        // The symbol, drawn to an image and mapped onto a plane on the face so
        // it turns with the tile.
        if let image = symbolImage(symbol) {
            let plane = SCNPlane(width: 1.7, height: 1.7)
            let pm = SCNMaterial()
            pm.diffuse.contents = image
            pm.isDoubleSided = true
            pm.lightingModel = .constant
            plane.materials = [pm]
            let planeNode = SCNNode(geometry: plane)
            planeNode.position = SCNVector3(0, 0, 0.26)
            tile.addChildNode(planeNode)
        }

        // Pop in, then a gentle, readable sway (never turning fully away).
        tile.scale = SCNVector3(0.02, 0.02, 0.02)
        let pop = SCNAction.scale(to: 1, duration: 0.4)
        pop.timingMode = .easeOut
        tile.runAction(pop)

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
        key.light?.intensity = 1000
        key.light?.color = cg(1.0, 0.97, 0.92)
        key.eulerAngles = SCNVector3(-0.6, -0.5, 0)
        scene.rootNode.addChildNode(key)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 350
        ambient.light?.color = cg(0.6, 0.6, 0.85)
        scene.rootNode.addChildNode(ambient)

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
            let font = UIFont.systemFont(ofSize: side * 0.66)
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
