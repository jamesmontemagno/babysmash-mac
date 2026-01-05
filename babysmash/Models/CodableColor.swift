//
//  CodableColor.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI
import AppKit

/// Color wrapper for Codable support
struct CodableColor: Codable, Equatable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
    
    init(_ color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor(color)
        self.red = Double(nsColor.redComponent)
        self.green = Double(nsColor.greenComponent)
        self.blue = Double(nsColor.blueComponent)
        self.opacity = Double(nsColor.alphaComponent)
    }
    
    // Common color presets
    static let white = CodableColor(red: 1.0, green: 1.0, blue: 1.0)
    static let black = CodableColor(red: 0.0, green: 0.0, blue: 0.0)
    static let red = CodableColor(.red)
    static let blue = CodableColor(.blue)
    static let yellow = CodableColor(.yellow)
    static let green = CodableColor(.green)
    static let purple = CodableColor(.purple)
    static let pink = CodableColor(.pink)
    static let orange = CodableColor(.orange)
    static let cyan = CodableColor(.cyan)
    static let mint = CodableColor(.mint)
}
