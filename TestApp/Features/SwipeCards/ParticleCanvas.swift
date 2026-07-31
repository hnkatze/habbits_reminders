//
//  ParticleCanvas.swift
//  TestApp
//
//  The game loop. `TimelineView(.animation)` ticks once per display frame and
//  hands us the frame's timestamp; `Canvas` draws every particle at the
//  position it should occupy at that instant. No Timer, no RunLoop, no manual
//  frame counter — the loop is declarative.
//

import SwiftUI

struct ParticleCanvas: View {
    let particles: [Particle]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                for particle in particles where particle.isAlive(at: now) {
                    let d = particle.displacement(at: now)
                    let point = CGPoint(x: center.x + d.width, y: center.y + d.height)
                    let rect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)

                    context.opacity = particle.opacity(at: now)
                    context.fill(Circle().path(in: rect), with: .color(particle.color))
                }
            }
        }
        .allowsHitTesting(false)   // sparks never intercept touches
    }
}
