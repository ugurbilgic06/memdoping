//
//  Celebration3DView.swift
//  MemDoping
//
//  A real 3D reward for clearing a level: a glossy gold trophy that pops in and
//  slowly spins, shown on the mission summary. Same SceneKit pipeline as
//  Hero3DView. Verified in the simulator (SceneKit doesn't render in static
//  preview snapshots).
//

import SwiftUI
import SceneKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct Celebration3DView: View {
    var size: CGFloat = 140
    var spins: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Brand.accent.opacity(0.55), .clear],
                    center: .center, startRadius: 6, endRadius: size * 0.85))
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 8)

            SceneView(scene: Celebration3DView.makeScene(spins: spins), options: [])
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Brand.edgeHighlight, lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    static func makeScene(spins: Bool) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = cg(0.16, 0.13, 0.34)

        let gold = SCNMaterial()
        gold.lightingModel = .physicallyBased
        gold.diffuse.contents = cg(1.0, 0.80, 0.28)
        gold.metalness.contents = 1.0
        gold.roughness.contents = 0.22

        // Trophy = cup (cone) + stem + base, grouped.
        let trophy = SCNNode()

        let cup = SCNCone(topRadius: 0.95, bottomRadius: 0.5, height: 1.0)
        cup.materials = [gold]
        let cupNode = SCNNode(geometry: cup)
        cupNode.position = SCNVector3(0, 0.55, 0)
        trophy.addChildNode(cupNode)

        let stem = SCNCylinder(radius: 0.13, height: 0.35)
        stem.materials = [gold]
        let stemNode = SCNNode(geometry: stem)
        stemNode.position = SCNVector3(0, -0.02, 0)
        trophy.addChildNode(stemNode)

        let base = SCNCylinder(radius: 0.5, height: 0.16)
        base.materials = [gold]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, -0.3, 0)
        trophy.addChildNode(baseNode)

        trophy.position = SCNVector3(0, -0.2, 0)
        // Pop in, then spin.
        trophy.scale = SCNVector3(0.01, 0.01, 0.01)
        let pop = SCNAction.scale(to: 1.0, duration: 0.45)
        pop.timingMode = .easeOut
        trophy.runAction(pop)
        if spins {
            trophy.runAction(.repeatForever(.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 7)))
        }
        scene.rootNode.addChildNode(trophy)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0.1, 5.2)
        scene.rootNode.addChildNode(camera)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1100
        key.light?.color = cg(1.0, 0.97, 0.9)
        key.eulerAngles = SCNVector3(-0.6, -0.5, 0)
        scene.rootNode.addChildNode(key)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .omni
        rim.light?.intensity = 600
        rim.light?.color = cg(0.5, 0.45, 1.0)
        rim.position = SCNVector3(-4, 3, -3)
        scene.rootNode.addChildNode(rim)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 320
        ambient.light?.color = cg(0.6, 0.6, 0.8)
        scene.rootNode.addChildNode(ambient)

        // Real 3D confetti: a one-shot particle burst around the trophy.
        let confetti = SCNParticleSystem()
        confetti.loops = false
        confetti.birthRate = 260
        confetti.emissionDuration = 0.18
        confetti.particleLifeSpan = 1.5
        confetti.particleLifeSpanVariation = 0.6
        confetti.particleVelocity = 4.2
        confetti.particleVelocityVariation = 2.6
        confetti.spreadingAngle = 90
        confetti.emittingDirection = SCNVector3(0, 1, 0)
        confetti.acceleration = SCNVector3(0, -7, 0)
        confetti.particleSize = 0.07
        confetti.particleSizeVariation = 0.04
        #if canImport(UIKit)
        confetti.particleColor = UIColor(red: 1.0, green: 0.82, blue: 0.30, alpha: 1)
        #elseif canImport(AppKit)
        confetti.particleColor = NSColor(srgbRed: 1.0, green: 0.82, blue: 0.30, alpha: 1)
        #endif
        confetti.particleColorVariation = SCNVector4(0.12, 0.12, 0.12, 0)
        confetti.blendMode = .additive
        confetti.isAffectedByGravity = false
        let emitter = SCNNode()
        emitter.position = SCNVector3(0, 0.4, 0)
        emitter.addParticleSystem(confetti)
        scene.rootNode.addChildNode(emitter)

        return scene
    }

    private static func cg(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
        CGColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
