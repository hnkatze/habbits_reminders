//
//  PlaceReminderDetailView.swift
//  TestApp
//
//  Detail for a location reminder: shows the place, and either the note or an
//  editable checklist (tap to toggle, swipe to delete, add new items).
//

import SwiftUI
import SwiftData

struct PlaceReminderDetailView: View {
    @Bindable var reminder: PlaceReminder
    @Environment(\.modelContext) private var context

    @State private var newItem = ""

    var body: some View {
        List {
            Section("Place") {
                Label(reminder.name, systemImage: reminder.iconName)
                Label(
                    "\(reminder.latitude, format: .number.precision(.fractionLength(4))), \(reminder.longitude, format: .number.precision(.fractionLength(4)))",
                    systemImage: "mappin.and.ellipse"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Text("Radius: \(Int(reminder.radius)) m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if reminder.isList {
                Section("Checklist") {
                    ForEach(reminder.items) { item in
                        Button {
                            item.isDone.toggle()
                        } label: {
                            HStack {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isDone ? .green : .secondary)
                                Text(item.text)
                                    .strikethrough(item.isDone)
                                    .foregroundStyle(item.isDone ? .secondary : .primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteItems)

                    HStack {
                        TextField("Add item", text: $newItem)
                        Button("Add") { addItem() }
                            .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            } else {
                Section("Note") {
                    Text(reminder.note.isEmpty ? "—" : reminder.note)
                }
            }
        }
        .navigationTitle(reminder.name)
    }

    private func addItem() {
        let text = newItem.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        context.insert(ChecklistItem(text: text, reminder: reminder))
        newItem = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        let sorted = reminder.items
        for index in offsets {
            context.delete(sorted[index])
        }
    }
}
