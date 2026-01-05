//
//  MultiMonitorManager.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import AppKit
import Combine

/// Manages multi-monitor detection and screen configuration for BabySmash.
class MultiMonitorManager: ObservableObject {
    /// Singleton instance for app-wide access.
    static let shared = MultiMonitorManager()
    
    /// Information about a single screen.
    struct ScreenInfo: Identifiable, Equatable {
        let id: Int
        let frame: CGRect
        let visibleFrame: CGRect
        let scaleFactor: CGFloat
        let localizedName: String
        
        static func == (lhs: ScreenInfo, rhs: ScreenInfo) -> Bool {
            lhs.id == rhs.id &&
            lhs.frame == rhs.frame &&
            lhs.scaleFactor == rhs.scaleFactor
        }
    }
    
    /// Multi-monitor display mode setting.
    enum DisplayMode: String, CaseIterable {
        case all = "all"
        case primary = "primary"
        case selected = "selected"
        
        var displayName: String {
            switch self {
            case .all: return "All Displays"
            case .primary: return "Primary Only"
            case .selected: return "Select Display..."
            }
        }
    }
    
    /// All detected screens.
    @Published private(set) var screens: [ScreenInfo] = []
    
    /// The total frame encompassing all screens (virtual display space).
    @Published private(set) var totalFrame: CGRect = .zero
    
    /// Number of connected displays.
    var screenCount: Int { screens.count }
    
    private init() {
        updateScreenConfiguration()
        
        // Monitor for display configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Called when screen parameters change (connect/disconnect/arrangement).
    @objc private func screensDidChange() {
        updateScreenConfiguration()
        
        // Post notification for other components to react
        NotificationCenter.default.post(name: .screenConfigurationChanged, object: nil)
    }
    
    /// Updates the internal screen configuration from NSScreen.
    private func updateScreenConfiguration() {
        let nsScreens = NSScreen.screens
        
        screens = nsScreens.enumerated().map { index, screen in
            ScreenInfo(
                id: index,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                scaleFactor: screen.backingScaleFactor,
                localizedName: screen.localizedName
            )
        }
        
        // Calculate total virtual frame
        totalFrame = calculateTotalBounds(from: nsScreens)
    }
    
    /// Calculates the bounding rectangle that contains all screens.
    private func calculateTotalBounds(from screens: [NSScreen]) -> CGRect {
        guard !screens.isEmpty else { return .zero }
        
        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity
        
        for screen in screens {
            let frame = screen.frame
            minX = min(minX, frame.minX)
            minY = min(minY, frame.minY)
            maxX = max(maxX, frame.maxX)
            maxY = max(maxY, frame.maxY)
        }
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    /// Gets the screens to use based on the display mode setting.
    /// - Parameters:
    ///   - mode: The display mode setting.
    ///   - selectedIndex: The index of the selected screen (for `.selected` mode).
    /// - Returns: Array of NSScreen objects to create windows for.
    func screensForMode(_ mode: DisplayMode, selectedIndex: Int = 0) -> [NSScreen] {
        let nsScreens = NSScreen.screens
        
        switch mode {
        case .all:
            return nsScreens
        case .primary:
            return nsScreens.first.map { [$0] } ?? []
        case .selected:
            guard selectedIndex >= 0 && selectedIndex < nsScreens.count else {
                return nsScreens.first.map { [$0] } ?? []
            }
            return [nsScreens[selectedIndex]]
        }
    }
    
    /// Returns a random position on any of the active screens.
    /// - Parameter mode: The display mode to consider.
    /// - Parameter selectedIndex: The selected screen index (for `.selected` mode).
    /// - Returns: A CGPoint within the bounds of one of the active screens.
    func randomPositionOnActiveScreens(mode: DisplayMode, selectedIndex: Int = 0) -> CGPoint {
        let activeScreens = screensForMode(mode, selectedIndex: selectedIndex)
        guard let screen = activeScreens.randomElement() else {
            // Fallback to center of primary screen or a reasonable default
            if let primaryScreen = NSScreen.main {
                return CGPoint(x: primaryScreen.frame.midX, y: primaryScreen.frame.midY)
            }
            return CGPoint(x: 400, y: 400)
        }
        
        let frame = screen.visibleFrame
        let padding: CGFloat = 150
        
        // Ensure valid ranges
        let xMin = frame.minX + padding
        let xMax = max(xMin, frame.maxX - padding)
        let yMin = frame.minY + padding
        let yMax = max(yMin, frame.maxY - padding)
        
        return CGPoint(
            x: CGFloat.random(in: xMin...xMax),
            y: CGFloat.random(in: yMin...yMax)
        )
    }
    
    /// Determines which screen contains the given point.
    /// - Parameter point: The point in global screen coordinates.
    /// - Returns: The index of the screen containing the point, or nil if not found.
    func screenIndex(containing point: CGPoint) -> Int? {
        for (index, screen) in screens.enumerated() {
            if screen.frame.contains(point) {
                return index
            }
        }
        return nil
    }
    
    /// Converts a point from global coordinates to local coordinates for a specific screen.
    /// - Parameters:
    ///   - point: The point in global screen coordinates.
    ///   - screenIndex: The index of the target screen.
    /// - Returns: The point in the screen's local coordinate space.
    func localPoint(from globalPoint: CGPoint, forScreen screenIndex: Int) -> CGPoint {
        guard screenIndex >= 0 && screenIndex < screens.count else {
            return globalPoint
        }
        
        let screen = screens[screenIndex]
        return CGPoint(
            x: globalPoint.x - screen.frame.minX,
            y: globalPoint.y - screen.frame.minY
        )
    }
    
    /// Converts a point from local screen coordinates to global coordinates.
    /// - Parameters:
    ///   - localPoint: The point in local screen coordinates.
    ///   - screenIndex: The index of the source screen.
    /// - Returns: The point in global screen coordinates.
    func globalPoint(from localPoint: CGPoint, forScreen screenIndex: Int) -> CGPoint {
        guard screenIndex >= 0 && screenIndex < screens.count else {
            return localPoint
        }
        
        let screen = screens[screenIndex]
        return CGPoint(
            x: localPoint.x + screen.frame.minX,
            y: localPoint.y + screen.frame.minY
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when screen configuration changes (monitors added/removed/rearranged).
    static let screenConfigurationChanged = Notification.Name("screenConfigurationChanged")
}
