//
//  FloatEffect.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

/// A gentle floating/bobbing animation effect for letters and numbers
struct FloatEffect: ViewModifier {
    @State private var isFloating = false
    
    // Randomize animation parameters for variety
    private let floatDistance: CGFloat
    private let floatDuration: Double
    private let rotationAmount: Double
    private let horizontalDrift: CGFloat
    
    init() {
        // Random parameters so each letter floats slightly differently
        self.floatDistance = CGFloat.random(in: 8...15)
        self.floatDuration = Double.random(in: 2.0...3.5)
        self.rotationAmount = Double.random(in: -5...5)
        self.horizontalDrift = CGFloat.random(in: -5...5)
    }
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: isFloating ? horizontalDrift : -horizontalDrift,
                y: isFloating ? -floatDistance : floatDistance
            )
            .rotationEffect(.degrees(isFloating ? rotationAmount : -rotationAmount))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: floatDuration)
                    .repeatForever(autoreverses: true)
                ) {
                    isFloating = true
                }
            }
    }
}

/// A more playful bounce-float effect
struct BounceFloatEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    private let bounceHeight: CGFloat
    private let duration: Double
    
    init() {
        self.bounceHeight = CGFloat.random(in: 10...18)
        self.duration = Double.random(in: 1.5...2.5)
    }
    
    func body(content: Content) -> some View {
        content
            .keyframeAnimator(
                initialValue: AnimationValues(),
                repeating: true
            ) { content, value in
                content
                    .offset(y: value.offsetY)
                    .scaleEffect(y: value.squash)
            } keyframes: { _ in
                KeyframeTrack(\.offsetY) {
                    SpringKeyframe(-bounceHeight, duration: duration * 0.5, spring: .smooth)
                    SpringKeyframe(0, duration: duration * 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.squash) {
                    SpringKeyframe(1.0, duration: duration * 0.4)
                    SpringKeyframe(0.95, duration: duration * 0.1)
                    SpringKeyframe(1.05, duration: duration * 0.2)
                    SpringKeyframe(1.0, duration: duration * 0.3)
                }
            }
    }
    
    struct AnimationValues {
        var offsetY: CGFloat = 0
        var squash: CGFloat = 1.0
    }
}
