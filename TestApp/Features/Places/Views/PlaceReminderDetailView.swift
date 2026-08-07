//
//  PlaceReminderDetailView.swift
//  TestApp
//
//  Detail for a location reminder: a hero with live distance and status, a
//  toggle to arm/mute the arrival geofence, the tracking Live Activity, and the
//  note or editable checklist.
//

import SwiftData
import SwiftUI

struct PlaceReminderDetailView: View {
  @Bindable var reminder: PlaceReminder
  @Environment(\.modelContext) private var context
  @Environment(LocationManager.self) private var locationManager
  @Environment(LiveActivityManager.self) private var liveActivity

  @State private var newItem = ""
  @State private var showLimitAlert = false

  private var color: Color { Color(hex: reminder.colorHex) }

  var body: some View {
    List {
      hero
      statusSection
      parkingSection
      trackingSection
      contentSection
      detailsSection
    }
    .navigationTitle(reminder.name)
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        if let shareURL {
          ShareLink(item: shareURL) {
            Image(systemName: "square.and.arrow.up")
          }
        }
      }
    }
    .alert("Active places limit reached", isPresented: $showLimitAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(
        "You can have up to \(PlaceReminder.activeLimit) active places at a time. Mute another place first, then turn this one on."
      )
    }
  }

  private var shareURL: URL? {
    let query = reminder.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    return URL(
      string: "https://maps.apple.com/?ll=\(reminder.latitude),\(reminder.longitude)&q=\(query)")
  }

  // MARK: - Hero
  private var hero: some View {
    Section {
      VStack(spacing: 12) {
        Image(systemName: reminder.iconName)
          .font(.system(size: 34, weight: .semibold))
          .foregroundStyle(.white)
          .frame(width: 78, height: 78)
          .background(color.gradient, in: .rect(cornerRadius: 20, style: .continuous))
          .shadow(color: color.opacity(0.4), radius: 8, y: 4)

        Text(reminder.name)
          .font(.title2.weight(.bold))
          .multilineTextAlignment(.center)

        statusPill
        distanceView
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 10)
      .listRowBackground(Color.clear)
    }
  }

  private var statusPill: some View {
    Label(
      reminder.isActive ? "Active" : "Muted",
      systemImage: reminder.isActive ? "dot.radiowaves.left.and.right" : "bell.slash.fill"
    )
    .font(.caption.weight(.semibold))
    .foregroundStyle(reminder.isActive ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(
      reminder.isActive ? AnyShapeStyle(Color.green.opacity(0.15)) : AnyShapeStyle(.quaternary),
      in: .capsule
    )
    .animation(.snappy, value: reminder.isActive)
  }

  @ViewBuilder
  private var distanceView: some View {
    if let location = locationManager.currentLocation {
      Label(
        "\(DistanceFormatter.string(forMeters: reminder.distance(from: location))) away",
        systemImage: "location.fill"
      )
      .font(.subheadline.weight(.medium))
      .foregroundStyle(.secondary)
      .contentTransition(.numericText())
    } else {
      HStack(spacing: 6) {
        ProgressView().controlSize(.small)
        Text("Locating…")
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
    }
  }

  // MARK: - Status (arm / mute the arrival geofence)
  private var statusSection: some View {
    Section {
      Toggle(isOn: $reminder.isActive) {
        Label("Arrival reminder", systemImage: "bell.badge")
      }
      .tint(color)
      .onChange(of: reminder.isActive) { _, active in
        updateGeofence(active: active)
      }
    } footer: {
      Text(
        reminder.isActive
          ? "You'll be reminded when you arrive here."
          : "Muted — no reminder at this place. Turn it back on anytime."
      )
    }
  }

  // MARK: - Parking (spot + meter countdown)
  // Non-nil string binding so an empty field clears the stored optional.
  private var parkingSpotBinding: Binding<String> {
    Binding(
      get: { reminder.parkingSpot ?? "" },
      set: { reminder.parkingSpot = $0.isEmpty ? nil : $0 }
    )
  }

  private var parkingExpiryBinding: Binding<Date> {
    Binding(
      get: { reminder.parkingExpiresAt ?? .now.addingTimeInterval(3600) },
      set: { reminder.parkingExpiresAt = $0 }
    )
  }

  @ViewBuilder
  private var parkingSection: some View {
    if reminder.kind == .parking {
      Section("Parking") {
        TextField("Spot (e.g. B-24)", text: parkingSpotBinding)

        if let expiry = reminder.parkingExpiresAt {
          LabeledContent("Meter") {
            if expiry > .now {
              Text(timerInterval: Date.now...expiry, countsDown: true)
                .monospacedDigit()
                .foregroundStyle(color)
            } else {
              Text("Expired").foregroundStyle(.red)
            }
          }
          DatePicker(
            "Expires",
            selection: parkingExpiryBinding,
            in: Date.now...,
            displayedComponents: [.date, .hourAndMinute]
          )
          Button(role: .destructive) {
            reminder.parkingExpiresAt = nil
          } label: {
            Label("Clear meter", systemImage: "timer.slash")
          }
        } else {
          Button {
            reminder.parkingExpiresAt = .now.addingTimeInterval(3600)
          } label: {
            Label("Set meter time", systemImage: "timer")
          }
        }
      }
    }
  }

  // MARK: - Tracking Live Activity
  @ViewBuilder
  private var trackingSection: some View {
    Section {
      if liveActivity.isTracking(reminder) {
        Button(role: .destructive) {
          Task { await liveActivity.stop() }
          locationManager.stopBackgroundUpdates()
        } label: {
          Label("Stop Live Activity", systemImage: "stop.circle.fill")
        }
      } else {
        Button {
          locationManager.requestAlwaysAuthorization()
          locationManager.startBackgroundUpdates()
          liveActivity.start(tracking: reminder, from: locationManager.currentLocation)
        } label: {
          Label("Track with Live Activity", systemImage: "location.circle.fill")
        }
        .disabled(liveActivity.isTracking)
      }
    } footer: {
      if liveActivity.isTracking && !liveActivity.isTracking(reminder) {
        Text("Stop the current tracking to follow this place instead.")
      } else {
        Text(
          "Shows live distance on the Lock Screen and Dynamic Island while you head there. Uses background location only while active."
        )
      }
    }
  }

  // MARK: - Content (note or checklist)
  @ViewBuilder
  private var contentSection: some View {
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

  // MARK: - Details
  private var detailsSection: some View {
    Section("Details") {
      LabeledContent("Coordinates") {
        Text(
          "\(reminder.latitude, format: .number.precision(.fractionLength(4))), \(reminder.longitude, format: .number.precision(.fractionLength(4)))"
        )
        .foregroundStyle(.secondary)
      }
      LabeledContent("Radius", value: "\(Int(reminder.radius)) m")
      LabeledContent("Added") {
        Text(reminder.createdAt, format: .dateTime.month().day().year())
          .foregroundStyle(.secondary)
      }
    }
  }

  // MARK: - Geofence arm / mute
  private func updateGeofence(active: Bool) {
    if active {
      // Enforce the active-places cap. Count OTHER armed places so the check is
      // robust regardless of this reminder's just-flipped value.
      let selfID = reminder.notificationID
      let descriptor = FetchDescriptor<PlaceReminder>(
        predicate: #Predicate { $0.isActive && $0.notificationID != selfID })
      let others = (try? context.fetchCount(descriptor)) ?? 0
      if others >= PlaceReminder.activeLimit {
        reminder.isActive = false  // revert the toggle
        showLimitAlert = true
        return
      }

      locationManager.requestAlwaysAuthorization()
      let id = reminder.notificationID
      let name = reminder.name
      let icon = reminder.iconName
      let color = reminder.colorHex
      let lat = reminder.latitude
      let lng = reminder.longitude
      let radius = reminder.radius
      Task {
        if await NotificationManager.requestAuthorization() {
          NotificationManager.scheduleLocationReminder(
            id: id, habitName: name, iconName: icon, colorHex: color,
            latitude: lat, longitude: lng, radius: radius)
        }
      }
    } else {
      NotificationManager.cancelLocationReminder(id: reminder.notificationID)
    }
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
