//
//  PlaceReminder.swift
//  TestApp
//
//  A location-based reminder: fires when you ARRIVE at a place. Its content is
//  either a text note or a checklist (isList == true → use `items`).
//

import Foundation
import SwiftData

@Model
final class PlaceReminder {
    var name: String
    var iconName: String
    var colorHex: String
    var createdAt: Date

    var latitude: Double
    var longitude: Double
    var radius: Double
    var notificationID: String = ""

    // Content mode: a free-text note, or a checklist of items.
    var isList: Bool
    var note: String

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.reminder)
    var items: [ChecklistItem] = []

    init(
        name: String,
        iconName: String = "mappin.circle.fill",
        colorHex: String = "#007AFF",
        latitude: Double,
        longitude: Double,
        radius: Double = 150,
        isList: Bool = false,
        note: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.isList = isList
        self.note = note
        self.notificationID = UUID().uuidString
        self.createdAt = createdAt
    }
}

extension PlaceReminder {
    // Short description for the list row.
    var summary: String {
        if isList {
            let done = items.filter(\.isDone).count
            return "\(done)/\(items.count) items"
        }
        return note.isEmpty ? "Note" : note
    }
}
