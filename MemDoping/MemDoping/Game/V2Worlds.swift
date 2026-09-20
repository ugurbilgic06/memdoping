//
//  V2Worlds.swift
//  MemDoping
//
//  The V2 mission template, now applied to the whole 100-level ladder rather
//  than living in a separate "V2 Worlds" section: the six-phase flow and the
//  one-line hook that opens a mission.
//
//  The story/world layer moved to LadderWorlds.swift (five story worlds over
//  the ladder). Audience stays a lens — the age band shifts tone and difficulty
//  (see GameStore.ageOffset) — not a separate content track.
//

import SwiftUI

/// The six-phase mission flow the V2 spec targets (§4).
enum MissionPhase: String, CaseIterable {
    case hook, tutorial, play, challenge, recall, reward

    /// The name shown in the phase bar. Kept as a key so it translates — the
    /// raw values stay English identifiers.
    var label: LocalizedStringKey {
        switch self {
        case .hook:      return "Hook"
        case .tutorial:  return "Teach"
        case .play:      return "Playing"
        case .challenge: return "Pace"
        case .recall:    return "Recall it"
        case .reward:    return "Reward"
        }
    }
}

/// The punchy opening line for a mission — the "hook" phase in one sentence.
/// One per mechanic, so all 100 levels get one without authoring 100 lines.
enum MissionHook {
    static func line(for mechanic: LevelMechanic) -> LocalizedStringKey {
        switch mechanic {
        case .loci:         return "Walk the room, remember what went where."
        case .scene:        return "The odd one sticks."
        case .pairRecall:   return "Just looking isn't enough."
        case .chunking:     return "Nine digits. Fifteen seconds."
        case .retrieval:    return "No options. You produce it."
        case .interleaving: return "Two channels are mixed."
        case .elaboration:  return "Every fact hides a 'why'."
        case .story:        return "Chain them into one line."
        case .numberShape:  return "Every digit has a shape."
        }
    }
}

/// The six-phase flow, drawn as a compact bar.
struct MissionPhaseBar: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(MissionPhase.allCases.enumerated()), id: \.offset) { i, p in
                Text(p.label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Brand.text.opacity(0.7))
                    .padding(.vertical, 5).frame(maxWidth: .infinity)
                    .background(Brand.text.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
                if i < MissionPhase.allCases.count - 1 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 7)).foregroundStyle(Brand.text.opacity(0.35))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
