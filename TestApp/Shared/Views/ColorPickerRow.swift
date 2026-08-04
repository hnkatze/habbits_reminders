//
//  ColorPickerRow.swift
//  TestApp
//
//  Reusable horizontal row of color swatches. Shared by the habit and place
//  create sheets. Each swatch is a real Button so VoiceOver announces it and
//  reports the current selection, instead of a silent tap gesture on a Circle.
//

import SwiftUI

struct ColorPickerRow: View {
  let colors: [String]
  @Binding var selection: String

  var body: some View {
    HStack(spacing: 14) {
      ForEach(Array(colors.enumerated()), id: \.element) { index, hex in
        let isSelected = hex == selection
        Button {
          selection = hex
        } label: {
          Circle()
            .fill(Color(hex: hex))
            .frame(width: 32, height: 32)
            .overlay {
              if isSelected {
                Image(systemName: "checkmark")
                  .font(.caption.bold())
                  .foregroundStyle(.white)
              }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color \(index + 1)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
      }
    }
  }
}
