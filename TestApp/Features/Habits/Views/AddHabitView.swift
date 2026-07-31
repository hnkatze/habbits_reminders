//
//  AddHabitView.swift
//  TestApp
//
//  Create sheet for a recurring habit: name, icon, color, and an optional daily
//  reminder. Location reminders are created separately (AddPlaceReminderView).
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var iconName = "star.fill"
    @State private var colorHex = "#FB0021"
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()

    @FocusState private var nameFocused: Bool

    private let icons = [
        "star.fill", "bolt.fill", "leaf.fill", "heart.fill",
        "book.fill", "drop.fill", "flame.fill", "figure.run"
    ]
    private let colors = ["#FB0021", "#FF9500", "#34C759", "#007AFF", "#AF52DE", "#FF2D55"]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Drink water", text: $name)
                        .focused($nameFocused)
                }

                Section("Icon") { iconGrid }
                Section("Color") { colorRow }

                Section("Daily reminder") {
                    Toggle("Daily reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker(
                            "Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
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

    // MARK: - Icon grid
    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
            ForEach(icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(icon == iconName ? Color(hex: colorHex) : .secondary)
                    .background(
                        icon == iconName ? Color(hex: colorHex).opacity(0.15) : .clear,
                        in: .rect(cornerRadius: 10)
                    )
                    .onTapGesture { iconName = icon }
            }
        }
    }

    // MARK: - Color row
    private var colorRow: some View {
        HStack(spacing: 14) {
            ForEach(colors, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 32, height: 32)
                    .overlay {
                        if hex == colorHex {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture { colorHex = hex }
            }
        }
    }

    // MARK: - Save
    private func save() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            iconName: iconName,
            colorHex: colorHex,
            reminderTime: reminderEnabled ? reminderTime : nil
        )
        context.insert(habit)

        if reminderEnabled {
            let id = habit.notificationID
            let habitName = habit.name
            let time = reminderTime
            Task {
                if await NotificationManager.requestAuthorization() {
                    NotificationManager.scheduleDailyReminder(id: id, habitName: habitName, at: time)
                }
            }
        }

        dismiss()
    }
}
