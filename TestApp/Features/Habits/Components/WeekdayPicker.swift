//
//  WeekdayPicker.swift
//  TestApp
//
//  Seven toggleable day chips for choosing which days a habit reminder fires.
//  Selection holds Calendar weekday numbers (1 = Sunday … 7 = Saturday), so it
//  maps straight onto UNCalendarNotificationTrigger. Built from real Buttons
//  with the `.isSelected` VoiceOver trait, matching IconPickerGrid /
//  ColorPickerRow.
//

import SwiftUI

struct WeekdayPicker: View {
  @Binding var selection: Set<Int>
  var tintHex: String

  // Localized one-letter symbols; index 0 = Sunday, matching weekday number 1.
  private var symbols: [String] { Calendar.current.veryShortWeekdaySymbols }
  private var names: [String] { Calendar.current.weekdaySymbols }

  var body: some View {
    HStack(spacing: 6) {
      ForEach(Array(symbols.enumerated()), id: \.offset) { index, symbol in
        let weekday = index + 1
        let isOn = selection.contains(weekday)
        Button {
          if isOn { selection.remove(weekday) } else { selection.insert(weekday) }
        } label: {
          Text(symbol)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 38)
            .foregroundStyle(isOn ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .background {
              Capsule().fill(isOn ? AnyShapeStyle(Color(hex: tintHex)) : AnyShapeStyle(.quaternary))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(names[index])
        .accessibilityAddTraits(isOn ? .isSelected : [])
      }
    }
  }
}
