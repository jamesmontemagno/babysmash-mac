//
//  PatternOverlay.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI

/// Provides pattern overlays for shapes to help distinguish them beyond color
/// This is especially useful for users with color blindness
struct PatternOverlay: View {
    let pattern: PatternType
    let lineWidth: CGFloat
    
    init(pattern: PatternType, lineWidth: CGFloat = 4) {
        self.pattern = pattern
        self.lineWidth = lineWidth
    }
    
    enum PatternType: CaseIterable, Identifiable {
        case solid
        case horizontalStripes
        case verticalStripes
        case diagonalStripesLeft
        case diagonalStripesRight
        case dots
        case crosshatch
        case grid
        
        var id: String {
            switch self {
            case .solid: return "solid"
            case .horizontalStripes: return "horizontal"
            case .verticalStripes: return "vertical"
            case .diagonalStripesLeft: return "diagonalLeft"
            case .diagonalStripesRight: return "diagonalRight"
            case .dots: return "dots"
            case .crosshatch: return "crosshatch"
            case .grid: return "grid"
            }
        }
        
        /// Returns a random pattern (excluding solid)
        static var random: PatternType {
            let patterns = allCases.filter { $0 != .solid }
            return patterns.randomElement() ?? .horizontalStripes
        }
        
        /// Returns a pattern based on shape type for consistent identification
        static func forShapeType(_ shapeType: ShapeType) -> PatternType {
            switch shapeType {
            case .circle: return .dots
            case .oval: return .horizontalStripes
            case .rectangle: return .verticalStripes
            case .square: return .grid
            case .triangle: return .diagonalStripesRight
            case .hexagon: return .crosshatch
            case .trapezoid: return .diagonalStripesLeft
            case .star: return .solid  // Stars are already distinctive
            case .heart: return .solid // Hearts are already distinctive
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            patternContent(in: geometry.size)
                .opacity(0.3)
        }
        .clipped()
    }
    
    @ViewBuilder
    private func patternContent(in size: CGSize) -> some View {
        switch pattern {
        case .solid:
            Color.clear
        case .horizontalStripes:
            StripesPattern(spacing: lineWidth * 2, lineWidth: lineWidth, angle: 0)
        case .verticalStripes:
            StripesPattern(spacing: lineWidth * 2, lineWidth: lineWidth, angle: 90)
        case .diagonalStripesLeft:
            StripesPattern(spacing: lineWidth * 2, lineWidth: lineWidth, angle: -45)
        case .diagonalStripesRight:
            StripesPattern(spacing: lineWidth * 2, lineWidth: lineWidth, angle: 45)
        case .dots:
            DotsPattern(spacing: lineWidth * 3, dotSize: lineWidth)
        case .crosshatch:
            CrosshatchPattern(spacing: lineWidth * 2, lineWidth: lineWidth)
        case .grid:
            GridPattern(spacing: lineWidth * 3, lineWidth: lineWidth)
        }
    }
}

// MARK: - Pattern Components

/// Creates a stripes pattern at any angle
struct StripesPattern: View {
    let spacing: CGFloat
    let lineWidth: CGFloat
    let angle: Double
    
    var body: some View {
        Canvas { context, size in
            let diagonal = sqrt(size.width * size.width + size.height * size.height)
            let count = Int(diagonal / (spacing + lineWidth)) + 2
            
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: .degrees(angle))
            context.translateBy(x: -diagonal / 2, y: -diagonal / 2)
            
            for i in 0..<count {
                let y = CGFloat(i) * (spacing + lineWidth)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: diagonal, y: y))
                context.stroke(path, with: .color(.black), lineWidth: lineWidth)
            }
        }
    }
}

/// Creates a dots pattern
struct DotsPattern: View {
    let spacing: CGFloat
    let dotSize: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * spacing + spacing / 2
                    let y = CGFloat(row) * spacing + spacing / 2
                    let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                    context.fill(Circle().path(in: rect), with: .color(.black))
                }
            }
        }
    }
}

/// Creates a crosshatch pattern
struct CrosshatchPattern: View {
    let spacing: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            StripesPattern(spacing: spacing, lineWidth: lineWidth, angle: 45)
            StripesPattern(spacing: spacing, lineWidth: lineWidth, angle: -45)
        }
    }
}

/// Creates a grid pattern
struct GridPattern: View {
    let spacing: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            StripesPattern(spacing: spacing, lineWidth: lineWidth, angle: 0)
            StripesPattern(spacing: spacing, lineWidth: lineWidth, angle: 90)
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        ForEach(PatternOverlay.PatternType.allCases) { pattern in
            Circle()
                .fill(.blue)
                .overlay(
                    PatternOverlay(pattern: pattern)
                        .clipShape(Circle())
                )
                .frame(width: 80, height: 80)
        }
    }
    .padding()
}
