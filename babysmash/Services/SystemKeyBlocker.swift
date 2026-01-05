//
//  SystemKeyBlocker.swift
//  babysmash
//
//  Created by James Montemagno on 1/5/26.
//

import Cocoa
import CoreGraphics

/// Blocks system keyboard shortcuts to prevent babies from accidentally
/// exiting the app, triggering Mission Control, switching apps, etc.
class SystemKeyBlocker: ObservableObject {
    static let shared = SystemKeyBlocker()
    
    @Published private(set) var isBlocking: Bool = false
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Key codes for blocked keys
    private static let blockedKeyCodes: Set<Int64> = [
        48,  // Tab (Cmd+Tab)
        12,  // Q (Cmd+Q)
        13,  // W (Cmd+W)
        4,   // H (Cmd+H)
        46,  // M (Cmd+M)
        126, // Up Arrow (Ctrl+Up for Mission Control)
        125, // Down Arrow (Ctrl+Down for App Exposé)
        123, // Left Arrow (Ctrl+Left for Switch Spaces)
        124, // Right Arrow (Ctrl+Right for Switch Spaces)
        99,  // F3 (Mission Control)
        103, // F11 (Show Desktop)
    ]
    
    // Emergency exit key code: Escape (53) with Opt+Cmd
    private static let escapeKeyCode: Int64 = 53
    
    // Settings shortcut: S key code
    private static let sKeyCode: Int64 = 1
    
    private init() {}
    
    /// Starts blocking system keyboard shortcuts.
    /// - Returns: `true` if blocking started successfully, `false` if permissions are missing.
    @discardableResult
    func startBlocking() -> Bool {
        guard !isBlocking else { return true }
        
        // Check accessibility permission first
        guard AccessibilityManager.isAccessibilityEnabled() else {
            print("SystemKeyBlocker: Accessibility permission not granted")
            return false
        }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        // Create the event tap
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                return SystemKeyBlocker.handleEvent(proxy: proxy, type: type, event: event, refcon: refcon)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("SystemKeyBlocker: Failed to create event tap - accessibility permissions required")
            return false
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            isBlocking = true
            print("SystemKeyBlocker: Started blocking system keys")
            return true
        }
        
        return false
    }
    
    /// Stops blocking system keyboard shortcuts.
    func stopBlocking() {
        guard isBlocking else { return }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isBlocking = false
        print("SystemKeyBlocker: Stopped blocking system keys")
    }
    
    /// Event callback that filters keyboard events.
    private static func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        
        // Re-enable tap if it was disabled by timeout or user input
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let refcon = refcon {
                let blocker = Unmanaged<SystemKeyBlocker>.fromOpaque(refcon).takeUnretainedValue()
                if let tap = blocker.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            }
            return Unmanaged.passRetained(event)
        }
        
        // Only process key down and key up events
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // ALLOW: Emergency exit with Opt+Cmd+Esc (Force Quit dialog)
        if flags.contains([.maskAlternate, .maskCommand]) && keyCode == escapeKeyCode {
            return Unmanaged.passRetained(event)
        }
        
        // ALLOW: Settings shortcut with Opt+S (no Cmd)
        if flags.contains(.maskAlternate) && !flags.contains(.maskCommand) && keyCode == sKeyCode {
            return Unmanaged.passRetained(event)
        }
        
        // BLOCK: Cmd+key combinations (Tab, Q, W, H, M)
        if flags.contains(.maskCommand) {
            if keyCode == 48 ||  // Tab (Cmd+Tab)
               keyCode == 12 ||  // Q (Cmd+Q)
               keyCode == 13 ||  // W (Cmd+W)
               keyCode == 4 ||   // H (Cmd+H)
               keyCode == 46 {   // M (Cmd+M)
                return nil // Block the event
            }
        }
        
        // BLOCK: Ctrl+arrow combinations (Mission Control / Spaces)
        if flags.contains(.maskControl) {
            if keyCode >= 123 && keyCode <= 126 { // Arrow keys
                return nil // Block the event
            }
        }
        
        // BLOCK: F3 (Mission Control) and F11 (Show Desktop)
        if keyCode == 99 || keyCode == 103 {
            return nil // Block the event
        }
        
        // Allow all other events
        return Unmanaged.passRetained(event)
    }
    
    deinit {
        stopBlocking()
    }
}
