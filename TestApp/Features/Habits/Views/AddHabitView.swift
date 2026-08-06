//
//  AddHabitView.swift
//  TestApp
//
//  Create sheet for a recurring habit: name, icon, color, and an optional daily
//  reminder. Location reminders are created separately (AddPlaceReminderView).
//

import SwiftData
import SwiftUI

struct AddHabitView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var iconName = "star.fill"
  @State private var colorHex = "#FB0021"
  @State private var reminderEnabled = false
  @State private var reminderTime = Date()
  @State private var weekdays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
  @State private var timerEnabled = false
  @State private var durationMinutes = 20

  @FocusState private var nameFocused: Bool

  private let icons = [
    "star.fill", "bolt.fill", "leaf.fill", "heart.fill",
    "book.fill", "drop.fill", "flame.fill", "figure.run",
  ]
  private let colors = ["#FB0021", "#FF9500", "#34C759", "#007AFF", "#AF52DE", "#FF2D55"]

  private var isValid: Bool {
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
    // A reminder with no days selected would never fire — require at least one.
    if reminderEnabled && weekdays.isEmpty { return false }
    return true
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Name") {
          TextField("e.g. Drink water", text: $name)
            .focused($nameFocused)
        }

        Section("Icon") {
          IconPickerGrid(icons: icons, selection: $iconName, tintHex: colorHex)
        }
        Section("Color") {
          ColorPickerRow(colors: colors, selection: $colorHex)
        }

        Section("Daily reminder") {
          Toggle("Daily reminder", isOn: $reminderEnabled)
          if reminderEnabled {
            DatePicker(
              "Time",
              selection: $reminderTime,
              displayedComponents: .hourAndMinute
            )
            WeekdayPicker(selection: $weekdays, tintHex: colorHex)
              .padding(.vertical, 4)
          }
        }

        Section("Focus timer") {
          Toggle("Focus timer", isOn: $timerEnabled)
          if timerEnabled {
            Stepper(
              "Duration: \(durationMinutes) min",
              value: $durationMinutes, in: 5...120, step: 5)
          }
        }
      }
      .navigationTitle("New Habit")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { save() }
            .disabled(!isValid)
        }
      }
      .onAppear { nameFocused = true }
    }
  }

  // MARK: - Save
  private func save() {
    let sortedDays = weekdays.sorted()
    let habit = Habit(
      name: name.trimmingCharacters(in: .whitespaces),
      iconName: iconName,
      colorHex: colorHex,
      reminderTime: reminderEnabled ? reminderTime : nil,
      weekdays: sortedDays,
      durationMinutes: timerEnabled ? durationMinutes : nil
    )
    context.insert(habit)

    if reminderEnabled {
      let id = habit.notificationID
      let habitName = habit.name
      let icon = habit.iconName
      let color = habit.colorHex
      let days = sortedDays
      let time = reminderTime
      Task {
        if await NotificationManager.requestAuthorization() {
          NotificationManager.scheduleDailyReminder(
            id: id, habitName: habitName, iconName: icon, colorHex: color, weekdays: days, at: time)
        }
      }
    }

    dismiss()
  }
}
