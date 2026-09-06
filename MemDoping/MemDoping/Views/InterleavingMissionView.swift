//
//  InterleavingMissionView.swift
//  MemDoping
//
//  T06 Interleaving ("Karışık Meydan"). Two steps per question — category, then
//  word — over a shuffled mix of themes. Categories are colour-coded AND named
//  (never colour alone, for accessibility). The intro frames the extra
//  difficulty as expected and useful so it doesn't read as failure (§2).
//

import SwiftUI

struct InterleavingMissionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: InterleavingSession
    @State private var outcome: GameStore.SessionOutcome?
    @State private var revealed = false

    init(level: GameLevel) {
        _session = State(initialValue: InterleavingSession(level: level))
    }

    var body: some View {
        ZStack {
            BrandBackground(tint: session.level.tileBase)

            Group {
                switch session.phase {
                case .intro:    introPhase
                case .play:     playPhase
                case .feedback: feedbackPhase
                case .summary:  summaryPhase
                }
            }
            .padding()
            .transition(reduceMotion ? .opacity : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity))
        }
        .animation(reduceMotion ? nil : .easeInOut, value: session.phase)
        .navigationBarBackButtonHidden(session.phase != .intro)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if session.phase == .play {
                    Button("Quit") { dismiss() }
                        .foregroundStyle(Color.primary.opacity(0.8))
                }
            }
        }
    }

    // MARK: Intro

    private var introPhase: some View {
        MissionIntro(
            level: session.level,
            stats: [
                MissionStat("\(session.themes.count)", "categories", "square.grid.2x2"),
                MissionStat("\(session.totalQuestions)", "to recall", "checklist"),
                MissionStat("2", "steps each", "arrow.triangle.branch")
            ],
            onStart: { session.begin() }
        )
    }

    // MARK: Play — category then answer

    private var playPhase: some View {
        VStack(spacing: 18) {
            ProgressView(value: session.progress).tint(Brand.accent)

            if let q = session.current {
                Symbol3DTile(symbol: q.pair.symbol, tint: session.level.tileBase, size: 132,
                             celebrate: revealed && q.answerCorrect)
                    .padding(.top, 4)

                if session.step == .category {
                    Text("Which category?")
                        .font(.title3.weight(.semibold)).foregroundStyle(.primary)
                    VStack(spacing: 12) {
                        ForEach(Array(q.categoryOptions.enumerated()), id: \.element.id) { i, theme in
                            categoryButton(theme).dealIn(i)
                        }
                    }
                } else {
                    chosenCategoryChip(q)
                    Text("Which word?")
                        .font(.title3.weight(.semibold)).foregroundStyle(.primary)
                    VStack(spacing: 12) {
                        ForEach(Array(q.answerOptions.enumerated()), id: \.element) { i, option in
                            answerButton(option, question: q).dealIn(i)
                        }
                    }
                }

                Spacer()

                if revealed {
                    PrimaryButton(
                        title: session.index + 1 < session.totalQuestions ? "Next" : "Finish",
                        systemImage: "arrow.right"
                    ) {
                        revealed = false
                        session.advance()
                    }
                }
            }
        }
        .id(session.index)
    }

    private func categoryButton(_ theme: MemoryTheme) -> some View {
        Button {
            if store.soundEnabled { SoundPlayer.shared.play(.tap) }
            if store.hapticsEnabled { HapticsPlayer.shared.tap() }
            session.pickCategory(theme)
        } label: {
            GameTile(base: themeColor(theme.id).brightness(0.62), cornerRadius: 14) {
                HStack(spacing: 12) {
                    Text(themeIcon(theme.id)).font(.title2)
                    Text(theme.title.localizedContent)
                        .foregroundStyle(.primary).fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private func chosenCategoryChip(_ q: InterleavingSession.Question) -> some View {
        let picked = session.theme(id: q.chosenCategoryID ?? "")
        return HStack(spacing: 6) {
            if let picked {
                Text(themeIcon(picked.id))
                Text(picked.title.localizedContent).fontWeight(.semibold)
            }
            if !q.categoryCorrect, let correct = session.theme(id: q.themeID) {
                Text("· actually \(correct.title.localizedContent)")
                    .foregroundStyle(Brand.danger)
            }
        }
        .font(.subheadline)
        .foregroundStyle(Color.primary.opacity(0.85))
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color.primary.opacity(0.06), in: Capsule())
    }

    private func answerButton(_ option: String, question q: InterleavingSession.Question) -> some View {
        let isChosen = q.chosenAnswer == option
        let isCorrectAnswer = option == q.pair.word
        var base = session.level.tileBase
        if revealed {
            if isCorrectAnswer { base = Brand.success }
            else if isChosen { base = Brand.danger }
        }
        return Button {
            guard !revealed else { return }
            session.pickAnswer(option)
            revealed = true
            if store.soundEnabled { SoundPlayer.shared.play(isCorrectAnswer ? .pop : .incorrect) }
            if store.hapticsEnabled { HapticsPlayer.shared.notify(success: isCorrectAnswer) }
        } label: {
            GameTile(base: base, cornerRadius: 14) {
                HStack {
                    Text(option.localizedContent).foregroundStyle(.primary).fontWeight(.medium)
                    Spacer()
                    if revealed && isCorrectAnswer {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.primary)
                    } else if revealed && isChosen {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.primary)
                    }
                }
                .padding().frame(maxWidth: .infinity)
            }
            .scaleEffect(isChosen && revealed ? 1.05 : 1.0)
            .flipReveal(revealed && isChosen && isCorrectAnswer && !reduceMotion)
            .modifier(ShakeEffect(animatableData:
                (revealed && isChosen && !isCorrectAnswer && !reduceMotion) ? 1 : 0))
            .overlay { if revealed && isCorrectAnswer && !reduceMotion { SparkBurst(color: .white) } }
        }
        .buttonStyle(TileButtonStyle())
        .disabled(revealed)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.55), value: revealed)
    }

    // MARK: Feedback

    private var feedbackPhase: some View {
        VStack(spacing: 16) {
            Text("Through the mix")
                .font(.title2.bold()).foregroundStyle(.primary)
            Text("\(session.correctCount) of \(session.totalQuestions) recalled")
                .foregroundStyle(Color.primary.opacity(0.8))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(session.questions.enumerated()), id: \.element.id) { i, q in
                        HStack(spacing: 12) {
                            Text(q.pair.symbol).font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(q.pair.word.localizedContent)
                                    .font(.headline).foregroundStyle(.primary)
                                if !q.categoryCorrect {
                                    Text("wrong category")
                                        .font(.caption).foregroundStyle(Brand.danger)
                                }
                            }
                            Spacer()
                            Image(systemName: q.answerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(q.answerCorrect ? Brand.success : Brand.danger)
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .dealIn(i)
                    }
                }
            }

            Card {
                Label {
                    Text(session.categoryErrors == 0
                         ? "You kept the categories straight the whole way — that's the interleaving skill."
                         : "Mixed practice feels harder now but pays off later. Sorting the category first is the skill to watch.")
                        .font(.subheadline).foregroundStyle(Color.primary.opacity(0.85))
                } icon: {
                    Image(systemName: "arrow.triangle.branch").foregroundStyle(Brand.accent)
                }
            }

            PrimaryButton(title: "See results", systemImage: "arrow.right") {
                let result = store.complete(
                    level: session.level,
                    correct: session.correctCount,
                    total: session.totalQuestions
                )
                outcome = result
                scheduleReviews()
                if store.soundEnabled { SoundPlayer.shared.play(result.mastered ? .levelUp : .correct) }
                if store.hapticsEnabled { HapticsPlayer.shared.notify(success: result.mastered) }
                session.showSummary()
            }
        }
    }

    /// Interleaving mixes themes, so schedule each pair under its own theme id.
    private func scheduleReviews() {
        let grouped = Dictionary(grouping: session.reviewablePairsByTheme, by: { $0.themeID })
        for (themeID, entries) in grouped {
            store.scheduleReviews(themeId: themeID, pairs: entries.map(\.pair))
        }
    }

    // MARK: Summary

    private var summaryPhase: some View {
        MissionSummary(
            passedMastery: session.passedMastery,
            accuracy: session.accuracy,
            outcome: outcome,
            onRetry: {
                session = session.makeRetry()
                outcome = nil
                revealed = false
            },
            onExit: { dismiss() }
        )
    }

    // MARK: Theme visuals (colour + icon, never colour alone)

    private func themeColor(_ id: String) -> Color {
        switch id {
        case "animals": Brand.accent
        case "food":    Brand.success
        case "space":   Brand.primary
        case "travel":  Color(red: 0.30, green: 0.62, blue: 0.90)
        default:        Color.primary.opacity(0.5)
        }
    }

    private func themeIcon(_ id: String) -> String {
        switch id {
        case "animals": "🐾"
        case "food":    "🍽️"
        case "space":   "🌌"
        case "travel":  "🧭"
        default:        "❓"
        }
    }
}

#Preview("Interleaving — mixed categories") {
    InterleavingMissionView(level: SampleLevels.level(at: 7)!)
        .environment(GameStore())
}
