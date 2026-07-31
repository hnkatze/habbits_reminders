//
//  HabitRow.swift
//  TestApp
//
//  Presentational row for the habits list. Reads a Habit, shows its icon,
//  name, current streak, and whether it's done today.
//

import SwiftUI

struct HabitRow: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: habit.iconName)
                .font(.title2)
                .foregroundStyle(Color(hex: habit.colorHex))
                .frame(width: 40, height: 40)
                .background(Color(hex: habit.colorHex).opacity(0.15), in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body.weight(.medium))

                Text(streakLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if habit.isCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private var streakLabel: String {
        let streak = habit.currentStreak
        return streak == 0 ? "No streak yet" : "\(streak) day streak"
    }
}
