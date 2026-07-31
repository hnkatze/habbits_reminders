//
//  HabitStatsView.swift
//  TestApp
//
//  Dashboard built with Swift Charts, styled with material cards, soft shadows,
//  gradient bars and value annotations. Chart data is precomputed into plain
//  structs so the chart closures stay trivial for the type-checker.
//

import SwiftUI
import SwiftData
import Charts

struct HabitStatsView: View {
    @Environment(\.dismiss) private var dismiss

    @Query private var habits: [Habit]
    @Query private var entries: [HabitEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    summaryRow
                    weeklyCard
                    perHabitCard
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.12), .clear],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
    }

    // MARK: - Summary tiles
    private var summaryRow: some View {
        HStack(spacing: 14) {
            statTile(value: "\(entries.count)", label: "Total done",
                     icon: "checkmark.seal.fill", tint: .green)
            statTile(value: "\(bestStreak)", label: "Best streak",
                     icon: "flame.fill", tint: .orange)
        }
    }

    private func statTile(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    // MARK: - Weekly chart
    private var weeklyCard: some View {
        chartCard(title: "Last 14 days", systemImage: "calendar") {
            Chart(dailyCounts) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Completions", day.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(6)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 200)
        }
    }

    // MARK: - Per-habit chart
    private var perHabitCard: some View {
        chartCard(title: "By habit", systemImage: "list.bullet") {
            Chart(habitStats) { stat in
                BarMark(
                    x: .value("Completions", stat.count),
                    y: .value("Habit", stat.name)
                )
                .foregroundStyle(stat.color.gradient)
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text("\(stat.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: max(120, CGFloat(habitStats.count) * 46))
        }
    }

    // MARK: - Card wrapper
    private func chartCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .padding(18)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    // MARK: - Derived data (precomputed → trivial chart closures)
    private var bestStreak: Int {
        habits.map(\.currentStreak).max() ?? 0
    }

    private var habitStats: [HabitStat] {
        habits.map { habit in
            HabitStat(
                name: habit.name,
                count: habit.entries.count,
                color: Color(hex: habit.colorHex)
            )
        }
    }

    private var dailyCounts: [DailyCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = (0..<14).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
        return days.map { day in
            let count = entries.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
            return DailyCount(date: day, count: count)
        }
    }
}

// Plain value types for the charts — no SwiftData or custom initializers inside
// the chart closure, which keeps type-checking fast.
private struct DailyCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

private struct HabitStat: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let color: Color
}
