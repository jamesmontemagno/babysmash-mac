//
//  VisualSoundIndicator.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI

/// A visual indicator that flashes when sounds play
/// Used for auditory accessibility - provides visual feedback for deaf/HoH users
struct VisualSoundIndicator: View {
    @Binding var isActive: Bool
    let borderWidth: CGFloat
    
    init(isActive: Binding<Bool>, borderWidth: CGFloat = 20) {
        self._isActive = isActive
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isActive {
                Rectangle()
                    .stroke(
                        LinearGradient(
                            colors: [.yellow, .orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: borderWidth
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)  // Don't block interactions
    }
}

/// A view that displays captions for sounds and speech
/// Used for auditory accessibility - shows text for what's being said/played
struct CaptionView: View {
    let text: String
    
    var body: some View {
        if !text.isEmpty {
            VStack {
                Spacer()
                Text(text)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.black.opacity(0.75))
                    )
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .allowsHitTesting(false)
        }
    }
}

/// Container view that manages both visual sound indicator and captions
struct AccessibilitySoundOverlay: View {
    @ObservedObject private var accessibilityManager = AccessibilitySettingsManager.shared
    
    var body: some View {
        ZStack {
            // Visual sound indicator (flashing border)
            if accessibilityManager.settings.visualSoundIndicators {
                VisualSoundIndicator(isActive: $accessibilityManager.showSoundIndicator)
            }
            
            // Captions
            if accessibilityManager.settings.showCaptions {
                CaptionView(text: accessibilityManager.currentCaption)
                    .animation(.easeInOut(duration: 0.3), value: accessibilityManager.currentCaption)
            }
        }
    }
}

// MARK: - Preview

#Preview("Sound Indicator Active") {
    ZStack {
        Color.black
        
        VisualSoundIndicator(isActive: .constant(true))
    }
    .frame(width: 400, height: 300)
}

#Preview("Caption View") {
    ZStack {
        Color.black
        
        CaptionView(text: "Circle - Blue")
    }
    .frame(width: 400, height: 300)
}
