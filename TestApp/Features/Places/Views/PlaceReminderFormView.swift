//
//  PlaceReminderFormView.swift
//  TestApp
//
//  Create or edit a location reminder. Passing `editing:` switches modes:
//  - Create: a guided flow — pick a type, set a location, and the rest of the
//    fields (name, radius, content, appearance) reveal once a place is chosen.
//  - Edit: every section is shown at once (a direct form). The checklist itself
//    is managed from the detail screen, so this form never touches items in edit
//    mode. Saving an edit re-arms the arrival geofence with the fresh data.
//

import CoreLocation
import SwiftData
import SwiftUI

struct PlaceReminderFormView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss

  // nil → create a new place; non-nil → edit this one.
  private let editing: PlaceReminder?

  @State private var name: String
  @State private var kind: PlaceKind
  @State private var iconName: String
  @State private var colorHex: String

  @State private var coordinate: CLLocationCoordinate2D?
  @State private var radius: Double

  // Parking-only extras.
  @State private var parkingSpot: String
  @State private var setParkingMeter: Bool
  @State private var parkingExpiry: Date

  // Search-by-name state.
  @State private var searchQuery = ""
  @State private var searchResults: [PlaceSearchResult] = []
  @State private var searching = false

  // Paste-a-link state (kept as a fallback).
  @State private var mapLink = ""
  @State private var resolvingLink = false

  // Content.
  @State private var isList: Bool
  @State private var note: String
  @State private var newItem = ""
  @State private var draftItems: [DraftItem]

  @State private var locationManager = LocationManager()
  @State private var awaitingCurrentLocation = false
  @State private var showLimitAlert = false

  private let icons = [
    "cart.fill", "bag.fill", "fork.knife", "pills.fill",
    "fuelpump.fill", "house.fill", "building.2.fill", "mappin.circle.fill",
    "parkingsign.circle.fill", "dumbbell.fill", "airplane", "ticket.fill",
  ]
  private let colors = ["#007AFF", "#FB0021", "#FF9500", "#34C759", "#AF52DE", "#FF2D55"]

  init(editing: PlaceReminder? = nil) {
    self.editing = editing
    _name = State(initialValue: editing?.name ?? "")
    _kind = State(initialValue: editing?.kind ?? .generic)
    _iconName = State(initialValue: editing?.iconName ?? "cart.fill")
    _colorHex = State(initialValue: editing?.colorHex ?? "#007AFF")
    _coordinate = State(initialValue: editing.map(\.coordinate))
    _radius = State(initialValue: editing?.radius ?? 150)
    _parkingSpot = State(initialValue: editing?.parkingSpot ?? "")
    _setParkingMeter = State(initialValue: editing?.parkingExpiresAt != nil)
    _parkingExpiry = State(
      initialValue: editing?.parkingExpiresAt ?? Date.now.addingTimeInterval(3600))
    _isList = State(initialValue: editing?.isList ?? false)
    _note = State(initialValue: editing?.note ?? "")
    _draftItems = State(initialValue: [])
  }

  private var isEditing: Bool { editing != nil }

  // In create mode the tail sections appear only after a place is chosen; in
  // edit mode everything is shown at once.
  private var showsDetails: Bool { isEditing || coordinate != nil }

  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty && coordinate != nil
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Type") {
          Picker("Type", selection: $kind) {
            ForEach(PlaceKind.allCases) { kind in
              Label(kind.label, systemImage: kind.defaultIcon).tag(kind)
            }
          }
        }

        if kind == .parking {
          Section("Parking") { parkingSection }
        }

        Section("Location") { locationSection }

        if showsDetails {
          Section("Name") {
            TextField("e.g. Supermarket", text: $name)
          }

          Section("Content") { contentSection }

          Section {
            DisclosureGroup("Appearance") {
              IconPickerGrid(icons: icons, selection: $iconName, tintHex: colorHex)
              ColorPickerRow(colors: colors, selection: $colorHex)
            }
          }
        }
      }
      .task(id: mapLink) { await resolveLink() }
      .task(id: searchQuery) { await runSearch() }
      .navigationTitle(isEditing ? "Edit Place" : "New Place Reminder")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(isEditing ? "Done" : "Save") { save() }
            .disabled(!isValid)
        }
      }
      .onChange(of: kind) { applyKindPreset() }
      .onChange(of: coordinate?.latitude) { autofillNameIfNeeded() }
      .onChange(of: locationManager.currentLocation?.coordinate.latitude) {
        adoptCurrentLocationIfAwaited()
      }
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
    HStack {
      Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
      TextField("Search a place", text: $searchQuery)
        .textInputAutocapitalization(.words)
      if searching { ProgressView() }
    }

    ForEach(searchResults) { result in
      Button {
        select(result)
      } label: {
        VStack(alignment: .leading, spacing: 2) {
          Text(result.name).foregroundStyle(.primary)
          if !result.subtitle.isEmpty {
            Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
          }
        }
      }
    }

    Button {
      useCurrentLocation()
    } label: {
      Label("Use my location", systemImage: "location.fill")
    }

    LocationPickerMap(coordinate: $coordinate, radius: radius, tintHex: colorHex)
      .listRowInsets(EdgeInsets())

    if let coordinate {
      HStack {
        Image(systemName: "mappin.circle.fill").foregroundStyle(.green)
        Text(
          "\(coordinate.latitude, format: .number.precision(.fractionLength(4))), \(coordinate.longitude, format: .number.precision(.fractionLength(4)))"
        )
        .font(.caption)
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("Radius: \(Int(radius)) m").font(.caption).foregroundStyle(.secondary)
        Slider(value: $radius, in: 100...500, step: 50)
      }
    }

    DisclosureGroup("Or paste a Maps link") { mapLinkField }
  }

  @ViewBuilder
  private var mapLinkField: some View {
    TextField("Paste a Google/Apple Maps link", text: $mapLink, axis: .vertical)
      .lineLimit(1...3)

    if resolvingLink {
      HStack(spacing: 8) {
        ProgressView()
        Text("Resolving link…").font(.caption).foregroundStyle(.secondary)
      }
    } else if coordinate == nil, !mapLink.trimmingCharacters(in: .whitespaces).isEmpty {
      Label(
        "Couldn't read coordinates. Try the full link.",
        systemImage: "exclamationmark.triangle.fill"
      )
      .font(.caption)
      .foregroundStyle(.orange)
    }
  }

  // MARK: - Parking
  @ViewBuilder
  private var parkingSection: some View {
    TextField("Spot (e.g. B-24)", text: $parkingSpot)
    Toggle("Set meter time", isOn: $setParkingMeter)
    if setParkingMeter {
      DatePicker(
        "Expires",
        selection: $parkingExpiry,
        in: Date.now...,
        displayedComponents: [.date, .hourAndMinute]
      )
    }
  }

  // MARK: - Content
  @ViewBuilder
  private var contentSection: some View {
    Picker("Type", selection: $isList) {
      Text("Note").tag(false)
      Text("List").tag(true)
    }
    .pickerStyle(.segmented)

    if isList {
      if isEditing {
        Text("Manage the checklist from the place screen.")
          .font(.caption).foregroundStyle(.secondary)
      } else {
        listEditor
      }
    } else {
      TextField("Note (e.g. buy milk)", text: $note, axis: .vertical)
        .lineLimit(1...4)
    }
  }

  // Applying a kind presets the icon, tint, and content mode to sensible
  // defaults for that template — the user can still override any of them after.
  private func applyKindPreset() {
    iconName = kind.defaultIcon
    colorHex = kind.defaultColorHex
    isList = kind.prefersList
  }

  // MARK: - Place selection
  private func select(_ result: PlaceSearchResult) {
    // Fill the name from the result before moving the pin, so the reverse-geocode
    // autofill (which only fires on an empty name) leaves this better label alone.
    if name.trimmingCharacters(in: .whitespaces).isEmpty {
      name = result.name
    }
    coordinate = result.coordinate
    searchResults = []
    searchQuery = ""
  }

  private func runSearch() async {
    let query = searchQuery.trimmingCharacters(in: .whitespaces)
    guard query.count > 1 else {
      searching = false
      searchResults = []
      return
    }
    try? await Task.sleep(for: .milliseconds(350))
    guard !Task.isCancelled else { return }
    searching = true
    let center = coordinate ?? locationManager.currentLocation?.coordinate
    let results = await PlaceSearchService.search(query, near: center)
    guard !Task.isCancelled else { return }
    searchResults = results
    searching = false
  }

  private func useCurrentLocation() {
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
    if let location = locationManager.currentLocation {
      coordinate = location.coordinate
    } else {
      awaitingCurrentLocation = true
    }
  }

  private func adoptCurrentLocationIfAwaited() {
    guard awaitingCurrentLocation, let location = locationManager.currentLocation else { return }
    awaitingCurrentLocation = false
    coordinate = location.coordinate
  }

  // Reverse-geocode a freshly picked coordinate into a name — but only when the
  // user hasn't typed one, and only if it's still empty when the lookup returns.
  private func autofillNameIfNeeded() {
    guard let coordinate, name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
    Task {
      guard let resolved = await PlaceSearchService.name(for: coordinate) else { return }
      if name.trimmingCharacters(in: .whitespaces).isEmpty {
        name = resolved
      }
    }
  }

  private func resolveLink() async {
    let link = mapLink.trimmingCharacters(in: .whitespaces)
    guard link.count > 8 else {
      resolvingLink = false
      return
    }
    try? await Task.sleep(for: .milliseconds(400))
    guard !Task.isCancelled else { return }
    resolvingLink = true
    let result = await MapLinkResolver.coordinates(from: link)
    guard !Task.isCancelled else { return }
    if let result {
      coordinate = CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude)
    }
    resolvingLink = false
  }

  // MARK: - List editor (create mode only)
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
    guard let coordinate else { return }
    if let place = editing {
      applyEdits(to: place, coordinate: coordinate)
    } else {
      createNew(coordinate: coordinate)
    }
  }

  private func applyEdits(to place: PlaceReminder, coordinate: CLLocationCoordinate2D) {
    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    let isParking = kind == .parking
    let spot = parkingSpot.trimmingCharacters(in: .whitespaces)

    place.name = trimmedName
    place.kind = kind
    place.iconName = iconName
    place.colorHex = colorHex
    place.latitude = coordinate.latitude
    place.longitude = coordinate.longitude
    place.radius = radius
    place.isList = isList
    if !isList {
      place.note = note.trimmingCharacters(in: .whitespaces)
    }
    place.parkingSpot = isParking && !spot.isEmpty ? spot : nil
    place.parkingExpiresAt = isParking && setParkingMeter ? parkingExpiry : nil

    // The arrival notification carries the name/icon/color/coords, so re-arm it
    // with the fresh data whenever the place is active.
    if place.isActive {
      NotificationManager.cancelLocationReminder(id: place.notificationID)
      locationManager.requestAlwaysAuthorization()
      let id = place.notificationID
      let name = trimmedName
      let icon = iconName
      let color = colorHex
      let lat = coordinate.latitude
      let lng = coordinate.longitude
      let currentRadius = radius
      Task {
        if await NotificationManager.requestAuthorization() {
          NotificationManager.scheduleLocationReminder(
            id: id, habitName: name, iconName: icon, colorHex: color,
            latitude: lat, longitude: lng, radius: currentRadius)
        }
      }
    }

    dismiss()
  }

  private func createNew(coordinate: CLLocationCoordinate2D) {
    // At the limit, save the place muted and don't arm its geofence.
    let atLimit = armedPlaceCount() >= PlaceReminder.activeLimit
    let isParking = kind == .parking
    let spot = parkingSpot.trimmingCharacters(in: .whitespaces)

    let reminder = PlaceReminder(
      name: name.trimmingCharacters(in: .whitespaces),
      iconName: iconName,
      colorHex: colorHex,
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
      radius: radius,
      kind: kind,
      isList: isList,
      note: isList ? "" : note.trimmingCharacters(in: .whitespaces),
      parkingSpot: isParking && !spot.isEmpty ? spot : nil,
      parkingExpiresAt: isParking && setParkingMeter ? parkingExpiry : nil
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
