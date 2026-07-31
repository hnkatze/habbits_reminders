//
//  Particle.swift
//  TestApp
//
//  A single particle in the burst. It stores no live position — instead it
//  DERIVES where it is from the elapsed time. That is the key idea of a
//  time-based simulation: given a clock, every particle is a pure function of
//  "how old am I?", so we never mutate state frame by frame.
//

import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    let velocity: CGVector        // points per second
    let color: Color
    let birth: Date
    let lifespan: TimeInterval

    private static let gravity: Double = 500   // points per second^2, pulling down

    func age(at now: Date) -> TimeInterval { now.timeIntervalSince(birth) }

    func isAlive(at now: Date) -> Bool { age(at: now) < lifespan }

    // Displacement from the emission center: constant velocity + gravity.
    // Classic physics: x = v·t,  y = v·t + ½·g·t²
    func displacement(at now: Date) -> CGSize {
        let t = age(at: now)
        return CGSize(
            width: velocity.dx * t,
            height: velocity.dy * t + 0.5 * Self.gravity * t * t
        )
    }

    func opacity(at now: Date) -> Double {
        max(0, 1 - age(at: now) / lifespan)
    }
}

extension Particle {
    // Emit a fan of particles pushed toward the swipe direction, with an
    // upward kick and random spread so it looks like a spark burst.
    static func burst(direction: SwipeDirection, count: Int = 30) -> [Particle] {
        let now = Date()
        let palette: [Color] = [.yellow, .orange, .pink, .cyan, .white]
        let horizontalSign: CGFloat = direction == .right ? 1 : -1

        return (0..<count).map { _ in
            let angle = Double.random(in: -0.9...0.9)          // spread, radians
            let speed = CGFloat.random(in: 220...520)
            let dx = horizontalSign * speed * CGFloat(cos(angle))
            let dy = speed * CGFloat(sin(angle)) - CGFloat.random(in: 120...320)  // upward

            return Particle(
                velocity: CGVector(dx: dx, dy: dy),
                color: palette.randomElement() ?? .white,
                birth: now,
                lifespan: Double.random(in: 0.6...1.1)
            )
        }
    }
}
