//
//  PerformanceMonitor.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI
import Combine

/// Monitors rendering performance and provides adaptive limits to prevent frame drops.
/// Uses a lightweight approach to track approximate CPU load without expensive profiling.
@MainActor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    // MARK: - Published State
    
    /// Current performance tier based on recent measurements
    @Published private(set) var currentTier: PerformanceTier = .high
    
    /// Whether the app is currently under heavy load
    @Published private(set) var isUnderLoad: Bool = false
    
    // MARK: - Settings
    
    @AppStorage("performanceMode") var performanceMode: PerformanceMode = .auto
    
    enum PerformanceMode: String, CaseIterable {
        case auto = "Auto"
        case high = "High Quality"
        case balanced = "Balanced"
        case low = "Battery Saver"
        
        var localizedName: String {
            switch self {
            case .auto: return "Auto"
            case .high: return "High Quality"
            case .balanced: return "Balanced"
            case .low: return "Battery Saver"
            }
        }
    }
    
    enum PerformanceTier {
        case high      // Full effects, no limits
        case medium    // Reduced effects, moderate limits
        case low       // Minimal effects, strict limits
        
        /// Maximum concurrent figures for this tier
        var maxFigures: Int {
            switch self {
            case .high: return 50
            case .medium: return 30
            case .low: return 15
            }
        }
        
        /// Maximum concurrent trails for this tier
        var maxTrails: Int {
            switch self {
            case .high: return 300
            case .medium: return 150
            case .low: return 50
            }
        }
        
        /// Whether to use drawingGroup for figures
        var useDrawingGroup: Bool {
            switch self {
            case .high: return true
            case .medium: return false
            case .low: return false
            }
        }
        
        /// Whether to show glow effects
        var showGlowEffects: Bool {
            switch self {
            case .high: return true
            case .medium: return true
            case .low: return false
            }
        }
        
        /// Whether to show shadow effects
        var showShadowEffects: Bool {
            switch self {
            case .high: return true
            case .medium: return true
            case .low: return false
            }
        }
        
        /// Minimum distance between trail points (throttling)
        var minTrailDistance: CGFloat {
            switch self {
            case .high: return 5
            case .medium: return 10
            case .low: return 20
            }
        }
        
        /// Fade timer interval in seconds
        var fadeTimerInterval: TimeInterval {
            switch self {
            case .high: return 0.5
            case .medium: return 0.75
            case .low: return 1.0
            }
        }
    }
    
    // MARK: - Private State
    
    private var frameTimestamps: [CFAbsoluteTime] = []
    private var lastFrameTime: CFAbsoluteTime = 0
    private var loadSamples: [Double] = []
    private let maxSamples = 30
    private var updateTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Returns the effective performance tier considering user preference and auto-detection.
    var effectiveTier: PerformanceTier {
        switch performanceMode {
        case .auto:
            return currentTier
        case .high:
            return .high
        case .balanced:
            return .medium
        case .low:
            return .low
        }
    }
    
    /// Records a frame render for performance tracking. Call this periodically.
    func recordFrame() {
        let now = CFAbsoluteTimeGetCurrent()
        
        if lastFrameTime > 0 {
            let frameDuration = now - lastFrameTime
            // Target is 16.67ms for 60fps
            let load = min(1.0, frameDuration / 0.05) // Normalize to 0-1, > 1 if frame takes > 50ms
            loadSamples.append(load)
            
            if loadSamples.count > maxSamples {
                loadSamples.removeFirst()
            }
        }
        
        lastFrameTime = now
        frameTimestamps.append(now)
        
        // Keep only recent timestamps for FPS calculation
        let cutoff = now - 1.0
        frameTimestamps.removeAll { $0 < cutoff }
    }
    
    /// Current approximate frames per second
    var currentFPS: Int {
        guard frameTimestamps.count > 1 else { return 60 }
        return frameTimestamps.count
    }
    
    /// Called when item counts change to help predict load
    func reportItemCounts(figures: Int, trails: Int) {
        // Simple heuristic: more items = more load
        let itemLoad = Double(figures + trails) / 100.0
        let averageLoad = loadSamples.isEmpty ? 0 : loadSamples.reduce(0, +) / Double(loadSamples.count)
        let combinedLoad = max(itemLoad, averageLoad)
        
        isUnderLoad = combinedLoad > 0.7
        
        // Only auto-adjust in auto mode
        guard performanceMode == .auto else { return }
        
        // Adjust tier based on load
        if combinedLoad > 0.8 {
            if currentTier != .low {
                currentTier = .low
            }
        } else if combinedLoad > 0.5 {
            if currentTier == .high {
                currentTier = .medium
            }
        } else if combinedLoad < 0.3 {
            // Slowly recover to higher tier
            if currentTier == .low {
                currentTier = .medium
            } else if currentTier == .medium && !isUnderLoad {
                currentTier = .high
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        // Periodic check every 2 seconds to assess and recover performance tier
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.periodicUpdate()
            }
        }
    }
    
    private func periodicUpdate() {
        // If we haven't had new load samples, assume we're doing fine
        guard !loadSamples.isEmpty else {
            if performanceMode == .auto && currentTier != .high {
                currentTier = .high
            }
            return
        }
        
        let averageLoad = loadSamples.reduce(0, +) / Double(loadSamples.count)
        
        // Only auto-adjust in auto mode
        guard performanceMode == .auto else { return }
        
        // Recovery: if load has been low, try upgrading tier
        if averageLoad < 0.3 && currentTier != .high {
            if currentTier == .low {
                currentTier = .medium
            } else {
                currentTier = .high
            }
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}
