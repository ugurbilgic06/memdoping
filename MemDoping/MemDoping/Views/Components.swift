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
    static let primary = Color(red: 0.55, green: 0.45, blue: 0.28)   // warm brown
    static let accent  = Color(red: 0.46, green: 0.60, blue: 0.30)   // moss green (visible on cream)
    static let success = Color(red: 0.42, green: 0.72, blue: 0.40)   // fresh leaf green
    static let danger  = Color(red: 0.90, green: 0.42, blue: 0.42)   // soft terracotta rose

    /// Dark ink used on light fills (e.g. the primary button).
    static let ink = Color(red: 0.18, green: 0.16, blue: 0.08)

    /// A deep moss for accent *text* on the light theme — the `accent` green is
    /// used for fills/tints, but as text on a light surface a deeper tone reads
    /// better, so coloured labels use this instead.
    static let accentText = Color(red: 0.26, green: 0.38, blue: 0.14)

    /// A deep green for *text* — the light `success` green is for fills/tints;
    /// as text on a light surface it's nearly invisible, so use this.
    static let successText = Color(red: 0.06, green: 0.50, blue: 0.34)

    /// A vivid magenta that contrasts strongly with the teal/turquoise accents —
    /// used to make things stand out clearly (e.g. chunk dividers).
    static let mark = Color(red: 0.93, green: 0.16, blue: 0.55)

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

    /// A soft top-lit fill for card surfaces — a frosted white that reads as a
    /// raised card on the light background.
    static var surfaceGloss: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.92), .white.opacity(0.78)],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// A soft edge stroke for the lit rim of a rounded card on a light theme.
    static var edgeHighlight: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.9), ink.opacity(0.08)],
            startPoint: .top, endPoint: .bottom
        )
    }
}

/// Full-screen brand background: a warm cream→moss wash with a calm, endlessly
/// drifting layer of memory motifs (numbers, letters, little symbols) floating
/// upward — patterned, not a flat single colour, and gently alive. Still and
/// readable under Reduce Motion.
struct BrandBackground: View {
    var tint: Color? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Motif {
        let glyph: String; let x: CGFloat; let size: CGFloat
        let phase: Double; let speed: Double; let sway: Double
    }

    /// Generated once so motifs don't jump between redraws.
    private static let motifs: [Motif] = {
        let glyphs = ["1","2","3","5","7","9","A","B","C","E","K","M","R",
                      "🧠","📚","✨","🌿","🍃","➕","∑","🔢","🔤","🎵","🐚"]
        return (0..<30).map { _ in
            Motif(glyph: glyphs.randomElement()!,
                  x: CGFloat.random(in: 0.02...0.98),
                  size: CGFloat.random(in: 15...42),
                  phase: Double.random(in: 0...1),
                  speed: Double.random(in: 0.5...1.3),
                  sway: Double.random(in: 0...(.pi * 2)))
        }
    }()

    var body: some View {
        ZStack {
            base
            GeometryReader { geo in
                if reduceMotion {
                    motifLayer(geo: geo, t: 0)
                } else {
                    TimelineView(.animation) { timeline in
                        motifLayer(geo: geo, t: timeline.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// The warm base wash — cream at the top settling into soft moss.
    private var base: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.99, green: 0.98, blue: 0.91),   // cream
                         Color(red: 0.90, green: 0.93, blue: 0.78),   // pale yellow-green
                         Color(red: 0.80, green: 0.85, blue: 0.66)],  // light moss
                startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [Color(red: 1.0, green: 0.98, blue: 0.80).opacity(0.7), .clear],
                center: .init(x: 0.5, y: 0.02), startRadius: 0, endRadius: 520)
            .blendMode(.screen)
        }
    }

    private func motifLayer(geo: GeometryProxy, t: Double) -> some View {
        let span = geo.size.height + 90
        return ZStack {
            ForEach(0..<Self.motifs.count, id: \.self) { i in
                let m = Self.motifs[i]
                // Drift slowly upward and wrap; a little horizontal sway.
                let travel = (t * 9 * m.speed + m.phase * span).truncatingRemainder(dividingBy: span)
                let y = geo.size.height + 40 - travel
                let x = m.x * geo.size.width + CGFloat(sin(t * 0.25 * m.speed + m.sway)) * 12
                Text(m.glyph)
                    .font(.system(size: m.size, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.34, green: 0.42, blue: 0.20))
                    .opacity(0.12)
                    .position(x: x, y: y)
            }
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
            .shadow(color: Brand.ink.opacity(0.14), radius: 10, x: 0, y: 6)
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
    var tint: Color = Brand.primary

    var body: some View {
        GlossyTile(cornerRadius: 14) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(value)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.primary.opacity(0.7))
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
        // pink/coral. Purple and amber are avoided on purpose; kept light and
        // saturated so dark text stays readable on the tile.
        let hues: [Double] = [0.50, 0.42, 0.55, 0.34, 0.93, 0.60, 0.02, 0.88]
        let hue = hues[(index - 1) % hues.count]
        return Color(hue: hue, saturation: 0.62, brightness: 0.86)
    }
}

/// How cartoonish content symbols should look: 0 = restrained/flat (adults),
/// 1 = big, bouncy, thick-outlined (young children). Set once from the age band
/// (see ContentView) and inherited by every `SymbolBadge`.
private struct CartoonLevelKey: EnvironmentKey {
    static let defaultValue: Double = 0.55
}
extension EnvironmentValues {
    var cartoonLevel: Double {
        get { self[CartoonLevelKey.self] }
        set { self[CartoonLevelKey.self] = newValue }
    }
}

/// A large, illustrated presentation of a content emoji: the symbol sits on a
/// glossy, depth-shaded plate whose colour is distinct per item, so a row of
/// them reads as a set of friendly, recognisable tokens rather than flat emoji.
/// Helps young / pre-reading players lean on the picture, not the word. The look
/// gets rounder, bolder and more colourful for younger players (`cartoonLevel`).
struct SymbolBadge: View {
    let symbol: String
    /// Varies the plate colour so neighbouring badges are easy to tell apart.
    var seed: Int = 0
    /// Overall plate size; the emoji fills most of it.
    var size: CGFloat = 84

    @Environment(\.cartoonLevel) private var cartoon

    /// A cheerful palette — cyan/teal/green/blue/pink/coral. Purple and amber
    /// are avoided on purpose (the owner's steer).
    private var plate: Color {
        // A full, bright rainbow across the whole wheel — ordered so consecutive
        // seeds jump far around it, giving a lively "rengarenk" spread rather
        // than a run of similar tones. Kept luminous so nothing reads gloomy.
        let hues: [Double] = [0.00, 0.50, 0.13, 0.62, 0.33, 0.85, 0.08,
                              0.55, 0.75, 0.28, 0.92, 0.44, 0.68, 0.18]
        let h = hues[abs(seed) % hues.count]
        // Vivid and bright; younger players get an extra saturation boost.
        return Color(hue: h, saturation: 0.62 + 0.15 * cartoon, brightness: 0.92)
    }

    var body: some View {
        // Rounder corners, bigger emoji, thicker outline and softer shadow the
        // more cartoonish the level — a tick bigger for everyone.
        let corner = size * (0.28 + 0.10 * cartoon)
        let emojiSize = size * (0.66 + 0.09 * cartoon)
        let outline = 1.5 + 2.2 * cartoon
        Text(symbol)
            .font(.system(size: emojiSize))
            .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(LinearGradient(
                        colors: [plate.brightness(1.22), plate, plate.brightness(0.82)],
                        startPoint: .top, endPoint: .bottom))
            )
            // Top sheen for a rounded, glossy read.
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.45), .clear],
                                         startPoint: .top, endPoint: .center))
                    .padding(2)
                    .allowsHitTesting(false)
            }
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(LinearGradient(
                        colors: [.white.opacity(0.8), .black.opacity(0.20)],
                        startPoint: .top, endPoint: .bottom), lineWidth: outline)
            )
            .shadow(color: plate.opacity(0.5), radius: 9 + 4 * cartoon, y: 6)
            .accessibilityHidden(true)   // the caller labels the pair with its word
    }
}

/// A chunky, beveled, glossy game tile — reads as a 3D piece (mahjong-style)
/// while staying transparent, fast, and tap-friendly for the many interactive
/// pieces. Real SceneKit is reserved for hero/celebration moments.
struct GameTile<Content: View>: View {
    var base: Color = Color(hue: 0.52, saturation: 0.55, brightness: 0.84)
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
            .shadow(color: Brand.ink.opacity(0.22), radius: pressed ? 3 : 9,
                    x: 0, y: pressed ? 2 : 6)
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

/// A staggered "deal-in" entrance — tiles rise, scale up, and fade in one after
/// another, like pieces being dealt. Give each its position `index`. Reset by
/// changing the container's `.id` (e.g. per question). Still under Reduce Motion.
struct DealIn: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 20)
            .scaleEffect(shown || reduceMotion ? 1 : 0.92, anchor: .top)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.spring(response: 0.42, dampingFraction: 0.72)
                    .delay(Double(index) * 0.06)) { shown = true }
            }
    }
}

extension View {
    /// Deals this view in with a staggered rise/scale by its `index`.
    func dealIn(_ index: Int) -> some View { modifier(DealIn(index: index)) }
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

/// A compact, one-shot confetti pop — colourful pieces spray out and drift down.
/// Anchored to a tile (e.g. a correct answer) as an overlay.
struct ConfettiBurst: View {
    var count: Int = 20
    @State private var go = false

    private struct Piece: Identifiable {
        let id = UUID()
        let angle: Double
        let dist: CGFloat
        let color: Color
        let size: CGFloat
        let rot: Double
        let isCircle: Bool
    }

    private let pieces: [Piece]

    init(count: Int = 20) {
        self.count = count
        let colors: [Color] = [Brand.accent, Brand.success, Brand.primary,
                               Brand.danger, Color(red: 1.0, green: 0.8, blue: 0.3)]
        pieces = (0..<count).map { i in
            Piece(angle: Double(i) / Double(count) * 2 * .pi + Double.random(in: -0.25...0.25),
                  dist: CGFloat.random(in: 46...96),
                  color: colors.randomElement()!,
                  size: CGFloat.random(in: 6...11),
                  rot: Double.random(in: 160...720),
                  isCircle: Bool.random())
        }
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { p in
                Group {
                    if p.isCircle {
                        Circle().fill(p.color).frame(width: p.size, height: p.size)
                    } else {
                        Rectangle().fill(p.color).frame(width: p.size, height: p.size * 0.5)
                    }
                }
                .rotationEffect(.degrees(go ? p.rot : 0))
                .offset(x: go ? cos(p.angle) * p.dist : 0,
                        y: go ? sin(p.angle) * p.dist + 34 : 0)   // drift down a little
                .opacity(go ? 0 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.85)) { go = true } }
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
                .stroke(.primary.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
