//
//  ChecklistItem.swift
//  TestApp
//
//  One line of a PlaceReminder's checklist (e.g. "Milk"). The `reminder`
//  property is the inverse side of the relationship declared in PlaceReminder.
//

import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var text: String
    var isDone: Bool
    var reminder: PlaceReminder?

    init(text: String, isDone: Bool = false, reminder: PlaceReminder? = nil) {
        self.text = text
        self.isDone = isDone
        self.reminder = reminder
    }
}
