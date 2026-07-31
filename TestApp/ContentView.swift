//
//  ContentView.swift
//  TestApp
//
//  Created by Hector  on 31/7/26.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Animation States
    @State private var runnerBouncing = false
    @State private var sunRotating = false
    @State private var heartPulsing = false
    @State private var starsAppeared = false
    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var badgesAppeared = false
    @State private var imageAppeared = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // ── Background gradient ──────────────────────────────────
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.25),
                    Color(red: 0.15, green: 0.05, blue: 0.40),
                    Color(red: 0.30, green: 0.10, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // ── Floating star particles ──────────────────────────────
            FloatingStarsView(appeared: starsAppeared)

            // ── Main content ─────────────────────────────────────────
            VStack(spacing: 28) {

                Spacer()

                // Hero icon cluster
                heroIconCluster

                // Title block
                titleBlock

                // Badge row
                badgeRow

                // Custom image
                heroImage

                // CTA label
                ctaLabel

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Hero Icon Cluster
    private var heroIconCluster: some View {
        ZStack {
            // Glowing circle backdrop
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.purple.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 18)

            // Orbiting sun
            Image(systemName: "sun.max.fill")
                .font(.system(size: 30))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                )
                .symbolEffect(.rotate, options: .repeating)
                .offset(x: sunRotating ? 70 : 70, y: -55)
                .rotationEffect(.degrees(sunRotating ? 360 : 0))
                .animation(
                    .linear(duration: 8).repeatForever(autoreverses: false),
                    value: sunRotating
                )

            // Main runner icon
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, options: .repeating)
                .shadow(color: .purple.opacity(0.6), radius: 20, x: 0, y: 10)
                .scaleEffect(runnerBouncing ? 1.0 : 0.5)
                .opacity(runnerBouncing ? 1 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.2), value: runnerBouncing)

            // Pulsing heart
            Image(systemName: "heart.fill")
                .font(.system(size: 22))
                .foregroundStyle(.pink)
                .symbolEffect(.pulse, options: .repeating)
                .offset(x: -72, y: 40)
                .scaleEffect(heartPulsing ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.8), value: heartPulsing)

            // Lightning bolt
            Image(systemName: "bolt.fill")
                .font(.system(size: 22))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                )
                .symbolEffect(.variableColor.iterative, options: .repeating)
                .offset(x: 72, y: 42)
                .scaleEffect(heartPulsing ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.0), value: heartPulsing)
        }
    }

    // MARK: - Title Block
    private var titleBlock: some View {
        VStack(spacing: 10) {
            Text("Have a great day!")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .shadow(color: .cyan.opacity(0.4), radius: 8)
                .scaleEffect(titleAppeared ? 1.0 : 0.7)
                .opacity(titleAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.5), value: titleAppeared)

            Text("CIT · It's a beautiful day ✨")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.80))
                .multilineTextAlignment(.center)
                .opacity(subtitleAppeared ? 1 : 0)
                .offset(y: subtitleAppeared ? 0 : 12)
                .animation(.easeOut(duration: 0.5).delay(0.85), value: subtitleAppeared)
        }
    }

    // MARK: - Badge Row
    private var badgeRow: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                BadgeView(symbol: "flame.fill",
                          label: "Motivated",
                          colors: [.orange, .red])

                BadgeView(symbol: "leaf.fill",
                          label: "Healthy",
                          colors: [.green, .teal])

                BadgeView(symbol: "star.fill",
                          label: "Winning",
                          colors: [.yellow, .orange])
            }
        }
        .scaleEffect(badgesAppeared ? 1.0 : 0.8)
        .opacity(badgesAppeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.65).delay(1.1), value: badgesAppeared)
    }

    // MARK: - Hero Image
    private var heroImage: some View {
        Image(.zerotow)
            .resizable()
            .scaledToFit()
            .frame(width: 220, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .purple.opacity(0.5), radius: 24, x: 0, y: 12)
            .scaleEffect(imageAppeared ? 1.0 : 0.85)
            .opacity(imageAppeared ? 1 : 0)
            .animation(.spring(response: 0.65, dampingFraction: 0.7).delay(1.35), value: imageAppeared)
    }

    // MARK: - CTA Label
    private var ctaLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .symbolEffect(.bounce, options: .repeating)
            Text("Tap anywhere to continue")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive(), in: .capsule)
        .opacity(badgesAppeared ? 1 : 0)
        .animation(.easeIn(duration: 0.4).delay(1.6), value: badgesAppeared)
    }

    // MARK: - Animation Trigger
    private func startAnimations() {
        runnerBouncing  = true
        heartPulsing    = true
        sunRotating     = true
        starsAppeared   = true
        titleAppeared   = true
        subtitleAppeared = true
        badgesAppeared  = true
        imageAppeared   = true
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let symbol: String
    let label: String
    let colors: [Color]

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                )
                .symbolEffect(.pulse, options: .repeating)

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(width: 78, height: 72)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}

// MARK: - Floating Stars
struct FloatingStarsView: View {
    let appeared: Bool

    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let delay: Double
    }

    private let stars: [Star] = (0..<28).map { i in
        Star(
            id: i,
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 2...5),
            delay: Double.random(in: 0...2)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                Circle()
                    .fill(.white)
                    .frame(width: star.size, height: star.size)
                    .position(
                        x: star.x * geo.size.width,
                        y: star.y * geo.size.height
                    )
                    .opacity(appeared ? Double.random(in: 0.3...0.85) : 0)
                    .animation(
                        .easeIn(duration: 0.6).delay(star.delay),
                        value: appeared
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
