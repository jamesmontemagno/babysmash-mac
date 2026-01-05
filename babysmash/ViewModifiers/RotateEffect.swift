//
//  RotateEffect.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

struct RotateEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .keyframeAnimator(
                initialValue: AnimationValues(),
                trigger: isAnimating
            ) { content, value in
                content
                    .rotationEffect(.degrees(value.rotation))
            } keyframes: { _ in
                KeyframeTrack(\.rotation) {
                    SpringKeyframe(380, duration: 0.5, spring: .bouncy)
                    SpringKeyframe(360, duration: 0.2)
                }
            }
            .onAppear {
                isAnimating = true
            }
    }
    
    struct AnimationValues {
        var rotation: Double = 0
    }
}
