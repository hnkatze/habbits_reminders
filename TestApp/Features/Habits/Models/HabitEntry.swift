//
//  HabitEntry.swift
//  TestApp
//
//  One completion record: "this habit was done on this date". The `habit`
//  property is the inverse side of the relationship declared in Habit.swift.
//

import Foundation
import SwiftData

@Model
final class HabitEntry {
    var date: Date
    var habit: Habit?

    init(date: Date = .now, habit: Habit? = nil) {
        self.date = date
        self.habit = habit
    }
}
