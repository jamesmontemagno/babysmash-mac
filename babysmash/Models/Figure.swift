//
//  Figure.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

struct Figure: Identifiable {
    let id = UUID()
    let shapeType: ShapeType?          // nil if displaying letter/number
    let character: Character?           // Letter or number to display
    let color: Color
    let position: CGPoint
    let size: CGFloat                   // Base size (150-300 range)
    let createdAt: Date
    
    // Animation state
    var scale: CGFloat = 0.0
    var rotation: Angle = .zero
    var opacity: Double = 1.0
    
    // Configuration
    let showFace: Bool
    let animationStyle: AnimationStyle
    
    enum AnimationStyle: CaseIterable {
        case jiggle
        case throb
        case rotate
        case snap
        case none
        
        static var random: AnimationStyle {
            allCases.randomElement()!
        }
    }
}
