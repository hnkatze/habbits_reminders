//
//  HabitRow.swift
//  TestApp
//
//  Presentational row for the habits list: a gradient icon chip, the name, an
//  animated streak badge, and a completion mark that bounces when toggled.
//

import SwiftUI

struct HabitRow: View {
  let habit: Habit

  private var color: Color { Color(hex: habit.colorHex) }

  var body: some View {
    HStack(spacing: 14) {
      iconChip

      VStack(alignment: .leading, spacing: 3) {
        Text(habit.name)
          .font(.body.weight(.semibold))
        streakBadge
      }

      Spacer()

      // Swaps circle ↔ filled check with a symbol morph, and bounces on change.
      Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
        .font(.title2)
        .foregroundStyle(habit.isCompletedToday ? AnyShapeStyle(.green) : AnyShapeStyle(.tertiary))
        .contentTransition(.symbolEffect(.replace))
        .symbolEffect(.bounce, value: habit.isCompletedToday)
    }
    .padding(.vertical, 6)
  }

  private var iconChip: some View {
    Image(systemName: habit.iconName)
      .font(.title3.weight(.semibold))
      .foregroundStyle(.white)
      .frame(width: 46, height: 46)
      .background(
        LinearGradient(
          colors: [color, color.opacity(0.7)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing),
        in: .rect(cornerRadius: 13, style: .continuous)
      )
      .shadow(color: color.opacity(0.35), radius: 5, y: 3)
  }

  @ViewBuilder
  private var streakBadge: some View {
    let streak = habit.currentStreak
    if streak == 0 {
      Text("No streak yet")
        .font(.caption)
        .foregroundStyle(.secondary)
    } else {
      HStack(spacing: 4) {
        Image(systemName: "flame.fill")
          .foregroundStyle(.orange)
          .symbolEffect(.variableColor.iterative.reversing, isActive: true)
        Text("\(streak)")
          .contentTransition(.numericText())
          .foregroundStyle(.primary)
        Text("day streak")
          .foregroundStyle(.secondary)
      }
      .font(.caption.weight(.medium))
    }
  }
}
