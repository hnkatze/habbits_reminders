//
//  AddPlaceReminderView.swift
//  TestApp
//
//  Create a location reminder: name, a place (pasted Maps link → coords),
//  radius, and content that is either a text note or a checklist.
//

import SwiftData
import SwiftUI

struct AddPlaceReminderView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var iconName = "cart.fill"
  @State private var colorHex = "#007AFF"

  @State private var mapLink = ""
  @State private var radius: Double = 150
  @State private var resolvedCoordinate: (latitude: Double, longitude: Double)?
  @State private var resolvingLink = false

  @State private var isList = false
  @State private var note = ""
  @State private var newItem = ""
  @State private var draftItems: [DraftItem] = []

  @State private var locationManager = LocationManager()
  @State private var showLimitAlert = false
  @FocusState private var nameFocused: Bool

  private let icons = [
    "cart.fill", "bag.fill", "fork.knife", "pills.fill",
    "fuelpump.fill", "house.fill", "building.2.fill", "mappin.circle.fill",
  ]
  private let colors = ["#007AFF", "#FB0021", "#FF9500", "#34C759", "#AF52DE", "#FF2D55"]

  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty && resolvedCoordinate != nil
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Name") {
          TextField("e.g. Supermarket", text: $name)
            .focused($nameFocused)
        }

        Section("Icon") {
          IconPickerGrid(icons: icons, selection: $iconName, tintHex: colorHex)
        }
        Section("Color") {
          ColorPickerRow(colors: colors, selection: $colorHex)
        }
        Section("Location") { locationSection }

        Section("Content") {
          Picker("Type", selection: $isList) {
            Text("Note").tag(false)
            Text("List").tag(true)
          }
          .pickerStyle(.segmented)

          if isList {
            listEditor
          } else {
            TextField("Note (e.g. buy milk)", text: $note, axis: .vertical)
              .lineLimit(1...4)
          }
        }
      }
      .task(id: mapLink) { await resolveLink() }
      .navigationTitle("New Place Reminder")
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
      .alert("Active places limit reached", isPresented: $showLimitAlert) {
        Button("OK") { dismiss() }
      } message: {
        Text(
          "You can have up to \(PlaceReminder.activeLimit) active places at a time. This one was saved muted — mute another place, then turn it on from its detail screen."
        )
      }
    }
  }

  // How many places currently have their geofence armed.
  private func armedPlaceCount() -> Int {
    let descriptor = FetchDescriptor<PlaceReminder>(predicate: #Predicate { $0.isActive })
    return (try? context.fetchCount(descriptor)) ?? 0
  }

  // MARK: - Location
  @ViewBuilder
  private var locationSection: some View {
    TextField("Paste a Google/Apple Maps link", text: $mapLink, axis: .vertical)
      .lineLimit(1...3)

    if resolvingLink {
      HStack(spacing: 8) {
        ProgressView()
        Text("Resolving link…").font(.caption).foregroundStyle(.secondary)
      }
    } else if let coordinate = resolvedCoordinate {
      HStack {
        Image(systemName: "mappin.circle.fill").foregroundStyle(.green)
        Text(
          "Found \(coordinate.latitude, format: .number.precision(.fractionLength(4))), \(coordinate.longitude, format: .number.precision(.fractionLength(4)))"
        )
        .font(.caption)
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("Radius: \(Int(radius)) m").font(.caption).foregroundStyle(.secondary)
        Slider(value: $radius, in: 100...500, step: 50)
      }
    } else if !mapLink.trimmingCharacters(in: .whitespaces).isEmpty {
      Label(
        "Couldn't read coordinates. Try the full link.",
        systemImage: "exclamationmark.triangle.fill"
      )
      .font(.caption)
      .foregroundStyle(.orange)
    }
  }

  private func resolveLink() async {
    let link = mapLink.trimmingCharacters(in: .whitespaces)
    resolvedCoordinate = nil
    guard link.count > 8 else {
      resolvingLink = false
      return
    }
    try? await Task.sleep(for: .milliseconds(400))
    guard !Task.isCancelled else { return }
    resolvingLink = true
    let result = await MapLinkResolver.coordinates(from: link)
    guard !Task.isCancelled else { return }
    resolvedCoordinate = result
    resolvingLink = false
  }

  // MARK: - List editor
  @ViewBuilder
  private var listEditor: some View {
    ForEach(draftItems) { item in
      Text(item.text)
    }
    .onDelete { draftItems.remove(atOffsets: $0) }

    HStack {
      TextField("Add item", text: $newItem)
      Button("Add") { addItem() }
        .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
    }
  }

  private func addItem() {
    let text = newItem.trimmingCharacters(in: .whitespaces)
    guard !text.isEmpty else { return }
    draftItems.append(DraftItem(text: text))
    newItem = ""
  }

  // MARK: - Save
  private func save() {
    guard let coordinate = resolvedCoordinate else { return }

    // At the limit, save the place muted and don't arm its geofence.
    let atLimit = armedPlaceCount() >= PlaceReminder.activeLimit

    let reminder = PlaceReminder(
      name: name.trimmingCharacters(in: .whitespaces),
      iconName: iconName,
      colorHex: colorHex,
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
      radius: radius,
      isList: isList,
      note: isList ? "" : note.trimmingCharacters(in: .whitespaces)
    )
    reminder.isActive = !atLimit
    context.insert(reminder)

    if isList {
      for draft in draftItems {
        let text = draft.text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { continue }
        context.insert(ChecklistItem(text: text, reminder: reminder))
      }
    }

    guard !atLimit else {
      showLimitAlert = true  // the alert's OK dismisses the sheet
      return
    }

    locationManager.requestAlwaysAuthorization()
    let id = reminder.notificationID
    let reminderName = reminder.name
    let icon = reminder.iconName
    let color = reminder.colorHex
    let lat = coordinate.latitude
    let lng = coordinate.longitude
    let currentRadius = radius
    Task {
      if await NotificationManager.requestAuthorization() {
        NotificationManager.scheduleLocationReminder(
          id: id,
          habitName: reminderName,
          iconName: icon,
          colorHex: color,
          latitude: lat,
          longitude: lng,
          radius: currentRadius
        )
      }
    }

    dismiss()
  }
}

// Draft item held in memory while composing the list (before saving).
private struct DraftItem: Identifiable {
  let id = UUID()
  var text: String
}
