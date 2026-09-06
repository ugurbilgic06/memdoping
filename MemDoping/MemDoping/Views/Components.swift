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
    static let primary = Color(red: 0.36, green: 0.24, blue: 0.86)   // indigo
    static let accent  = Color(red: 0.98, green: 0.53, blue: 0.24)   // energetic orange
    static let success = Color(red: 0.16, green: 0.68, blue: 0.45)
    static let danger  = Color(red: 0.86, green: 0.30, blue: 0.34)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.10, green: 0.08, blue: 0.24),
                     Color(red: 0.17, green: 0.12, blue: 0.36)],
            startPoint: .top, endPoint: .bottom
        )
    }
}

/// Full-screen brand background.
struct BrandBackground: View {
    var body: some View {
        Brand.backgroundGradient.ignoresSafeArea()
    }
}

/// A large primary call-to-action button.
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
            .background(tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(.white)
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
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}

/// A rounded translucent card container.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
