//
//  ThrobEffect.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

struct ThrobEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .keyframeAnimator(
                initialValue: AnimationValues(),
                trigger: isAnimating
            ) { content, value in
                content
                    .scaleEffect(value.scale)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.1, duration: 0.15)
                    SpringKeyframe(0.9, duration: 0.15)
                    SpringKeyframe(1.05, duration: 0.1)
                    SpringKeyframe(0.95, duration: 0.1)
                    SpringKeyframe(1.0, duration: 0.1)
                }
            }
            .onAppear {
                isAnimating = true
            }
    }
    
    struct AnimationValues {
        var scale: Double = 1.0
    }
}
