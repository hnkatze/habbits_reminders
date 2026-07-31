//
//  SwipeCardView.swift
//  TestApp
//
//  Phase 4 of the "card swipe" training project:
//  flinging a card now emits a spark burst, drawn with `Canvas` and driven by
//  a `TimelineView` game loop (see ParticleCanvas.swift).
//

import SwiftUI

struct SwipeCardView: View {

    @State private var cards: [Card] = Card.sampleDeck
    @State private var offset: CGSize = .zero
    @State private var particles: [Particle] = []

    private let threshold: CGFloat = 120
    private let maxVisible = 3

    var body: some View {
        ZStack {
            background

            if cards.isEmpty {
                emptyState
            } else {
                deck
            }

            // Sparks are drawn on top of everything and ignore touches.
            ParticleCanvas(particles: particles)
                .ignoresSafeArea()
        }
    }

    // MARK: - Deck
    private var deck: some View {
        ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                let depth = cards.count - 1 - index

                if depth < maxVisible {
                    CardView(card: card)
                        .scaleEffect(1 - CGFloat(depth) * 0.05)
                        .offset(y: CGFloat(depth) * -14)
                        .offset(depth == 0 ? offset : .zero)
                        .rotationEffect(depth == 0 ? .degrees(Double(offset.width / 18)) : .zero)
                        .overlay(alignment: .top) {
                            if depth == 0 { swipeBadge }
                        }
                        .gesture(dragGesture, including: depth == 0 ? .all : .none)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .zIndex(Double(index))
                }
            }
        }
    }

    // MARK: - Current drag intent (derived, not stored)
    private var dragDirection: SwipeDirection? {
        if offset.width > 40 { .right }
        else if offset.width < -40 { .left }
        else { nil }
    }

    // MARK: - Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
            }
            .onEnded { value in
                if value.translation.width > threshold {
                    fling(.right)
                } else if value.translation.width < -threshold {
                    fling(.left)
                } else {
                    withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.65)) {
                        offset = .zero
                    }
                }
            }
    }

    private func fling(_ direction: SwipeDirection) {
        // Emit the burst, dropping any particles that already died so the
        // array can't grow without bound between swipes.
        particles = particles.filter { $0.isAlive(at: Date()) }
            + Particle.burst(direction: direction)

        withAnimation(.easeOut(duration: 0.35)) {
            offset = direction.flyAwayOffset
        } completion: {
            offset = .zero
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                _ = cards.popLast()
            }
        }
    }

    // MARK: - Swipe badge (LIKE / NOPE)
    @ViewBuilder
    private var swipeBadge: some View {
        if let dragDirection {
            let info = dragDirection.badge
            Text(info.text)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(info.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(info.color, lineWidth: 4)
                )
                .rotationEffect(.degrees(dragDirection == .right ? -18 : 18))
                .padding(.top, 32)
                .opacity(min(Double(abs(offset.width) / threshold), 1.0))
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("That's the whole deck!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    cards = Card.sampleDeck
                }
            } label: {
                Label("Reshuffle", systemImage: "arrow.clockwise")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
        }
    }

    // MARK: - Background
    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.20),
                Color(red: 0.12, green: 0.08, blue: 0.35)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    SwipeCardView()
}
