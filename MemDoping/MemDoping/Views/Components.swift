//
//  Components.swift
//  MemDoping
//
//  Shared visual language and small reusable views. Restrained animation, clear
//  contrast, and non-color-only cues support the Sensory Motivation Engine (§4).
//

import SwiftUI

/// MemDoping brand palette.
enum Brand {
    static let primary = Color(red: 0.30, green: 0.62, blue: 1.0)    // calm blue
    static let accent  = Color(red: 0.36, green: 0.86, blue: 0.82)   // soft, calming aqua
    static let success = Color(red: 0.28, green: 0.84, blue: 0.60)   // soft green
    static let danger  = Color(red: 1.0,  green: 0.45, blue: 0.55)   // soft rose

    /// Dark ink used on light/aqua fills (e.g. the primary button).
    static let ink = Color(red: 0.04, green: 0.16, blue: 0.18)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.10, blue: 0.20),
                     Color(red: 0.08, green: 0.28, blue: 0.42)],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// A top-lit glossy fill for a solid colour — gives buttons and tiles a
    /// rounded, dimensional look (matches the app icon's style).
    static func gloss(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(1.0), color.opacity(0.78)],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// A subtle top-lit fill for translucent surfaces (cards, chips, tiles).
    static var surfaceGloss: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.14), .white.opacity(0.05)],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// A soft top highlight stroke for the lit edge of a rounded surface.
    static var edgeHighlight: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.35), .white.opacity(0.05)],
            startPoint: .top, endPoint: .bottom
        )
    }
}

/// Full-screen brand background that slowly, endlessly cycles hue so the colour
/// is always shifting. A `tint` (the level's motif colour) offsets the starting
/// hue, so different levels begin on different colours. Still and readable under
/// Reduce Motion.
struct BrandBackground: View {
    var tint: Color? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                gradient(hue: 0.50)
            } else {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    // Ping-pong through a cheerful green→cyan→blue band, so the
                    // colour is always shifting but never lands on purple/amber.
                    let cycle = (t * 0.03).truncatingRemainder(dividingBy: 2.0)
                    let tri = cycle < 1 ? cycle : 2 - cycle
                    gradient(hue: 0.30 + tri * 0.33)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func gradient(hue: Double) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hue: hue, saturation: 0.45, brightness: 0.22),
                         Color(hue: hue, saturation: 0.58, brightness: 0.50)],
                startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [Color(hue: hue, saturation: 0.85, brightness: 0.62).opacity(0.5), .clear],
                center: .init(x: 0.5, y: 0.0), startRadius: 0, endRadius: 520)
            .blendMode(.screen)
        }
    }
}

/// A dimensional rounded tile surface used across game elements.
struct GlossyTile<Content: View>: View {
    var fill: LinearGradient = Brand.surfaceGloss
    var cornerRadius: CGFloat = 16
    var strokeColor: Color = .white
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Brand.edgeHighlight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 8, x: 0, y: 5)
    }
}

/// A large primary call-to-action button with a glossy, raised look.
struct PrimaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String? = nil
    var tint: Color = Brand.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Brand.gloss(tint), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Brand.edgeHighlight, lineWidth: 1)
            )
            .foregroundStyle(Brand.ink)
            .shadow(color: tint.opacity(0.45), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

/// A compact labelled stat chip (XP, Memory Score, level).
struct StatChip: View {
    let title: LocalizedStringKey
    let value: String
    var systemImage: String
    var tint: Color = .white

    var body: some View {
        GlossyTile(cornerRadius: 14) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(value)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A rounded, dimensional card container.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GlossyTile(cornerRadius: 20) {
            content
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension Color {
    /// Returns the colour with its brightness scaled (0.8 = darker, 1.2 = lighter).
    func brightness(_ factor: Double) -> Color {
        #if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h, saturation: s, brightness: min(1, max(0, b * factor)), opacity: a)
        #else
        return self.opacity(1) // fallback: unchanged on platforms without UIKit
        #endif
    }
}

extension GameLevel {
    /// The tile motif evolves as you climb the ladder, so later levels feel new.
    /// Grouped into four colour tiers across the level range.
    var tileBase: Color {
        // A cheerful, bright palette cycled per level — cyan/teal/green/blue/
        // pink/coral. Purple and amber are avoided on purpose; white text stays
        // readable at this brightness.
        let hues: [Double] = [0.50, 0.42, 0.55, 0.34, 0.93, 0.60, 0.02, 0.88]
        let hue = hues[(index - 1) % hues.count]
        return Color(hue: hue, saturation: 0.78, brightness: 0.66)
    }
}

/// A chunky, beveled, glossy game tile — reads as a 3D piece (mahjong-style)
/// while staying transparent, fast, and tap-friendly for the many interactive
/// pieces. Real SceneKit is reserved for hero/celebration moments.
struct GameTile<Content: View>: View {
    var base: Color = Color(hue: 0.72, saturation: 0.35, brightness: 0.30)
    var cornerRadius: CGFloat = 16
    var pressed: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LinearGradient(
                        colors: [base.brightness(1.35), base, base.brightness(0.72)],
                        startPoint: .top, endPoint: .bottom))
            )
            // Raised bevel: bright lit top edge fading to a dark bottom edge.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.08), .black.opacity(0.35)],
                        startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
            )
            // Inner top sheen.
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.30), .clear],
                                         startPoint: .top, endPoint: .center))
                    .padding(1.5)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.45), radius: pressed ? 3 : 10,
                    x: 0, y: pressed ? 2 : 7)
            .scaleEffect(pressed ? 0.97 : 1)
    }
}

/// A springy press-down for tiles — they physically depress when tapped.
struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

/// A horizontal shake driven by an animatable progress value (0 → 1).
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 9
    var shakes: CGFloat = 3
    var animatableData: CGFloat = 0

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx = travel * sin(animatableData * .pi * shakes * 2)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0))
    }
}

/// A "doors opening" reveal: two panels cover the screen, then slide apart to
/// unveil the content when it appears (Vita-Mahjong style). Still under Reduce
/// Motion.
struct DoorReveal: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(GameStore.self) private var store
    @State private var open = false

    func body(content: Content) -> some View {
        content.overlay {
            if !reduceMotion {
                GeometryReader { geo in
                    let w = geo.size.width
                    HStack(spacing: 0) {
                        panel(seamOnRight: true).frame(width: w / 2 + 1)
                            .offset(x: open ? -(w / 2 + 2) : 0)
                        panel(seamOnRight: false).frame(width: w / 2 + 1)
                            .offset(x: open ? (w / 2 + 2) : 0)
                    }
                    .frame(width: w, height: geo.size.height)
                }
                .ignoresSafeArea()
                .allowsHitTesting(!open)
                .onAppear {
                    if store.soundEnabled { SoundPlayer.shared.play(.sparkle) }
                    withAnimation(.easeInOut(duration: 0.75)) { open = true }
                }
            }
        }
    }

    private func panel(seamOnRight: Bool) -> some View {
        LinearGradient(
            colors: [Color(hue: 0.50, saturation: 0.50, brightness: 0.30),
                     Color(hue: 0.52, saturation: 0.58, brightness: 0.16)],
            startPoint: .top, endPoint: .bottom)
        .overlay(alignment: seamOnRight ? .trailing : .leading) {
            Rectangle()
                .fill(LinearGradient(
                    colors: seamOnRight ? [.clear, Brand.accent.opacity(0.9)]
                                        : [Brand.accent.opacity(0.9), .clear],
                    startPoint: .leading, endPoint: .trailing))
                .frame(width: 10)
        }
        .overlay(alignment: seamOnRight ? .trailing : .leading) {
            Text("🧠").font(.system(size: 40))
                .offset(x: seamOnRight ? 20 : -20)
        }
    }
}

extension View {
    func doorReveal() -> some View { modifier(DoorReveal()) }
}

/// A subtle, endless vertical bob to give idle tiles a little life. Phase-offset
/// by `seed` so a grid of tiles drifts out of sync. Still under Reduce Motion.
struct GentleFloat: ViewModifier {
    let seed: Int
    @State private var up = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(y: (reduceMotion || !up) ? 0 : -4)
            .animation(reduceMotion ? nil
                       : .easeInOut(duration: 1.8 + Double(seed % 5) * 0.3).repeatForever(autoreverses: true),
                       value: up)
            .onAppear { up = true }
    }
}

extension View {
    func gentleFloat(_ seed: Int) -> some View { modifier(GentleFloat(seed: seed)) }

    /// A one-shot Y-axis flip when `active` becomes true — the tile "turns over"
    /// to reveal its result (mahjong-style). A full 360° keeps content upright.
    func flipReveal(_ active: Bool) -> some View {
        rotation3DEffect(.degrees(active ? 360 : 0), axis: (x: 0, y: 1, z: 0),
                         perspective: 0.4)
            .animation(.easeInOut(duration: 0.5), value: active)
    }
}

/// A one-shot radial spark burst — the little "explosion" when a tile lands
/// correctly. Fires its animation on appear, so show it conditionally.
struct SparkBurst: View {
    var color: Color = Brand.accent
    var count: Int = 12
    var radius: CGFloat = 40
    @State private var go = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                    .offset(x: go ? cos(angle) * radius : 0,
                            y: go ? sin(angle) * radius : 0)
                    .scaleEffect(go ? 0.3 : 1)
                    .opacity(go ? 0 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.55)) { go = true } }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A left-to-right layout that wraps to the next line when it runs out of
/// width — used for the scrambled letter tray, whose tile count varies by word.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                          proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Circular progress ring used for the XP ring on the home screen.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var tint: Color = Brand.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
