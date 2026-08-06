//
//  NotificationViewController.swift
//  TestAppNotificationContent
//
//  Custom UI shown when the user EXPANDS a habit/place notification (long-press
//  or pull down on the lock screen). The collapsed banner stays the system's —
//  iOS owns that. This is the one surface a notification lets us design, and
//  it's near-static by design (Apple disallows free-form animation here).
//
//  Self-contained: this target can't see the app's SwiftData store (no App
//  Group on a free account), so the card is built purely from the notification
//  content + its userInfo (iconName / colorHex / category). Enough for a big,
//  branded card.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

  private let iconContainer = UIView()
  private let iconView = UIImageView()
  private let tagLabel = PaddingLabel()
  private let titleLabel = UILabel()
  private let bodyLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    buildLayout()
  }

  // MARK: - Layout

  private func buildLayout() {
    view.backgroundColor = .clear

    iconContainer.translatesAutoresizingMaskIntoConstraints = false
    iconContainer.layer.cornerRadius = 16
    iconContainer.layer.cornerCurve = .continuous

    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.tintColor = .white
    iconView.contentMode = .center
    iconContainer.addSubview(iconView)

    tagLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    tagLabel.textColor = .white
    tagLabel.textInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
    tagLabel.layer.cornerRadius = 9
    tagLabel.layer.masksToBounds = true

    titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 2

    bodyLabel.font = .systemFont(ofSize: 15, weight: .regular)
    bodyLabel.textColor = .secondaryLabel
    bodyLabel.numberOfLines = 0

    // Tag hugs its content; a trailing spacer keeps it left-aligned.
    let tagRow = UIStackView(arrangedSubviews: [tagLabel, UIView()])
    tagRow.axis = .horizontal

    let textStack = UIStackView(arrangedSubviews: [tagRow, titleLabel, bodyLabel])
    textStack.axis = .vertical
    textStack.spacing = 6
    textStack.alignment = .fill

    let mainStack = UIStackView(arrangedSubviews: [iconContainer, textStack])
    mainStack.axis = .horizontal
    mainStack.spacing = 14
    mainStack.alignment = .top
    mainStack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(mainStack)

    NSLayoutConstraint.activate([
      iconContainer.widthAnchor.constraint(equalToConstant: 60),
      iconContainer.heightAnchor.constraint(equalToConstant: 60),
      iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
      iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

      mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
    ])
  }

  // MARK: - UNNotificationContentExtension

  func didReceive(_ notification: UNNotification) {
    let content = notification.request.content
    let info = content.userInfo

    titleLabel.text = content.title
    bodyLabel.text = content.body

    let iconName = info["iconName"] as? String ?? "bell.fill"
    let colorHex = info["colorHex"] as? String ?? "#FB0021"
    let color = UIColor(hex: colorHex)

    iconContainer.backgroundColor = color
    let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold)
    iconView.image = UIImage(systemName: iconName, withConfiguration: config)

    let isPlace = content.categoryIdentifier == "place-reminder"
    tagLabel.text = isPlace ? "PLACE" : "HABIT"
    tagLabel.backgroundColor = color
  }
}

// A UILabel with configurable padding — for the little category tag.
final class PaddingLabel: UILabel {
  var textInsets: UIEdgeInsets = .zero

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: textInsets))
  }

  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(
      width: size.width + textInsets.left + textInsets.right,
      height: size.height + textInsets.top + textInsets.bottom)
  }
}

// Build a UIColor from "#RRGGBB" — mirrors the app's Color(hex:) so this target
// stays self-contained.
extension UIColor {
  fileprivate convenience init(hex: String) {
    let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var value: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&value)
    self.init(
      red: CGFloat((value >> 16) & 0xFF) / 255,
      green: CGFloat((value >> 8) & 0xFF) / 255,
      blue: CGFloat(value & 0xFF) / 255,
      alpha: 1)
  }
}
