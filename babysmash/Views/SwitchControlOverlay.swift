//
//  SwitchControlManager.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI
import Combine

/// Manages switch control accessibility mode
/// Provides scanning through actions and selection via switch input
class SwitchControlManager: ObservableObject {
    static let shared = SwitchControlManager()
    
    @Published var currentHighlightIndex: Int = 0
    @Published var isScanning: Bool = false
    
    /// Available actions for switch control
    let actions: [SwitchAction] = SwitchAction.allCases
    
    enum SwitchAction: String, CaseIterable, Identifiable {
        case showRandomShape = "Show Shape"
        case showRandomLetter = "Show Letter"
        case showRandomNumber = "Show Number"
        case clearScreen = "Clear Screen"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .showRandomShape: return "circle.hexagongrid.fill"
            case .showRandomLetter: return "textformat.abc"
            case .showRandomNumber: return "number"
            case .clearScreen: return "xmark.circle.fill"
            }
        }
    }
    
    private var scanTimer: Timer?
    
    /// The interval between highlight advances
    var scanInterval: TimeInterval = 2.0
    
    /// Callback when an action is selected
    var onActionSelected: ((SwitchAction) -> Void)?
    
    private init() {}
    
    /// Starts the scanning cycle
    func startScanning() {
        guard !isScanning else { return }
        
        isScanning = true
        currentHighlightIndex = 0
        
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] _ in
            self?.advanceHighlight()
        }
    }
    
    /// Stops the scanning cycle
    func stopScanning() {
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
    }
    
    /// Selects the currently highlighted action
    func selectCurrentAction() {
        guard isScanning else { return }
        
        let action = actions[currentHighlightIndex]
        onActionSelected?(action)
    }
    
    /// Advances to the next highlighted item
    private func advanceHighlight() {
        currentHighlightIndex = (currentHighlightIndex + 1) % actions.count
    }
    
    /// Updates the scan interval
    func setScanInterval(_ interval: TimeInterval) {
        scanInterval = interval
        if isScanning {
            stopScanning()
            startScanning()
        }
    }
    
    /// Toggles scanning on/off
    func toggle() {
        if isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }
    
    deinit {
        stopScanning()
    }
}

// MARK: - Switch Control Overlay View

/// Visual overlay for switch control mode
/// Shows the available actions with the current one highlighted
struct SwitchControlOverlay: View {
    @ObservedObject private var manager = SwitchControlManager.shared
    
    var body: some View {
        if manager.isScanning {
            VStack {
                Spacer()
                
                HStack(spacing: 20) {
                    ForEach(Array(manager.actions.enumerated()), id: \.element.id) { index, action in
                        SwitchActionButton(
                            action: action,
                            isHighlighted: index == manager.currentHighlightIndex
                        )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.black.opacity(0.85))
                        .shadow(color: .black.opacity(0.3), radius: 20)
                )
                .padding(.bottom, 50)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .allowsHitTesting(false)  // Switch control uses external input
        }
    }
}

/// Individual action button in the switch control overlay
struct SwitchActionButton: View {
    let action: SwitchControlManager.SwitchAction
    let isHighlighted: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: action.iconName)
                .font(.system(size: 32, weight: .semibold))
            
            Text(action.rawValue)
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        .foregroundColor(isHighlighted ? .black : .white)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isHighlighted ? Color.yellow : Color.gray.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHighlighted ? Color.orange : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isHighlighted ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
    }
}

// MARK: - Preview

#Preview("Switch Control Overlay") {
    ZStack {
        Color.black
        
        SwitchControlOverlay()
    }
    .frame(width: 800, height: 600)
    .onAppear {
        SwitchControlManager.shared.startScanning()
    }
}
