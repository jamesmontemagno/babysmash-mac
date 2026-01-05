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
    }
    
    @ViewBuilder
    private func letterView(_ character: Character) -> some View {
        Text(String(character))
            .font(.custom(figure.fontFamily, size: figure.size * 0.8).weight(.heavy))
            .foregroundStyle(figure.color.gradient)
            .shadow(color: figure.color.opacity(0.5), radius: 10, x: 5, y: 5)
    }
    
    @ViewBuilder
    private func shapeView(_ type: ShapeType) -> some View {
        ZStack {
            shapeContent(type)
                .fill(figure.color.gradient)
                .shadow(color: figure.color.opacity(0.5), radius: 15, x: 5, y: 5)
            
            if figure.showFace {
                faceOverlay
            }
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
    
    private var animationModifier: some ViewModifier {
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
