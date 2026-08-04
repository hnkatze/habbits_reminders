//
//  ShareViewController.swift
//  TestAppShareExtension
//
//  Receives a shared place and hands it to the app through the testapp:// URL
//  scheme, which opens the New Place form pre-filled. No App Group needed.
//
//  Robustness rules learned the hard way:
//  1. Arm an UNCONDITIONAL dismissal timeout the moment we appear, so the sheet
//     can never hang — even if the content never resolves.
//  2. Handle every common share payload: Apple Maps map items (which are NOT
//     plain URLs), web URLs, and plain text.
//  3. Open the host app only once the extension is on screen (viewDidAppear).
//

import MapKit
import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
  private var didFinish = false
  private var didOpen = false

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Hard stop: whatever happens below, never keep the sheet up.
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in self?.finish() }
    resolve()
  }

  private func setUpUI() {
    view.backgroundColor = .systemBackground
    let label = UILabel()
    label.text = "Adding to Habits…"
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  private func resolve() {
    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
      let providers = item.attachments, !providers.isEmpty
    else {
      return finish()
    }

    let mapItemType = "com.apple.mapkit.map-item"
    let urlType = UTType.url.identifier
    let textType = UTType.plainText.identifier

    for provider in providers {
      // Apple Maps: an MKMapItem — read the coordinate directly.
      if provider.hasItemConformingToTypeIdentifier(mapItemType) {
        provider.loadItem(forTypeIdentifier: mapItemType, options: nil) { [weak self] value, _ in
          if let mapItem = value as? MKMapItem {
            let c = mapItem.placemark.coordinate
            self?.open(link: "https://maps.apple.com/?ll=\(c.latitude),\(c.longitude)")
          } else {
            self?.finish()
          }
        }
        return
      }
      // Google Maps / Safari: a web URL.
      if provider.hasItemConformingToTypeIdentifier(urlType) {
        provider.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] value, _ in
          self?.open(link: (value as? URL)?.absoluteString ?? (value as? String))
        }
        return
      }
      // Fallback: shared as plain text that contains a link.
      if provider.hasItemConformingToTypeIdentifier(textType) {
        provider.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] value, _ in
          self?.open(link: value as? String)
        }
        return
      }
    }
    finish()
  }

  private func open(link: String?) {
    DispatchQueue.main.async { [weak self] in
      guard let self, !self.didOpen else { return }
      guard let link,
        let encoded = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        let deepLink = URL(string: "testapp://add-place?url=\(encoded)")
      else {
        return self.finish()
      }
      self.didOpen = true
      self.extensionContext?.open(deepLink) { [weak self] _ in self?.finish() }
    }
  }

  private func finish() {
    guard !didFinish else { return }
    didFinish = true
    extensionContext?.completeRequest(returningItems: nil)
  }
}
