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
/// Uses TimelineView for efficient animation without Timer overhead
struct StarfieldBackground: View {
    let baseColor: Color
    @State private var stars: [Star] = []
    
    struct Star: Identifiable {
        let id = UUID()
        var position: CGPoint
        var size: CGFloat
        var opacity: Double
        var twinkleSpeed: Double // Individual speed multiplier for variety
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
            GeometryReader { geometry in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    
                    // Draw base color
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(baseColor)
                    )
                    
                    // Draw all stars in a single pass
                    for star in stars {
                        let twinkle = 0.5 + 0.5 * sin(time * star.twinkleSpeed)
                        let finalOpacity = star.opacity * twinkle
                        
                        let rect = CGRect(
                            x: star.position.x - star.size / 2,
                            y: star.position.y - star.size / 2,
                            width: star.size,
                            height: star.size
                        )
                        
                        context.opacity = finalOpacity
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(.white)
                        )
                    }
                }
                .onAppear {
                    generateStars(in: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateStars(in size: CGSize) {
        let width = max(size.width, 100)
        let height = max(size.height, 100)
        
        // Reduce star count for better performance (was 200)
        stars = (0..<120).map { _ in
            Star(
                position: CGPoint(
                    x: CGFloat.random(in: 0...width),
                    y: CGFloat.random(in: 0...height)
                ),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.3...1.0),
                twinkleSpeed: Double.random(in: 0.5...2.0) // Varied twinkle speeds
            )
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
