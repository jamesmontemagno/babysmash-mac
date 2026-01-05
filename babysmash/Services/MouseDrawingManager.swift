//
//  MouseDrawingManager.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI
import Combine

struct DrawingTrail: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double = 1.0
    let createdAt: Date
    
    /// The screen index this trail should be displayed on (for multi-monitor support).
    let screenIndex: Int
}

class MouseDrawingManager: ObservableObject {
    @Published var trails: [DrawingTrail] = []
    
    private var isDrawing = false
    private let maxTrails = 500
    private var fadeTimer: Timer?
    
    init() {
        startFadeTimer()
    }
    
    /// Adds a drawing point at the specified position on the specified screen.
    /// - Parameters:
    ///   - position: The position of the point in screen coordinates.
    ///   - screenIndex: The index of the screen this point belongs to.
    func addPoint(at position: CGPoint, screenIndex: Int = 0) {
        if !isDrawing {
            isDrawing = true
            SoundManager.shared.play(.smallbumblebee)
        }
        
        let trail = DrawingTrail(
            position: position,
            color: Color.randomBabySmash,
            size: CGFloat.random(in: 15...30),
            createdAt: Date(),
            screenIndex: screenIndex
        )
        
        trails.append(trail)
        
        // Limit total trails
        if trails.count > maxTrails {
            trails.removeFirst(trails.count - maxTrails)
        }
    }
    
    func endDrawing() {
        isDrawing = false
    }
    
    private func startFadeTimer() {
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.fadeOldTrails()
        }
    }
    
    private func fadeOldTrails() {
        let now = Date()
        trails = trails.compactMap { trail in
            let age = now.timeIntervalSince(trail.createdAt)
            if age > 3.0 { return nil } // Remove after 3 seconds
            
            var updated = trail
            if age > 1.0 {
                updated.opacity = max(0, 1.0 - (age - 1.0) / 2.0)
            }
            return updated
        }
    }
    
    deinit {
        fadeTimer?.invalidate()
    }
}
