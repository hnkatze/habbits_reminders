//
//  HabitDetailView.swift
//  TestApp
//
//  Detail screen: big toggle to mark today done/undone, current streak, and a
//  7-day history strip. `@Bindable` receives the SwiftData model; mutating its
//  entries relationship updates every view observing this habit.
//

import SwiftData
import SwiftUI

struct HabitDetailView: View {
  @Bindable var habit: Habit
  @Environment(\.modelContext) private var context
  @Environment(HabitTimerManager.self) private var habitTimer

  var body: some View {
    ScrollView {
      VStack(spacing: 28) {
        header
        toggleButton
        if habit.durationMinutes != nil {
          timerButton
        }
        streakCard
        historyStrip
      }
      .padding()
    }
    .navigationTitle(habit.name)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        ShareLink(item: shareText) {
          Image(systemName: "square.and.arrow.up")
        }
      }
    }
  }

  private var shareText: String {
    let streak = habit.currentStreak
    return streak > 0
      ? "I'm on a \(streak)-day streak for \(habit.name)! 🔥"
      : "I'm building a new habit: \(habit.name)."
  }

  // MARK: - Header
  private var header: some View {
    Image(systemName: habit.iconName)
      .font(.system(size: 60))
      .foregroundStyle(Color(hex: habit.colorHex))
      .frame(width: 110, height: 110)
      .background(Color(hex: habit.colorHex).opacity(0.15), in: .circle)
      .padding(.top, 8)
  }

  // MARK: - Today toggle
  private var toggleButton: some View {
    Button {
      withAnimation(.snappy) { toggleToday() }
    } label: {
      Label(
        habit.isCompletedToday ? "Completed today" : "Mark as done",
        systemImage: habit.isCompletedToday ? "checkmark.circle.fill" : "circle"
      )
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
    }
    .tint(Color(hex: habit.colorHex))
    .buttonStyle(.borderedProminent)
    .sensoryFeedback(.success, trigger: habit.isCompletedToday)
  }

  // MARK: - Focus timer (only when the habit has a duration)
  @ViewBuilder
  private var timerButton: some View {
    if let minutes = habit.durationMinutes {
      if habitTimer.isRunning(habit) {
        Button {
          Task { await habitTimer.stop() }
        } label: {
          Label("Stop timer", systemImage: "stop.circle.fill")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.red)
      } else {
        Button {
          habitTimer.start(habit: habit, minutes: minutes)
        } label: {
          Label("Start \(minutes)-min focus timer", systemImage: "timer")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(Color(hex: habit.colorHex))
        .disabled(habitTimer.isRunning)
      }
    }
  }

  // MARK: - Streak
  private var streakCard: some View {
    VStack(spacing: 4) {
      Text("\(habit.currentStreak)")
        .font(.system(size: 44, weight: .bold, design: .rounded))
        .foregroundStyle(Color(hex: habit.colorHex))
      Text("day streak")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
    .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 16))
  }

  // MARK: - History (last 7 days)
  private var historyStrip: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Last 7 days")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)

      HStack(spacing: 8) {
        ForEach(last7Days, id: \.self) { day in
          let done = habit.isCompleted(on: day)
          VStack(spacing: 6) {
            Circle()
              .fill(done ? Color(hex: habit.colorHex) : Color.gray.opacity(0.25))
              .frame(width: 34, height: 34)
              .overlay {
                if done {
                  Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                }
              }
            Text(dayLabel(day))
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
  }

  // MARK: - Logic
  private func toggleToday() {
    let calendar = Calendar.current
    if let existing = habit.entries.first(where: { calendar.isDate($0.date, inSameDayAs: .now) }) {
      context.delete(existing)  // was done → undo
    } else {
      let entry = HabitEntry(date: .now, habit: habit)
      context.insert(entry)  // mark done
    }
  }

  private var last7Days: [Date] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    return (0..<7).reversed().compactMap {
      calendar.date(byAdding: .day, value: -$0, to: today)
    }
  }

  private func dayLabel(_ date: Date) -> String {
    date.formatted(.dateTime.weekday(.narrow))
  }
}
