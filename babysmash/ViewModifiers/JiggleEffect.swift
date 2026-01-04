//
//  JiggleEffect.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

struct JiggleEffect: ViewModifier {
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
                    SpringKeyframe(10, duration: 0.1)
                    SpringKeyframe(-10, duration: 0.1)
                    SpringKeyframe(5, duration: 0.1)
                    SpringKeyframe(-5, duration: 0.1)
                    SpringKeyframe(0, duration: 0.1)
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
