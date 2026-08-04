//
//  IconPickerGrid.swift
//  TestApp
//
//  Reusable 4-column grid of SF Symbols to pick from. Shared by the habit and
//  place create sheets. Each cell is a real Button (not a tap gesture) so
//  VoiceOver announces it as a button and reports which one is selected.
//

import SwiftUI

struct IconPickerGrid: View {
  let icons: [String]
  @Binding var selection: String
  let tintHex: String

  private let columns = Array(repeating: GridItem(.flexible()), count: 4)

  var body: some View {
    LazyVGrid(columns: columns, spacing: 12) {
      ForEach(icons, id: \.self) { icon in
        let isSelected = icon == selection
        Button {
          selection = icon
        } label: {
          Image(systemName: icon)
            .font(.title2)
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isSelected ? Color(hex: tintHex) : .secondary)
            .background(
              isSelected ? Color(hex: tintHex).opacity(0.15) : .clear,
              in: .rect(cornerRadius: 10)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Self.readableName(for: icon))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
      }
    }
  }

  // Turn an SF Symbol name into something VoiceOver can read out loud:
  // "figure.run" -> "figure run", "cart.fill" -> "cart".
  static func readableName(for symbol: String) -> String {
    symbol
      .replacingOccurrences(of: ".fill", with: "")
      .replacingOccurrences(of: ".", with: " ")
  }
}
