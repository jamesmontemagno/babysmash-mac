//
//  ShapeType.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

enum ShapeType: String, CaseIterable, Identifiable {
    case circle
    case oval
    case rectangle
    case square
    case triangle
    case hexagon
    case trapezoid
    case star
    case heart
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    static var random: ShapeType {
        allCases.randomElement()!
    }
}
