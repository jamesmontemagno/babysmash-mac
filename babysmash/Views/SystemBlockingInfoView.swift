//
//  SystemBlockingInfoView.swift
//  babysmash
//
//  Created by James Montemagno on 1/5/26.
//

import SwiftUI

/// Onboarding view that explains system key blocking and allows enabling it
struct SystemBlockingInfoView: View {
    let onComplete: () -> Void
    
    @State private var titleOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var showSettings = false
    
    @AppStorage("blockSystemKeys") private var blockSystemKeys: Bool = false
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            HStack(spacing: 40) {
                // Left side: Title and content
                VStack(spacing: 24) {
                    // Title section
                    VStack(spacing: 12) {
                        Text("🔒")
                            .font(.system(size: 50))
                        
                        Text(L10n.Onboarding.SystemBlocking.title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                        
                        Text(L10n.Onboarding.SystemBlocking.subtitle)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(titleOpacity)
                    
                    // Content section
                    VStack(spacing: 20) {
                        // What it blocks
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.Onboarding.SystemBlocking.blocksTitle)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                blockingRow(key: "⌘Q", action: L10n.Onboarding.SystemBlocking.quitApp)
                                blockingRow(key: "⌘Tab", action: L10n.Onboarding.SystemBlocking.switchApps)
                                blockingRow(key: "⌘Space", action: L10n.Onboarding.SystemBlocking.spotlight)
                                blockingRow(key: "F3", action: L10n.Onboarding.SystemBlocking.missionControl)
                            }
                        }
                        
                        Divider()
                            .background(.white.opacity(0.3))
                        
                        // How to exit
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.Onboarding.SystemBlocking.exitTitle)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                exitRow(key: "⌥S", action: L10n.Onboarding.SystemBlocking.openSettings)
                                exitRow(key: "⌥⌘Q", action: L10n.Onboarding.SystemBlocking.exitApp)
                                exitRow(key: ". x20", action: L10n.Onboarding.SystemBlocking.emergencyExit)
                            }
                        }
                        
                        // Current status
                        HStack {
                            Image(systemName: blockSystemKeys ? "checkmark.shield.fill" : "shield.slash")
                                .foregroundStyle(blockSystemKeys ? .green : .orange)
                            
                            Text(blockSystemKeys ? L10n.Onboarding.SystemBlocking.statusEnabled : L10n.Onboarding.SystemBlocking.statusDisabled)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(blockSystemKeys ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        )
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .frame(maxWidth: 420)
                    .opacity(contentOpacity)
                }
                
                // Right side: Buttons
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Open Settings button
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                            Text(L10n.Onboarding.SystemBlocking.openSettingsButton)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Continue button
                    Button(action: onComplete) {
                        HStack(spacing: 12) {
                            Text(L10n.Onboarding.SystemBlocking.continueButton)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 22))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 200)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .purple.opacity(0.5), radius: 15, x: 0, y: 8)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .opacity(buttonOpacity)
            }
            .padding(.horizontal, 60)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func blockingRow(key: String, action: LocalizedStringResource) -> some View {
        HStack(spacing: 12) {
            Text(key)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.red.opacity(0.3))
                )
            
            Text(action)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red.opacity(0.7))
        }
    }
    
    private func exitRow(key: String, action: LocalizedStringResource) -> some View {
        HStack(spacing: 12) {
            Text(key)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.green.opacity(0.3))
                )
            
            Text(action)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green.opacity(0.7))
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            titleOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            contentOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            buttonOpacity = 1.0
        }
    }
}

#Preview {
    SystemBlockingInfoView(onComplete: {})
}
