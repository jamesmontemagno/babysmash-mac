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
    let fontFamily: String
    
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
    
    init(
        shapeType: ShapeType?,
        character: Character?,
        color: Color,
        position: CGPoint,
        size: CGFloat,
        createdAt: Date,
        scale: CGFloat = 0.0,
        rotation: Angle = .zero,
        opacity: Double = 1.0,
        showFace: Bool,
        animationStyle: AnimationStyle,
        fontFamily: String = "SF Pro Rounded"
    ) {
        self.shapeType = shapeType
        self.character = character
        self.color = color
        self.position = position
        self.size = size
        self.createdAt = createdAt
        self.scale = scale
        self.rotation = rotation
        self.opacity = opacity
        self.showFace = showFace
        self.animationStyle = animationStyle
        self.fontFamily = fontFamily
    }
}
