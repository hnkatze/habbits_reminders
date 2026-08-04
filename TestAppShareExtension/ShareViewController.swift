//
//  ShareViewController.swift
//  TestAppShareExtension
//
//  Receives a shared Maps link and hands it to the app through the testapp://
//  URL scheme, which opens the New Place form pre-filled. No App Group needed.
//
//  Two things matter for reliability:
//  1. Open the host app only AFTER the extension is on screen (viewDidAppear) —
//     opening earlier is silently dropped by iOS.
//  2. Always completeRequest, even if `open`'s completion never fires, so the
//     sheet can never hang.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
  private var pendingLink: String?
  private var didFinish = false

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpUI()
    extractSharedLink()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    tryOpen()
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

  private func extractSharedLink() {
    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
      let provider = item.attachments?.first
    else {
      return finish()
    }

    let urlType = UTType.url.identifier
    let textType = UTType.plainText.identifier
    let handler: (NSSecureCoding?, Error?) -> Void = { [weak self] value, _ in
      let link = (value as? URL)?.absoluteString ?? (value as? String)
      DispatchQueue.main.async {
        self?.pendingLink = link
        self?.tryOpen()
      }
    }

    if provider.hasItemConformingToTypeIdentifier(urlType) {
      provider.loadItem(forTypeIdentifier: urlType, options: nil, completionHandler: handler)
    } else if provider.hasItemConformingToTypeIdentifier(textType) {
      provider.loadItem(forTypeIdentifier: textType, options: nil, completionHandler: handler)
    } else {
      finish()
    }
  }

  // Fires from both viewDidAppear and the load completion; proceeds only once the
  // link is ready AND the extension is actually on screen.
  private func tryOpen() {
    guard isViewLoaded, view.window != nil, let link = pendingLink else { return }
    pendingLink = nil

    guard let encoded = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
      let deepLink = URL(string: "testapp://add-place?url=\(encoded)")
    else {
      return finish()
    }

    extensionContext?.open(deepLink) { [weak self] _ in
      self?.finish()
    }
    // Safety net: never leave the sheet hanging if the completion doesn't fire.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      self?.finish()
    }
  }

  private func finish() {
    guard !didFinish else { return }
    didFinish = true
    extensionContext?.completeRequest(returningItems: nil)
  }
}
