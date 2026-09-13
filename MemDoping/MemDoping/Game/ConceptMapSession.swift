//
//  ConceptMapSession.swift
//  MemDoping
//
//  PACER **C** — Conceptual knowledge, whose operation is *Mapping*.
//
//  The guide (p.5) describes conceptual material as a web rather than a list:
//    • put the main concept at the centre,
//    • add the sub-concepts and draw the relations between them,
//    • **write on each link what the relation actually is** — causes, increases,
//      decreases, requires, is an example of,
//    • rearrange the map as new information arrives.
//
//  The labelling is the part that carries the knowledge, so it's the part the
//  game asks for. Drawing an unnamed line between "stress" and "remembering"
//  says nothing; choosing *decreases* says everything.
//
//  Two beats: build the map with the notes visible, then rebuild the relations
//  with the map gone. The second beat is where "increases" and "decreases" stop
//  feeling interchangeable.
//
//  This is deliberately distinct from Elaboration, which picks one reason for
//  one fact. Here the player is naming edges in a network.
//
//  SAMPLE CONTENT: small everyday maps (see SampleContent.conceptMaps).
//

import Foundation
import Observation

@Observable
final class ConceptMapSession {

    enum Phase: Equatable {
        case intro
        case map        // connect each idea to the centre and name the relation
        case recall     // name the relations again, map hidden
        case feedback
        case summary
    }

    /// One spoke being labelled while the map is visible.
    struct MapLink: Identifiable {
        let id = UUID()
        let node: ConceptNode
        let options: [RelationKind]
        var chosen: RelationKind?
        var isCorrect: Bool { chosen == node.relation }
        var isAnswered: Bool { chosen != nil }
    }

    /// The same relation asked again with the map out of sight.
    struct RecallQ: Identifiable {
        let id = UUID()
        let node: ConceptNode
        let options: [RelationKind]
        var chosen: RelationKind?
        var isCorrect: Bool { chosen == node.relation }
    }

    let level: GameLevel
    private(set) var phase: Phase = .intro

    private(set) var deck: ConceptMapDeck
    private(set) var links: [MapLink] = []
    private(set) var mapIndex: Int = 0

    private(set) var questions: [RecallQ] = []
    private(set) var recallIndex: Int = 0

    init(level: GameLevel) {
        self.level = level
        self.deck = level.conceptMap ?? SampleContent.conceptMaps[0]
        buildRun()
    }

    private func buildRun() {
        let nodes = Array(deck.nodes.shuffled().prefix(max(3, level.itemCount)))

        links = nodes.map { node in
            MapLink(node: node, options: Self.relationOptions(
                correct: node.relation, count: max(2, level.choiceCount)))
        }

        questions = nodes.shuffled()
            .prefix(max(2, level.questionCount))
            .map { node in
                RecallQ(node: node, options: Self.relationOptions(
                    correct: node.relation, count: max(2, level.choiceCount)))
            }
    }

    /// The correct relation plus plausible neighbours, shuffled. `increases` and
    /// `decreases` are kept together on purpose — telling a strengthener from a
    /// weakener is the discrimination the map is meant to train.
    private static func relationOptions(correct: RelationKind, count: Int) -> [RelationKind] {
        // The confusable twin is always kept in the running, so a correct answer
        // can't be reached by elimination.
        let twin: RelationKind?
        switch correct {
        case .increases: twin = .decreases
        case .decreases: twin = .increases
        case .causes:    twin = .requires
        case .requires:  twin = .causes
        case .exampleOf: twin = nil
        }

        var pool = RelationKind.allCases.filter { $0 != correct }.shuffled()
        if let twin {
            pool.removeAll { $0 == twin }
            pool.insert(twin, at: 0)
        }

        let wanted = max(1, min(RelationKind.allCases.count, max(2, count)) - 1)
        return (Array(pool.prefix(wanted)) + [correct]).shuffled()
    }

    // MARK: - Map

    var currentLink: MapLink? {
        links.indices.contains(mapIndex) ? links[mapIndex] : nil
    }
    var mapProgress: Double {
        links.isEmpty ? 0 : Double(mapIndex) / Double(links.count)
    }
    /// Spokes already labelled — the UI draws the map growing around the centre.
    var builtLinks: [MapLink] { links.filter(\.isAnswered) }

    func beginMapping() { phase = .map }

    func chooseRelation(_ relation: RelationKind) {
        guard phase == .map, links.indices.contains(mapIndex),
              links[mapIndex].chosen == nil else { return }
        links[mapIndex].chosen = relation
    }

    func advanceAfterLink() {
        if mapIndex + 1 < links.count {
            mapIndex += 1
        } else {
            phase = .recall
        }
    }

    // MARK: - Recall

    var currentQuestion: RecallQ? {
        questions.indices.contains(recallIndex) ? questions[recallIndex] : nil
    }
    var recallProgress: Double {
        questions.isEmpty ? 0 : Double(recallIndex) / Double(questions.count)
    }

    func answerCurrent(_ relation: RelationKind) {
        guard phase == .recall, questions.indices.contains(recallIndex),
              questions[recallIndex].chosen == nil else { return }
        questions[recallIndex].chosen = relation
    }

    func advanceAfterAnswer() {
        if recallIndex + 1 < questions.count {
            recallIndex += 1
        } else {
            phase = .feedback
        }
    }

    // MARK: - Scoring

    /// How well the map was labelled with its notes in view.
    var mappedCorrect: Int { links.filter(\.isCorrect).count }
    var mappedTotal: Int { links.count }

    /// The score: the relations that survived the map being taken away.
    var correctCount: Int { questions.filter(\.isCorrect).count }
    var totalQuestions: Int { questions.count }
    var accuracy: Double {
        totalQuestions == 0 ? 0 : Double(correctCount) / Double(totalQuestions)
    }
    var passedMastery: Bool { accuracy >= level.masteryPercent }

    func showSummary() { phase = .summary }
    func makeRetry() -> ConceptMapSession { ConceptMapSession(level: level) }
}
