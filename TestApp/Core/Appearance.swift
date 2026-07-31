//
//  Appearance.swift
//  TestApp
//
//  User-selectable theme. Persisted via @AppStorage as its rawValue, and
//  turned into an optional ColorScheme (`nil` == follow the system).
//

import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    // nil tells SwiftUI to follow the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    // Icon shown in the toolbar toggle for the CURRENT theme.
    var symbolName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    // Cycle order when tapping the toolbar button: system → light → dark → …
    var next: Appearance {
        switch self {
        case .system: .light
        case .light: .dark
        case .dark: .system
        }
    }
}

#if canImport(UIKit)
import UIKit

extension Appearance {
    // UIKit equivalent, used to override the window style directly (see
    // TestAppApp) because `.preferredColorScheme` gets stuck when toggled
    // from a sheet.
    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}
#endif
