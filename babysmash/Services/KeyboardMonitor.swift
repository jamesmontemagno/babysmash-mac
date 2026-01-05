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
    
    deinit {
        stopMonitoring()
    }
}

extension Notification.Name {
    static let showSettings = Notification.Name("showSettings")
}
