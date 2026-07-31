//
//  Card.swift
//  TestApp
//
//  Model for a single swipeable card. Conforming to `Identifiable` gives each
//  card a STABLE identity (its `id`), so `ForEach` can track which card is
//  which across insertions and removals — the SwiftUI equivalent of a Key.
//

import SwiftUI

struct Card: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let colors: [Color]
}

extension Card {
    // Sample deck used by the preview and as the initial state.
    static var sampleDeck: [Card] {
        [
            Card(title: "Focus",  symbol: "scope",           colors: [.blue, .cyan]),
            Card(title: "Energy", symbol: "bolt.fill",       colors: [.orange, .red]),
            Card(title: "Calm",   symbol: "leaf.fill",       colors: [.green, .teal]),
            Card(title: "Dream",  symbol: "moon.stars.fill", colors: [.indigo, .purple]),
            Card(title: "Shine",  symbol: "sparkles",        colors: [.pink, .orange])
        ]
    }
}
