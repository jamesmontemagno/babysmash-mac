//
//  AutoPlayManager.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import Foundation
import Combine

/// Manages automatic shape generation for motor accessibility
/// Allows shapes to appear automatically at set intervals without user input
class AutoPlayManager: ObservableObject {
    static let shared = AutoPlayManager()
    
    @Published private(set) var isRunning: Bool = false
    
    private var timer: Timer?
    
    /// The interval between auto-generated shapes
    var interval: TimeInterval = 3.0
    
    /// Callback when a shape should be generated
    var onTick: (() -> Void)?
    
    private init() {}
    
    /// Starts auto-play mode
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        
        // Generate first shape immediately
        onTick?()
        
        // Then continue at interval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.onTick?()
        }
    }
    
    /// Stops auto-play mode
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    /// Updates the interval and restarts if running
    func setInterval(_ newInterval: TimeInterval) {
        interval = newInterval
        if isRunning {
            stop()
            start()
        }
    }
    
    /// Toggles auto-play on/off
    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }
    
    deinit {
        stop()
    }
}
