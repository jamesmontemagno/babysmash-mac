//
//  ThemedBackground.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI

/// A view that renders the appropriate background based on the theme settings
struct ThemedBackground: View {
    let theme: BabySmashTheme
    
    var body: some View {
        switch theme.backgroundStyle {
        case .solid:
            theme.backgroundColor.color
                .ignoresSafeArea()
        case .linearGradient:
            LinearGradient(
                colors: theme.backgroundGradientColors?.map(\.color) ?? [theme.backgroundColor.color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        case .radialGradient:
            RadialGradient(
                colors: theme.backgroundGradientColors?.map(\.color) ?? [theme.backgroundColor.color],
                center: .center,
                startRadius: 0,
                endRadius: 1000
            )
            .ignoresSafeArea()
        case .animatedGradient:
            AnimatedGradientBackground(colors: theme.backgroundGradientColors?.map(\.color) ?? [theme.backgroundColor.color])
        case .starfield:
            StarfieldBackground(baseColor: theme.backgroundColor.color)
        }
    }
}

/// An animated gradient background that slowly shifts colors
struct AnimatedGradientBackground: View {
    let colors: [Color]
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            colors: colors.isEmpty ? [.blue, .purple] : colors,
            startPoint: UnitPoint(x: animationPhase, y: 0),
            endPoint: UnitPoint(x: 1 - animationPhase, y: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
        .ignoresSafeArea()
    }
}

/// A starfield background with twinkling stars
struct StarfieldBackground: View {
    let baseColor: Color
    @State private var stars: [Star] = []
    @State private var twinkleTimer: Timer?
    
    struct Star: Identifiable {
        let id = UUID()
        var position: CGPoint
        var size: CGFloat
        var opacity: Double
        var twinklePhase: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                baseColor
                
                ForEach(stars) { star in
                    Circle()
                        .fill(.white)
                        .frame(width: star.size, height: star.size)
                        .opacity(star.opacity * (0.5 + 0.5 * sin(star.twinklePhase)))
                        .position(star.position)
                }
            }
            .onAppear {
                generateStars(in: geometry.size)
                startTwinkling()
            }
            .onDisappear {
                twinkleTimer?.invalidate()
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateStars(in size: CGSize) {
        let width = max(size.width, 100)
        let height = max(size.height, 100)
        
        stars = (0..<200).map { _ in
            Star(
                position: CGPoint(
                    x: CGFloat.random(in: 0...width),
                    y: CGFloat.random(in: 0...height)
                ),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.3...1.0),
                twinklePhase: Double.random(in: 0...2 * .pi)
            )
        }
    }
    
    private func startTwinkling() {
        twinkleTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in stars.indices {
                stars[i].twinklePhase += 0.1
            }
        }
    }
}

#Preview("Solid Background") {
    ThemedBackground(theme: .classic)
}

#Preview("Starfield Background") {
    ThemedBackground(theme: .space)
}

#Preview("Gradient Background") {
    ThemedBackground(theme: .ocean)
}
