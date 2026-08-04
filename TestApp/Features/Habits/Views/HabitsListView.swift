//
//  HabitsListView.swift
//  TestApp
//
//  The root screen. Shows two sections — recurring Habits and location-based
//  Place reminders — and a toolbar with add, stats, and a theme toggle whose
//  icon cycles system → light → dark.
//

import CoreLocation
import SwiftData
import SwiftUI

struct HabitsListView: View {
  @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
  @Query(sort: \PlaceReminder.createdAt, order: .reverse) private var places: [PlaceReminder]

  @Environment(\.modelContext) private var context

  // Theme lives here now (was in Settings). The root observes the same key.
  @AppStorage("appearance") private var appearance: Appearance = .system

  @State private var showingAddHabit = false
  @State private var showingAddPlace = false
  @State private var showingStats = false

  // Foreground-only: feeds the per-place distance shown in the rows.
  @State private var locationManager = LocationManager()
  // Drives the place-tracking Live Activity; shared down to the detail screen.
  @State private var liveActivity = LiveActivityManager()
  // Drives the habit focus-timer Live Activity; shared to the habit detail.
  @State private var habitTimer = HabitTimerManager()

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
                    PlaceReminderRow(reminder: place, userLocation: locationManager.currentLocation)
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
    .onAppear {
      if locationManager.status == .notDetermined {
        locationManager.requestWhenInUseAuthorization()
      }
      locationManager.startUpdatingLocation()
    }
    .onDisappear { locationManager.stopUpdatingLocation() }
    .environment(locationManager)
    .environment(liveActivity)
    .environment(habitTimer)
    // Every new fix, if an activity is tracking, refresh its distance. This
    // keeps firing in the background because tracking enables background
    // location updates while it's active.
    .onChange(of: locationManager.currentLocation) { _, newValue in
      guard let newValue, liveActivity.isTracking else { return }
      Task { await liveActivity.updateFromLocation(newValue) }
    }
  }

  private func deleteHabits(at offsets: IndexSet) {
    for index in offsets {
      let habit = habits[index]
      // Cancel the scheduled daily notification before dropping the model,
      // otherwise its repeating trigger keeps firing for a habit that no
      // longer exists. Canceling an unknown id is a harmless no-op.
      NotificationManager.cancelReminder(id: habit.notificationID)
      context.delete(habit)
    }
  }

  private func deletePlaces(at offsets: IndexSet) {
    for index in offsets {
      let place = places[index]
      // Same as above, plus the geofence region iOS is still monitoring.
      NotificationManager.cancelLocationReminder(id: place.notificationID)
      context.delete(place)
    }
  }
}
