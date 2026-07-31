//
//  PlaceReminderRow.swift
//  TestApp
//
//  List row for a location reminder.
//

import SwiftUI

struct PlaceReminderRow: View {
    let reminder: PlaceReminder

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: reminder.iconName)
                .font(.title2)
                .foregroundStyle(Color(hex: reminder.colorHex))
                .frame(width: 40, height: 40)
                .background(Color(hex: reminder.colorHex).opacity(0.15), in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.name)
                    .font(.body.weight(.medium))
                Text(reminder.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: reminder.isList ? "checklist" : "note.text")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
