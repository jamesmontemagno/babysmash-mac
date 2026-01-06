//
//  IntroView.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

/// A floating shape for the intro background animation
struct FloatingShape: Identifiable {
    let id = UUID()
    let shapeType: ShapeType
    let color: Color
    let size: CGFloat
    var position: CGPoint
    let velocity: CGPoint
    let rotationSpeed: Double
    var rotation: Angle = .zero
}

/// Intro screen shown on app launch with controls and animations
struct IntroView: View {
    let onDismiss: () -> Void
    
    @State private var floatingShapes: [FloatingShape] = []
    @State private var titleScale: CGFloat = 0.5
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var controlsOpacity: Double = 0
    @State private var promptOpacity: Double = 0
    @State private var promptPulse: Bool = false
    @State private var animationTimer: Timer?
    
    private let numberOfShapes = 12
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Floating shapes in background
                ForEach(floatingShapes) { shape in
                    floatingShapeView(shape)
                }
                
                // Main content
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App title
                    VStack(spacing: 16) {
                        Text("👶")
                            .font(.system(size: 80))
                        
                        Text(L10n.Intro.title)
                            .font(.system(size: 72, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple, .blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.5), radius: 20, x: 0, y: 10)
                        
                        Text(L10n.Intro.subtitle)
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)
                    
                    Spacer()
                    
                    // Controls section
                    VStack(spacing: 24) {
                        Text(L10n.Intro.howToPlay)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            controlRow(icon: "keyboard", resource: L10n.Intro.instructionKeyboard)
                            controlRow(icon: "computermouse", resource: L10n.Intro.instructionMouse)
                            controlRow(icon: "speaker.wave.3", resource: L10n.Intro.instructionSound)
                            controlRow(icon: "gearshape", resource: L10n.Intro.instructionSettings)
                        }
                    }
                    .padding(.vertical, 32)
                    .padding(.horizontal, 48)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
                    )
                    .frame(maxWidth: 500)
                    .opacity(controlsOpacity)
                    
                    Spacer()
                    
                    // Click to start prompt
                    Text(L10n.Intro.clickToStart)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .scaleEffect(promptPulse ? 1.05 : 1.0)
                        .opacity(promptOpacity)
                    
                    // Exit button
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle")
                            Text(L10n.General.quit)
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(controlsOpacity)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                dismissWithAnimation()
            }
            .onAppear {
                initializeShapes(in: geometry.size)
                startAnimations()
            }
            .onDisappear {
                animationTimer?.invalidate()
            }
        }
        .ignoresSafeArea()
    }
    
    private func controlRow(icon: String, resource: LocalizedStringResource) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.cyan)
                .frame(width: 32)
            
            Text(resource)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
    
    @ViewBuilder
    private func floatingShapeView(_ shape: FloatingShape) -> some View {
        Group {
            switch shape.shapeType {
            case .circle:
                Circle()
                    .fill(shape.color.opacity(0.15))
            case .star:
                StarShape()
                    .fill(shape.color.opacity(0.15))
            case .heart:
                HeartShape()
                    .fill(shape.color.opacity(0.15))
            case .hexagon:
                HexagonShape()
                    .fill(shape.color.opacity(0.15))
            case .triangle:
                TriangleShape()
                    .fill(shape.color.opacity(0.15))
            case .square:
                RoundedRectangle(cornerRadius: 8)
                    .fill(shape.color.opacity(0.15))
            default:
                Circle()
                    .fill(shape.color.opacity(0.15))
            }
        }
        .frame(width: shape.size, height: shape.size)
        .rotationEffect(shape.rotation)
        .position(shape.position)
        .blur(radius: 2)
    }
    
    private func initializeShapes(in size: CGSize) {
        floatingShapes = (0..<numberOfShapes).map { _ in
            FloatingShape(
                shapeType: [.circle, .star, .heart, .hexagon, .triangle, .square].randomElement()!,
                color: Color.randomBabySmash,
                size: CGFloat.random(in: 60...150),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -0.5...0.5),
                    y: CGFloat.random(in: -0.5...0.5)
                ),
                rotationSpeed: Double.random(in: -0.5...0.5)
            )
        }
    }
    
    private func startAnimations() {
        // Animate title entrance
        withAnimation(.spring(duration: 0.8, bounce: 0.4).delay(0.2)) {
            titleScale = 1.0
            titleOpacity = 1.0
        }
        
        // Animate subtitle
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            subtitleOpacity = 1.0
        }
        
        // Animate controls
        withAnimation(.easeOut(duration: 0.8).delay(0.9)) {
            controlsOpacity = 1.0
        }
        
        // Animate prompt
        withAnimation(.easeOut(duration: 0.6).delay(1.4)) {
            promptOpacity = 1.0
        }
        
        // Start pulse animation for prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                promptPulse = true
            }
        }
        
        // Start floating animation timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateFloatingShapes()
        }
    }
    
    private func updateFloatingShapes() {
        for i in floatingShapes.indices {
            floatingShapes[i].position.x += floatingShapes[i].velocity.x
            floatingShapes[i].position.y += floatingShapes[i].velocity.y
            floatingShapes[i].rotation += .degrees(floatingShapes[i].rotationSpeed)
            
            // Wrap around screen edges
            if floatingShapes[i].position.x < -floatingShapes[i].size {
                floatingShapes[i].position.x = NSScreen.main?.frame.width ?? 1200
            } else if floatingShapes[i].position.x > (NSScreen.main?.frame.width ?? 1200) + floatingShapes[i].size {
                floatingShapes[i].position.x = -floatingShapes[i].size
            }
            
            if floatingShapes[i].position.y < -floatingShapes[i].size {
                floatingShapes[i].position.y = NSScreen.main?.frame.height ?? 800
            } else if floatingShapes[i].position.y > (NSScreen.main?.frame.height ?? 800) + floatingShapes[i].size {
                floatingShapes[i].position.y = -floatingShapes[i].size
            }
        }
    }
    
    private func dismissWithAnimation() {
        animationTimer?.invalidate()
        
        withAnimation(.easeIn(duration: 0.3)) {
            titleOpacity = 0
            titleScale = 1.1
            controlsOpacity = 0
            promptOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    IntroView(onDismiss: {})
}
