//
//  CardView.swift
//  TestApp
//
//  Presentational view for ONE card. It knows nothing about gestures, the
//  stack, or animation — it just renders a `Card`. Small, reusable, and
//  composable (think of it as a Flutter widget). The parent decides where it
//  sits and how it moves.
//

import SwiftUI

struct CardView: View {
    let card: Card

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: card.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 300, height: 420)
            .overlay { content }
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 12)
    }

    private var content: some View {
        VStack(spacing: 18) {
            Image(systemName: card.symbol)
                .font(.system(size: 70))
                .foregroundStyle(.white)

            Text(card.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding()
    }
}
