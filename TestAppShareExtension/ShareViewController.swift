//
//  ShareViewController.swift
//  TestAppShareExtension
//
//  Receives a shared Maps link from the system share sheet and hands it to the
//  app through the testapp:// URL scheme, which opens the New Place form
//  pre-filled. No App Group needed — nothing is written here, we just pass the
//  URL along and let the app resolve the coordinate with MapLinkResolver.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    extractSharedLink()
  }

  private func extractSharedLink() {
    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
      let provider = item.attachments?.first
    else {
      return finish()
    }

    let urlType = UTType.url.identifier
    let textType = UTType.plainText.identifier

    if provider.hasItemConformingToTypeIdentifier(urlType) {
      provider.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] value, _ in
        let link = (value as? URL)?.absoluteString ?? (value as? String)
        DispatchQueue.main.async { self?.handOff(link) }
      }
    } else if provider.hasItemConformingToTypeIdentifier(textType) {
      provider.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] value, _ in
        DispatchQueue.main.async { self?.handOff(value as? String) }
      }
    } else {
      finish()
    }
  }

  private func handOff(_ link: String?) {
    guard let link,
      let encoded = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
      let deepLink = URL(string: "testapp://add-place?url=\(encoded)")
    else {
      return finish()
    }
    // A share extension opens its host app through the extension context.
    extensionContext?.open(deepLink) { [weak self] _ in
      self?.finish()
    }
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: nil)
  }
}
