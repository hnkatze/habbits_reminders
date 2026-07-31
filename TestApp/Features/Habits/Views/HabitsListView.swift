//
//  HabitsListView.swift
//  TestApp
//
//  The root screen. Shows two sections — recurring Habits and location-based
//  Place reminders — and a toolbar with add, stats, and a theme toggle whose
//  icon cycles system → light → dark.
//

import SwiftUI
import SwiftData

struct HabitsListView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \PlaceReminder.createdAt, order: .reverse) private var places: [PlaceReminder]

    @Environment(\.modelContext) private var context

    // Theme lives here now (was in Settings). The root observes the same key.
    @AppStorage("appearance") private var appearance: Appearance = .system

    @State private var showingAddHabit = false
    @State private var showingAddPlace = false
    @State private var showingStats = false

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty && places.isEmpty {
                    ContentUnavailableView(
                        "Nothing yet",
                        systemImage: "bell.badge",
                        description: Text("Tap + to add a habit or a location reminder.")
                    )
                } else {
                    List {
                        if !habits.isEmpty {
                            Section("Habits") {
                                ForEach(habits) { habit in
                                    NavigationLink(value: habit) {
                                        HabitRow(habit: habit)
                                    }
                                }
                                .onDelete(perform: deleteHabits)
                            }
                        }

                        if !places.isEmpty {
                            Section("Places") {
                                ForEach(places) { place in
                                    NavigationLink(value: place) {
                                        PlaceReminderRow(reminder: place)
                                    }
                                }
                                .onDelete(perform: deletePlaces)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(habit: habit)
            }
            .navigationDestination(for: PlaceReminder.self) { place in
                PlaceReminderDetailView(reminder: place)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddHabit = true
                        } label: {
                            Label("Habit", systemImage: "repeat")
                        }
                        Button {
                            showingAddPlace = true
                        } label: {
                            Label("Location reminder", systemImage: "mappin")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingStats = true
                    } label: {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .disabled(habits.isEmpty)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.snappy) { appearance = appearance.next }
                    } label: {
                        Image(systemName: appearance.symbolName)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel("Theme: \(appearance.label)")
                }
            }
            .sheet(isPresented: $showingAddHabit) { AddHabitView() }
            .sheet(isPresented: $showingAddPlace) { AddPlaceReminderView() }
            .sheet(isPresented: $showingStats) { HabitStatsView() }
        }
        // Applied from a real View (which reacts to @AppStorage) at the root of
        // the hierarchy — not from a sheet, so it flips reliably both ways.
        .preferredColorScheme(appearance.colorScheme)
    }

    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            context.delete(habits[index])
        }
    }

    private func deletePlaces(at offsets: IndexSet) {
        for index in offsets {
            context.delete(places[index])
        }
    }
}
