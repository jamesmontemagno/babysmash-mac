//
//  ThemePickerView.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

/// A view shown on first launch to let users pick their initial theme
struct ThemePickerView: View {
    let onThemeSelected: (BabySmashTheme) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTheme: BabySmashTheme = .classic
    @State private var titleOpacity: Double = 0
    @State private var gridOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var buttonPulse: Bool = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 12) {
                    Text("🎨")
                        .font(.system(size: 50))
                    
                    Text("Choose Your Theme")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Pick a look for your BabySmash adventure!")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .opacity(titleOpacity)
                .padding(.top, 30)
                
                // Theme grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(BabySmashTheme.allBuiltIn, id: \.id) { theme in
                            ThemePreviewCard(
                                theme: theme,
                                isSelected: selectedTheme.id == theme.id
                            )
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedTheme = theme
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }
                .opacity(gridOpacity)
                
                // Select button
                Button(action: {
                    themeManager.selectTheme(selectedTheme)
                    onThemeSelected(selectedTheme)
                }) {
                    HStack(spacing: 12) {
                        Text("Start with \(selectedTheme.name)")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.5), radius: 15, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(buttonPulse ? 1.05 : 1.0)
                .opacity(buttonOpacity)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            titleOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            gridOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
            buttonOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                buttonPulse = true
            }
        }
    }
}

/// A small preview card showing a theme's appearance
struct ThemePreviewCard: View {
    let theme: BabySmashTheme
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Mini preview
            ZStack {
                // Background preview
                themeBackgroundPreview
                
                // Sample shapes
                sampleShapes
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 3 : 1)
            )
            
            // Theme name
            Text(theme.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(duration: 0.3), value: isSelected)
    }
    
    @ViewBuilder
    private var themeBackgroundPreview: some View {
        switch theme.backgroundStyle {
        case .solid:
            Rectangle()
                .fill(theme.backgroundColor.color)
        case .linearGradient:
            if let gradientColors = theme.backgroundGradientColors {
                LinearGradient(
                    colors: gradientColors.map { $0.color },
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Rectangle()
                    .fill(theme.backgroundColor.color)
            }
        case .radialGradient:
            if let gradientColors = theme.backgroundGradientColors {
                RadialGradient(
                    colors: gradientColors.map { $0.color },
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
            } else {
                Rectangle()
                    .fill(theme.backgroundColor.color)
            }
        case .animatedGradient, .starfield:
            if let gradientColors = theme.backgroundGradientColors {
                LinearGradient(
                    colors: gradientColors.map { $0.color },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Rectangle()
                    .fill(theme.backgroundColor.color)
            }
        }
    }
    
    private var sampleShapes: some View {
        let sampleColors = Array(theme.palette.prefix(4))
        
        return ZStack {
            // Show a few sample shapes from the theme
            if sampleColors.count > 0 {
                Circle()
                    .fill(sampleColors[0].color)
                    .frame(width: 40, height: 40)
                    .offset(x: -35, y: -20)
                    .shadow(color: sampleColors[0].color.opacity(theme.shadowEnabled ? 0.5 : 0), radius: 6)
            }
            
            if sampleColors.count > 1 {
                StarShape()
                    .fill(sampleColors[1].color)
                    .frame(width: 38, height: 38)
                    .offset(x: 35, y: -15)
                    .shadow(color: sampleColors[1].color.opacity(theme.shadowEnabled ? 0.5 : 0), radius: 6)
            }
            
            if sampleColors.count > 2 {
                HeartShape()
                    .fill(sampleColors[2].color)
                    .frame(width: 34, height: 34)
                    .offset(x: -20, y: 28)
                    .shadow(color: sampleColors[2].color.opacity(theme.shadowEnabled ? 0.5 : 0), radius: 6)
            }
            
            if sampleColors.count > 3 {
                Text("A")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(sampleColors[3].color)
                    .offset(x: 28, y: 24)
                    .shadow(color: sampleColors[3].color.opacity(theme.shadowEnabled ? 0.5 : 0), radius: 6)
            }
        }
    }
}

#Preview {
    ThemePickerView(onThemeSelected: { _ in })
}
