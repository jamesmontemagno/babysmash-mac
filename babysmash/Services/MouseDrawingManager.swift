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
    private var fadeTimer: Timer?
    
    /// Last recorded position for distance throttling
    private var lastPosition: CGPoint?
    
    /// Cached performance tier to reduce lookups
    private var cachedMinDistance: CGFloat = 5
    private var cachedMaxTrails: Int = 300
    
    init() {
        startFadeTimer()
        updatePerformanceSettings()
    }
    
    /// Updates cached performance settings from PerformanceMonitor
    private func updatePerformanceSettings() {
        Task { @MainActor in
            let tier = PerformanceMonitor.shared.effectiveTier
            self.cachedMinDistance = tier.minTrailDistance
            self.cachedMaxTrails = tier.maxTrails
        }
    }
    
    /// Adds a drawing point at the specified position on the specified screen.
    /// Throttles points based on minimum distance to reduce rendering load.
    /// - Parameters:
    ///   - position: The position of the point in screen coordinates.
    ///   - screenIndex: The index of the screen this point belongs to.
    func addPoint(at position: CGPoint, screenIndex: Int = 0) {
        // Distance throttling: skip points too close to the last one
        if let last = lastPosition {
            let dx = position.x - last.x
            let dy = position.y - last.y
            let distance = sqrt(dx * dx + dy * dy)
            if distance < cachedMinDistance {
                return
            }
        }
        lastPosition = position
        
        if !isDrawing {
            isDrawing = true
            SoundManager.shared.play(.smallbumblebee)
            // Refresh performance settings when drawing starts
            updatePerformanceSettings()
        }
        
        let trail = DrawingTrail(
            position: position,
            color: Color.randomBabySmash,
            size: CGFloat.random(in: 15...25), // Slightly smaller range
            createdAt: Date(),
            screenIndex: screenIndex
        )
        
        trails.append(trail)
        
        // Limit total trails using performance-aware max
        if trails.count > cachedMaxTrails {
            trails.removeFirst(trails.count - cachedMaxTrails)
        }
    }
    
    func endDrawing() {
        isDrawing = false
        lastPosition = nil
    }
    
    private func startFadeTimer() {
        // Use slightly longer interval to reduce CPU usage
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.fadeOldTrails()
        }
    }
    
    private func fadeOldTrails() {
        // Early exit if no trails
        guard !trails.isEmpty else { return }
        
        let now = Date()
        
        // Check if any trail needs updating before rebuilding the array
        var needsUpdate = false
        for trail in trails {
            let age = now.timeIntervalSince(trail.createdAt)
            if age > 1.0 {
                needsUpdate = true
                break
            }
        }
        
        guard needsUpdate else { return }
        
        trails = trails.compactMap { trail in
            let age = now.timeIntervalSince(trail.createdAt)
            if age > 2.5 { return nil } // Slightly faster cleanup (was 3.0)
            
            if age > 1.0 {
                var updated = trail
                updated.opacity = max(0, 1.0 - (age - 1.0) / 1.5) // Faster fade (was 2.0)
                return updated
            }
            return trail
        }
    }
    
    deinit {
        fadeTimer?.invalidate()
    }
}
