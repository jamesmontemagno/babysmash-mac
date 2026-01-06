//
//  KeyboardMonitor.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import AppKit
import Combine

class KeyboardMonitor: ObservableObject {
    @Published var lastKeyPressed: KeyEvent?
    
    private var localMonitor: Any?
    
    // Emergency exit: track rapid period key presses
    private var periodPressCount = 0
    private var periodPressStartTime: Date?
    private let periodPressThreshold = 20
    private let periodPressTimeWindow: TimeInterval = 10.0 // Must press 20 times within 10 seconds
    
    // Prevent multiple exit dialogs
    private var isShowingExitDialog = false
    
    struct KeyEvent {
        let characters: String?
        let keyCode: UInt16
        let isLetter: Bool
        let isNumber: Bool
        let timestamp: Date
        
        var displayCharacter: Character? {
            guard let chars = characters, let first = chars.uppercased().first else {
                return nil
            }
            return first
        }
    }
    
    func startMonitoring() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // Consume the event (don't pass to other responders)
        }
    }
    
    func stopMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Check for settings shortcut: Option + S
        if event.modifierFlags.contains(.option) && event.charactersIgnoringModifiers == "s" {
            NotificationCenter.default.post(name: .showSettings, object: nil)
            return
        }
        
        // Check for quit shortcut: Option + Command + Q
        if event.modifierFlags.contains([.option, .command]) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            showExitConfirmation()
            return
        }
        
        // Check for emergency exit: rapid period key presses
        if event.charactersIgnoringModifiers == "." {
            handlePeriodPress()
            return
        } else {
            // Reset period counter if any other key is pressed
            resetPeriodCounter()
        }
        
        let characters = event.charactersIgnoringModifiers
        let keyCode = event.keyCode
        
        let isLetter = characters?.first?.isLetter ?? false
        let isNumber = characters?.first?.isNumber ?? false
        
        let keyEvent = KeyEvent(
            characters: characters,
            keyCode: keyCode,
            isLetter: isLetter,
            isNumber: isNumber,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.lastKeyPressed = keyEvent
        }
    }
    
    // MARK: - Emergency Exit (Rapid Period Presses)
    
    private func handlePeriodPress() {
        let now = Date()
        
        // Check if we're within the time window
        if let startTime = periodPressStartTime {
            if now.timeIntervalSince(startTime) > periodPressTimeWindow {
                // Time window expired, restart counting
                resetPeriodCounter()
            }
        }
        
        // Start tracking if this is the first press
        if periodPressStartTime == nil {
            periodPressStartTime = now
        }
        
        periodPressCount += 1
        
        // Check if threshold reached
        if periodPressCount >= periodPressThreshold {
            resetPeriodCounter()
            showExitConfirmation()
        }
    }
    
    private func resetPeriodCounter() {
        periodPressCount = 0
        periodPressStartTime = nil
    }
    
    // MARK: - Exit Confirmation Dialog
    
    private func showExitConfirmation() {
        // Prevent multiple dialogs
        guard !isShowingExitDialog else { return }
        isShowingExitDialog = true
        
        DispatchQueue.main.async { [weak self] in
            let alert = NSAlert()
            alert.messageText = "Exit BabySmash?"
            alert.informativeText = "Are you sure you want to quit BabySmash?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Quit")
            alert.addButton(withTitle: "Cancel")
            
            // Make the alert appear above our kiosk window
            if let window = NSApp.keyWindow {
                alert.beginSheetModal(for: window) { [weak self] response in
                    self?.isShowingExitDialog = false
                    if response == .alertFirstButtonReturn {
                        NSApplication.shared.terminate(nil)
                    }
                }
            } else {
                // Fallback: show as modal dialog
                let response = alert.runModal()
                self?.isShowingExitDialog = false
                if response == .alertFirstButtonReturn {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

extension Notification.Name {
    static let showSettings = Notification.Name("showSettings")
}
