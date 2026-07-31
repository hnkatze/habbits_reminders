//
//  SwipeDirection.swift
//  TestApp
//
//  Domain model for the card swipe: the two directions a card can be
//  thrown, plus small values derived from each case.
//

import SwiftUI

enum SwipeDirection {
    case left
    case right

    // Off-screen destination the card flies to when swiped away.
    //
    // This is a `switch` used as an EXPRESSION: every branch produces a
    // value and the whole switch evaluates to it. The compiler also checks
    // it is EXHAUSTIVE — add a `case up` and this stops compiling until you
    // handle it. That is Swift's enums working for you, not against you.
    var flyAwayOffset: CGSize {
        switch self {
        case .left:  CGSize(width: -1000, height: 0)
        case .right: CGSize(width:  1000, height: 0)
        }
    }

    // Label + color of the stamp shown while dragging toward this direction.
    var badge: (text: String, color: Color) {
        switch self {
        case .left:  ("NOPE", .red)
        case .right: ("LIKE", .green)
        }
    }
}
