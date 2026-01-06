//
//  FigureView.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

struct FigureView: View {
    let figure: Figure
    @State private var animationPhase: CGFloat = 0
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var accessibilityManager = AccessibilitySettingsManager.shared
    @ObservedObject private var performanceMonitor = PerformanceMonitor.shared
    
    private var theme: BabySmashTheme {
        themeManager.currentTheme
    }
    
    /// Whether to use expensive effects based on current performance tier
    private var useExpensiveEffects: Bool {
        performanceMonitor.effectiveTier.showGlowEffects
    }
    
    /// Whether to use drawingGroup based on performance tier
    private var useDrawingGroup: Bool {
        performanceMonitor.effectiveTier.useDrawingGroup
    }
    
    var body: some View {
        ZStack {
            if let character = figure.character {
                letterView(character)
            } else if let shapeType = figure.shapeType {
                shapeView(shapeType)
            }
        }
        .frame(width: figure.size, height: figure.size)
        .scaleEffect(figure.scale)
        .rotationEffect(figure.rotation)
        .opacity(figure.opacity)
        .position(figure.position)
        .modifier(animationModifier)
        .modifier(ConditionalDrawingGroup(enabled: useDrawingGroup))
    }
    
    @ViewBuilder
    private func letterView(_ character: Character) -> some View {
        let useGradient = theme.shapeStyle == .gradient && !accessibilityManager.settings.highContrastMode
        
        Text(String(character))
            .font(.custom(figure.fontFamily, size: figure.size * 0.8).weight(.heavy))
            .foregroundStyle(useGradient ? AnyShapeStyle(figure.color.gradient) : AnyShapeStyle(figure.color))
            .shadow(
                color: (theme.shadowEnabled && useExpensiveEffects) ? figure.color.opacity(theme.shadowOpacity) : .clear,
                radius: theme.shadowRadius,
                x: 5,
                y: 5
            )
            .overlay {
                if theme.glowEnabled && useExpensiveEffects && !accessibilityManager.settings.photosensitivitySafeMode {
                    Text(String(character))
                        .font(.custom(figure.fontFamily, size: figure.size * 0.8).weight(.heavy))
                        .foregroundStyle(figure.color)
                        .blur(radius: theme.glowRadius / 2)
                }
            }
            .modifier(effectiveFloatModifier)
    }
    
    @ViewBuilder
    private func shapeView(_ type: ShapeType) -> some View {
        let showPattern = accessibilityManager.settings.showPatterns && 
                          accessibilityManager.settings.colorBlindnessMode != .none
        
        ZStack {
            shapeContent(type)
                .fill(getShapeFillStyle(figure.color))
                .overlay {
                    // Pattern overlay for color blindness support
                    if showPattern {
                        PatternOverlay(pattern: PatternOverlay.PatternType.forShapeType(type))
                            .clipShape(shapeContent(type))
                    }
                }
                .overlay {
                    if theme.shapeStyle == .outlined || theme.shapeStyle == .filledWithOutline || accessibilityManager.settings.highContrastMode {
                        shapeContent(type)
                            .stroke(figure.color, lineWidth: accessibilityManager.settings.highContrastMode ? 5 : 3)
                    }
                }
                .shadow(
                    color: (theme.shadowEnabled && useExpensiveEffects) ? figure.color.opacity(theme.shadowOpacity) : .clear,
                    radius: theme.shadowRadius,
                    x: 5,
                    y: 5
                )
                .overlay {
                    if theme.glowEnabled && useExpensiveEffects && !accessibilityManager.settings.photosensitivitySafeMode {
                        shapeContent(type)
                            .stroke(figure.color, lineWidth: 2)
                            .blur(radius: theme.glowRadius / 2)
                    }
                }
            
            if figure.showFace {
                faceOverlay
            }
        }
    }
    
    private func getShapeFillStyle(_ color: Color) -> AnyShapeStyle {
        // Use simpler fills in high contrast mode
        if accessibilityManager.settings.highContrastMode {
            return AnyShapeStyle(color)
        }
        
        switch theme.shapeStyle {
        case .gradient:
            return AnyShapeStyle(color.gradient)
        case .filled, .filledWithOutline:
            return AnyShapeStyle(color)
        case .outlined:
            return AnyShapeStyle(color.opacity(0.2))
        }
    }
    
    private func shapeContent(_ type: ShapeType) -> AnyShape {
        switch type {
        case .circle:
            return AnyShape(Circle())
        case .oval:
            return AnyShape(Ellipse())
        case .rectangle:
            return AnyShape(RoundedRectangle(cornerRadius: 10))
        case .square:
            return AnyShape(RoundedRectangle(cornerRadius: 8))
        case .triangle:
            return AnyShape(TriangleShape())
        case .hexagon:
            return AnyShape(HexagonShape())
        case .trapezoid:
            return AnyShape(TrapezoidShape())
        case .star:
            return AnyShape(StarShape())
        case .heart:
            return AnyShape(HeartShape())
        }
    }
    
    private var faceOverlay: some View {
        Group {
            switch theme.faceStyle {
            case .none:
                EmptyView()
            case .simple:
                simpleFace
            case .kawaii:
                kawaiiFace
            }
        }
    }
    
    private var simpleFace: some View {
        VStack(spacing: figure.size * 0.05) {
            // Eyes
            HStack(spacing: figure.size * 0.2) {
                Circle()
                    .fill(.black)
                    .frame(width: figure.size * 0.1, height: figure.size * 0.1)
                Circle()
                    .fill(.black)
                    .frame(width: figure.size * 0.1, height: figure.size * 0.1)
            }
            // Smile
            Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                .stroke(.black, lineWidth: 3)
                .frame(width: figure.size * 0.3, height: figure.size * 0.15)
        }
        .offset(y: -figure.size * 0.05)
    }
    
    private var kawaiiFace: some View {
        VStack(spacing: figure.size * 0.03) {
            // Eyes - bigger and more expressive
            HStack(spacing: figure.size * 0.15) {
                // Left eye
                ZStack {
                    Ellipse()
                        .fill(.black)
                        .frame(width: figure.size * 0.12, height: figure.size * 0.15)
                    Circle()
                        .fill(.white)
                        .frame(width: figure.size * 0.04, height: figure.size * 0.04)
                        .offset(x: -figure.size * 0.02, y: -figure.size * 0.03)
                }
                // Right eye
                ZStack {
                    Ellipse()
                        .fill(.black)
                        .frame(width: figure.size * 0.12, height: figure.size * 0.15)
                    Circle()
                        .fill(.white)
                        .frame(width: figure.size * 0.04, height: figure.size * 0.04)
                        .offset(x: -figure.size * 0.02, y: -figure.size * 0.03)
                }
            }
            // Blush marks
            HStack(spacing: figure.size * 0.25) {
                Ellipse()
                    .fill(Color.pink.opacity(0.4))
                    .frame(width: figure.size * 0.08, height: figure.size * 0.05)
                Ellipse()
                    .fill(Color.pink.opacity(0.4))
                    .frame(width: figure.size * 0.08, height: figure.size * 0.05)
            }
            // Small cute smile
            Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                .stroke(.black, lineWidth: 2)
                .frame(width: figure.size * 0.15, height: figure.size * 0.08)
        }
        .offset(y: -figure.size * 0.05)
    }
    
    /// Returns the effective float modifier based on accessibility settings
    private var effectiveFloatModifier: some ViewModifier {
        if accessibilityManager.effectiveReduceMotion {
            return AnyViewModifier(NoAnimationModifier())
        }
        return AnyViewModifier(FloatEffect())
    }
    
    private var animationModifier: some ViewModifier {
        // Respect animation style set by GameViewModel (which already considers accessibility)
        switch figure.animationStyle {
        case .jiggle:
            return AnyViewModifier(JiggleEffect())
        case .throb:
            return AnyViewModifier(ThrobEffect())
        case .rotate:
            return AnyViewModifier(RotateEffect())
        case .snap:
            return AnyViewModifier(SnapEffect())
        case .none:
            return AnyViewModifier(NoAnimationModifier())
        }
    }
}

// Type erasure for ViewModifier
struct AnyViewModifier: ViewModifier {
    private let _body: (Content) -> AnyView
    
    init<M: ViewModifier>(_ modifier: M) {
        _body = { content in
            AnyView(content.modifier(modifier))
        }
    }
    
    func body(content: Content) -> some View {
        _body(content)
    }
}

// Helper shape for smile
struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}

// Snap effect (quick scale animation)
struct SnapEffect: ViewModifier {
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
                    SpringKeyframe(1.2, duration: 0.1, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.15)
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

// No animation modifier for .none case
struct NoAnimationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

// Conditional drawingGroup modifier for performance optimization
struct ConditionalDrawingGroup: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        if enabled {
            content.drawingGroup()
        } else {
            content
        }
    }
}
