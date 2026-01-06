//
//  SystemKeyBlocker.swift
//  babysmash
//
//  Created by James Montemagno on 1/5/26.
//

import Cocoa
import Combine
import CoreGraphics
import Carbon.HIToolbox

/// Blocks system keyboard shortcuts to prevent babies from accidentally
/// exiting the app, triggering Mission Control, switching apps, etc.
class SystemKeyBlocker: ObservableObject {
    static let shared = SystemKeyBlocker()
    
    @Published private(set) var isBlocking: Bool = false
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Hot key references for Carbon-based blocking (more reliable for some shortcuts)
    private var spotlightHotKeyRef: EventHotKeyRef?
    private var altSpotlightHotKeyRef: EventHotKeyRef?
    private var missionControlHotKeyRef: EventHotKeyRef?
    private var appExposeHotKeyRef: EventHotKeyRef?
    private var hotKeyEventHandler: EventHandlerRef?
    
    // MARK: - Blocked Key Codes
    
    // Key codes for blocked Cmd+key combinations
    private static let blockedCmdKeyCodes: Set<Int64> = [
        48,  // Tab (Cmd+Tab - app switcher)
        12,  // Q (Cmd+Q - quit)
        13,  // W (Cmd+W - close window)
        4,   // H (Cmd+H - hide)
        46,  // M (Cmd+M - minimize)
        0,   // A (Cmd+A - select all, prevent accidents)
        6,   // Z (Cmd+Z - undo)
        7,   // X (Cmd+X - cut)
        8,   // C (Cmd+C - copy)
        9,   // V (Cmd+V - paste)
        35,  // P (Cmd+P - print)
        45,  // N (Cmd+N - new window)
        31,  // O (Cmd+O - open)
        3,   // F (Cmd+F - find)
        5,   // G (Cmd+G - find next)
        37,  // L (Cmd+L - location bar)
        15,  // R (Cmd+R - refresh)
        17,  // T (Cmd+T - new tab)
        1,   // S (Cmd+S - save) - Note: Opt+S is still allowed for settings
        32,  // U (Cmd+U - view source)
        34,  // I (Cmd+I - inspector)
        40,  // K (Cmd+K - various)
        41,  // ; (Cmd+; - spell check)
        44,  // / (Cmd+/ - comment)
        30,  // ] (Cmd+] - indent)
        33,  // [ (Cmd+[ - outdent)
        27,  // - (Cmd+- - zoom out)
        24,  // = (Cmd+= - zoom in)
        29,  // 0 (Cmd+0 - reset zoom)
        50,  // ` (Cmd+` - switch window)
        36,  // Return (Cmd+Return - various)
        51,  // Delete (Cmd+Delete - delete)
        49,  // Space (Cmd+Space - Spotlight)
    ]
    
    // Key codes for Ctrl+key combinations
    private static let blockedCtrlKeyCodes: Set<Int64> = [
        126, // Up Arrow (Ctrl+Up - Mission Control)
        125, // Down Arrow (Ctrl+Down - App Exposé)
        123, // Left Arrow (Ctrl+Left - Switch Space left)
        124, // Right Arrow (Ctrl+Right - Switch Space right)
        18,  // 1 (Ctrl+1 - Switch to Desktop 1)
        19,  // 2 (Ctrl+2 - Switch to Desktop 2)
        20,  // 3 (Ctrl+3 - Switch to Desktop 3)
        21,  // 4 (Ctrl+4 - Switch to Desktop 4)
        23,  // 5 (Ctrl+5 - etc.)
        22,  // 6
        26,  // 7
        28,  // 8
        25,  // 9
    ]
    
    // Function key codes to block
    private static let blockedFunctionKeyCodes: Set<Int64> = [
        122, // F1 (Help/Brightness down on some Macs)
        120, // F2 (Brightness up)
        99,  // F3 (Mission Control)
        118, // F4 (Launchpad)
        96,  // F5 (Keyboard brightness down)
        97,  // F6 (Keyboard brightness up)
        98,  // F7 (Previous track)
        100, // F8 (Play/Pause)
        101, // F9 (Next track)
        109, // F10 (Mute)
        103, // F11 (Show Desktop / Volume down)
        111, // F12 (Volume up)
        105, // F13
        107, // F14
        113, // F15
        106, // F16
        64,  // F17
        79,  // F18
        80,  // F19
        90,  // F20
    ]
    
    // Media and special keys to block (NX key codes via special key events)
    private static let blockedSpecialKeyCodes: Set<Int64> = [
        10,  // Mute (some keyboards)
        145, // Brightness Down
        144, // Brightness Up
        130, // Dashboard (older Macs)
        131, // Launchpad
        160, // Expose All
        48,  // Backtick for switching windows
    ]
    
    // Standalone keys to always block (no modifier needed)
    private static let blockedStandaloneKeyCodes: Set<Int64> = [
        53,  // Escape (block standalone, but allow Opt+Cmd+Esc)
        115, // Home
        119, // End
        116, // Page Up
        121, // Page Down
        117, // Forward Delete
        114, // Help/Insert
        71,  // Clear
    ]
    
    // Exit shortcut: Q (12) with Opt+Cmd
    private static let qKeyCode: Int64 = 12
    
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
        
        // Listen for key events and special system-defined events (media keys)
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << NX_SYSDEFINED)
        
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
            
            // Register Carbon hot keys for Spotlight and other shortcuts that bypass event taps
            registerCarbonHotKeys()
            
            return true
        }
        
        return false
    }
    
    // MARK: - Carbon Hot Keys (More reliable for Spotlight)
    
    /// Registers Carbon hot keys to intercept shortcuts that may bypass CGEvent taps.
    /// This is particularly effective for Cmd+Space (Spotlight).
    private func registerCarbonHotKeys() {
        // Set up the event handler for hot key events
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // Install handler using GetEventDispatcherTarget for global interception
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            hotKeyHandler,
            1,
            &eventType,
            nil,
            &hotKeyEventHandler
        )
        
        if status != noErr {
            print("SystemKeyBlocker: Failed to install hot key handler, status: \(status)")
        }
        
        // Register Cmd+Space (Spotlight) - ID 1
        var spotlightHotKeyID = EventHotKeyID(signature: OSType(0x42534D48), id: 1) // "BSMH" = BabySmash Hotkey
        let spotlightStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(cmdKey),
            spotlightHotKeyID,
            GetEventDispatcherTarget(),
            OptionBits(0),
            &spotlightHotKeyRef
        )
        
        if spotlightStatus != noErr {
            print("SystemKeyBlocker: Failed to register Spotlight hot key, status: \(spotlightStatus)")
        } else {
            print("SystemKeyBlocker: Registered Cmd+Space hot key")
        }
        
        // Also register Cmd+Option+Space (alternative Spotlight shortcut)
        var altSpotlightHotKeyID = EventHotKeyID(signature: OSType(0x42534D48), id: 3)
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(cmdKey | optionKey),
            altSpotlightHotKeyID,
            GetEventDispatcherTarget(),
            OptionBits(0),
            &altSpotlightHotKeyRef
        )
        
        // Register Ctrl+Up (Mission Control) - ID 2
        var missionControlHotKeyID = EventHotKeyID(signature: OSType(0x42534D48), id: 2)
        RegisterEventHotKey(
            UInt32(kVK_UpArrow),
            UInt32(controlKey),
            missionControlHotKeyID,
            GetEventDispatcherTarget(),
            OptionBits(0),
            &missionControlHotKeyRef
        )
        
        // Register Ctrl+Down (App Exposé)
        var appExposeHotKeyID = EventHotKeyID(signature: OSType(0x42534D48), id: 4)
        RegisterEventHotKey(
            UInt32(kVK_DownArrow),
            UInt32(controlKey),
            appExposeHotKeyID,
            GetEventDispatcherTarget(),
            OptionBits(0),
            &appExposeHotKeyRef
        )
        
        print("SystemKeyBlocker: Registered Carbon hot keys for Spotlight and Mission Control")
    }
    
    /// Unregisters Carbon hot keys.
    private func unregisterCarbonHotKeys() {
        if let ref = spotlightHotKeyRef {
            UnregisterEventHotKey(ref)
            spotlightHotKeyRef = nil
        }
        if let ref = altSpotlightHotKeyRef {
            UnregisterEventHotKey(ref)
            altSpotlightHotKeyRef = nil
        }
        if let ref = missionControlHotKeyRef {
            UnregisterEventHotKey(ref)
            missionControlHotKeyRef = nil
        }
        if let ref = appExposeHotKeyRef {
            UnregisterEventHotKey(ref)
            appExposeHotKeyRef = nil
        }
        if let handler = hotKeyEventHandler {
            RemoveEventHandler(handler)
            hotKeyEventHandler = nil
        }
        print("SystemKeyBlocker: Unregistered Carbon hot keys")
    }
    
    /// Stops blocking system keyboard shortcuts.
    func stopBlocking() {
        guard isBlocking else { return }
        
        // Unregister Carbon hot keys first
        unregisterCarbonHotKeys()
        
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
        
        // Handle system-defined events (media keys, brightness, etc.)
        if type.rawValue == UInt32(NX_SYSDEFINED) {
            return handleSystemDefinedEvent(event)
        }
        
        // Only process key down and key up events
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // ALLOW: Exit shortcut with Opt+Cmd+Q
        if flags.contains([.maskAlternate, .maskCommand]) && keyCode == qKeyCode {
            return Unmanaged.passRetained(event)
        }
        
        // ALLOW: Settings shortcut with Opt+S (no Cmd)
        if flags.contains(.maskAlternate) && !flags.contains(.maskCommand) && keyCode == sKeyCode {
            return Unmanaged.passRetained(event)
        }
        
        // BLOCK: Cmd+key combinations
        if flags.contains(.maskCommand) && blockedCmdKeyCodes.contains(keyCode) {
            return nil
        }
        
        // BLOCK: Ctrl+key combinations (Mission Control / Spaces / Desktop switching)
        if flags.contains(.maskControl) && blockedCtrlKeyCodes.contains(keyCode) {
            return nil
        }
        
        // BLOCK: Cmd+Shift combinations (common shortcuts)
        if flags.contains([.maskCommand, .maskShift]) {
            // Block most Cmd+Shift combinations
            return nil
        }
        
        // BLOCK: Cmd+Option combinations (common system shortcuts)
        // But allow Opt+Cmd+Q for exit
        if flags.contains([.maskCommand, .maskAlternate]) && keyCode != qKeyCode {
            return nil
        }
        
        // BLOCK: Function keys (F1-F20)
        if blockedFunctionKeyCodes.contains(keyCode) {
            return nil
        }
        
        // BLOCK: Standalone special keys (Escape without modifiers, etc.)
        if blockedStandaloneKeyCodes.contains(keyCode) {
            // Only block if no important modifiers (allow Opt+Cmd+Q)
            if !flags.contains([.maskAlternate, .maskCommand]) {
                return nil
            }
        }
        
        // Allow all other events (regular typing)
        return Unmanaged.passRetained(event)
    }
    
    /// Handle system-defined events like media keys
    private static func handleSystemDefinedEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        // Get the NSEvent to check subtype
        guard let nsEvent = NSEvent(cgEvent: event) else {
            return Unmanaged.passRetained(event)
        }
        
        // Subtype 8 is for media keys (play, pause, volume, brightness, etc.)
        if nsEvent.subtype.rawValue == 8 {
            let data1 = nsEvent.data1
            let keyCode = (data1 & 0xFFFF0000) >> 16
            
            // Media key codes
            let blockedMediaKeys: Set<Int> = [
                0,   // Brightness Down (on some keyboards)
                1,   // Brightness Up
                2,   // Expose / Mission Control
                3,   // Dashboard
                4,   // Launchpad
                5,   // Keyboard Brightness Down
                6,   // Keyboard Brightness Up
                7,   // Previous Track
                8,   // Play/Pause
                9,   // Next Track
                10,  // Mute
                11,  // Volume Down
                12,  // Volume Up
                16,  // Sound volume
                17,  // Contrast up
                18,  // Contrast down
                19,  // Mode key
                20,  // Eject
                21,  // Power key
                22,  // Video mirror toggle
                23,  // Help key
            ]
            
            if blockedMediaKeys.contains(keyCode) {
                return nil // Block media key
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    deinit {
        stopBlocking()
    }
}

// NX event type constant for system-defined events
private let NX_SYSDEFINED: Int32 = 14

// Global Carbon hot key handler - must be a C function pointer
private func hotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    // Consume the event by returning noErr - this blocks the shortcut
    print("SystemKeyBlocker: Blocked hot key event")
    return noErr
}
