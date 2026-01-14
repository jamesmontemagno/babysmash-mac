//
//  SparkleController.swift
//  babysmash
//
//  Sparkle auto-update integration following RepoBar pattern.
//  Disables itself for unsigned/development builds.
//
//  THREADING MODEL:
//  - Class is @MainActor for UI state (isUpdateReady)
//  - Delegate methods are nonisolated (called by Sparkle on its queue)
//  - State updates use sequence numbers to prevent races
//  - Kiosk cleanup uses DispatchQueue.main.async (never sync to avoid deadlock)
//

import Foundation
import Security
import Combine
import AppKit

#if canImport(Sparkle)
import Sparkle
#endif

/// Protocol for update functionality - allows disabling for development builds
@MainActor
protocol UpdaterProviding: AnyObject {
    var automaticallyChecksForUpdates: Bool { get set }
    var automaticallyDownloadsUpdates: Bool { get set }
    var isAvailable: Bool { get }
    func checkForUpdates(_ sender: Any?)
}

/// No-op updater used for unsigned/dev builds so Sparkle dialogs don't appear
final class DisabledUpdaterController: UpdaterProviding {
    var automaticallyChecksForUpdates: Bool = false
    var automaticallyDownloadsUpdates: Bool = false
    let isAvailable: Bool = false
    func checkForUpdates(_: Any?) {}
}

#if canImport(Sparkle)
extension SPUStandardUpdaterController: UpdaterProviding {
    var automaticallyChecksForUpdates: Bool {
        get { self.updater.automaticallyChecksForUpdates }
        set { self.updater.automaticallyChecksForUpdates = newValue }
    }
    
    var automaticallyDownloadsUpdates: Bool {
        get { self.updater.automaticallyDownloadsUpdates }
        set { self.updater.automaticallyDownloadsUpdates = newValue }
    }
    
    var isAvailable: Bool { true }
}
#endif

/// Sparkle auto-update controller singleton.
/// Automatically disables itself for unsigned/development builds.
@MainActor
final class SparkleController: NSObject, ObservableObject {
    static let shared = SparkleController()
    
    private var updater: UpdaterProviding
    private let defaultsKey = "autoUpdateEnabled"
    
    /// Whether an update is ready to install
    @Published private(set) var isUpdateReady: Bool = false
    
    /// Sequence counter for ordering state updates
    nonisolated(unsafe) private var updateStateSequence: Int = 0
    private let stateQueue = DispatchQueue(label: "com.babysmash.sparkle.state")
    
    /// Whether updates can be checked (i.e., running a signed release build)
    var canCheckForUpdates: Bool {
        updater.isAvailable
    }
    
    /// Automatic update check preference
    var automaticallyChecksForUpdates: Bool {
        get { updater.automaticallyChecksForUpdates }
        set {
            updater.automaticallyChecksForUpdates = newValue
            UserDefaults.standard.set(newValue, forKey: defaultsKey)
        }
    }
    
    /// Automatic download preference
    var automaticallyDownloadsUpdates: Bool {
        get { updater.automaticallyDownloadsUpdates }
        set { updater.automaticallyDownloadsUpdates = newValue }
    }
    
    override private init() {
        #if canImport(Sparkle)
        let bundleURL = Bundle.main.bundleURL
        let isBundledApp = bundleURL.pathExtension == "app"
        let isDevelopmentBuild = SparkleController.isDevelopmentBuild(bundleURL: bundleURL)
        let isSigned = SparkleController.isDeveloperIDSigned(bundleURL: bundleURL)
        
        // Disable Sparkle for development/unsigned builds to avoid dialogs and signature errors
        let canUseSparkle = isBundledApp && isSigned && !isDevelopmentBuild
        #else
        let canUseSparkle = false
        #endif
        
        self.updater = DisabledUpdaterController()
        super.init()
        
        #if canImport(Sparkle)
        guard canUseSparkle else {
            print("[SparkleController] Disabled - not a signed release build")
            return
        }
        
        let savedAutoCheck = (UserDefaults.standard.object(forKey: defaultsKey) as? Bool) ?? false
        let controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        controller.automaticallyChecksForUpdates = savedAutoCheck
        controller.automaticallyDownloadsUpdates = savedAutoCheck
        controller.startUpdater()
        self.updater = controller
        print("[SparkleController] Started with auto-check: \(savedAutoCheck)")
        #endif
    }
    
    /// Manually check for updates
    func checkForUpdates() {
        guard canCheckForUpdates else {
            print("[SparkleController] Cannot check for updates - not available")
            return
        }
        updater.checkForUpdates(nil)
    }
    
    // MARK: - Private Helpers
    
    /// Detects development builds by checking if running from DerivedData or Xcode
    private static func isDevelopmentBuild(bundleURL: URL) -> Bool {
        let path = bundleURL.path
        return path.contains("DerivedData") ||
               path.contains("Xcode") ||
               path.contains("Build/Products")
    }
    
    /// Checks if the app is signed with a Developer ID certificate
    private static func isDeveloperIDSigned(bundleURL: URL) -> Bool {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(bundleURL as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
              let code = staticCode else {
            print("[SparkleController] Failed to create static code for signature check at: \(bundleURL.path)")
            return false
        }
        
        var infoCF: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &infoCF) == errSecSuccess else {
            print("[SparkleController] Failed to copy signing information")
            return false
        }
        
        guard let info = infoCF as? [String: Any] else {
            print("[SparkleController] Failed to cast signing info to dictionary")
            return false
        }
        
        guard let certs = info[kSecCodeInfoCertificates as String] as? [SecCertificate] else {
            print("[SparkleController] No certificates found in signing info, keys: \(info.keys)")
            return false
        }
        
        guard let leaf = certs.first else {
            print("[SparkleController] No leaf certificate found")
            return false
        }
        
        if let summary = SecCertificateCopySubjectSummary(leaf) as String? {
            let isDeveloperID = summary.hasPrefix("Developer ID Application:")
            print("[SparkleController] Certificate: \(summary), is Developer ID: \(isDeveloperID)")
            return isDeveloperID
        }
        return false
    }
}

// MARK: - Sparkle Delegate

#if canImport(Sparkle)
extension SparkleController: SPUUpdaterDelegate {
    nonisolated func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        let sequence = self.stateQueue.sync { () -> Int in
            self.updateStateSequence += 1
            return self.updateStateSequence
        }
        Task { @MainActor in
            // Only apply if this is the latest state update
            let currentSequence = self.stateQueue.sync { self.updateStateSequence }
            guard sequence == currentSequence else { return }
            self.isUpdateReady = true
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        let sequence = self.stateQueue.sync { () -> Int in
            self.updateStateSequence += 1
            return self.updateStateSequence
        }
        Task { @MainActor in
            let currentSequence = self.stateQueue.sync { self.updateStateSequence }
            guard sequence == currentSequence else { return }
            self.isUpdateReady = false
        }
    }
    
    nonisolated func userDidCancelDownload(_ updater: SPUUpdater) {
        let sequence = self.stateQueue.sync { () -> Int in
            self.updateStateSequence += 1
            return self.updateStateSequence
        }
        Task { @MainActor in
            let currentSequence = self.stateQueue.sync { self.updateStateSequence }
            guard sequence == currentSequence else { return }
            self.isUpdateReady = false
        }
    }
    
    nonisolated func updater(
        _ updater: SPUUpdater,
        userDidMake choice: SPUUserUpdateChoice,
        forUpdate updateItem: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        let downloaded = state.stage == .downloaded
        let sequence = self.stateQueue.sync { () -> Int in
            self.updateStateSequence += 1
            return self.updateStateSequence
        }
        Task { @MainActor in
            let currentSequence = self.stateQueue.sync { self.updateStateSequence }
            guard sequence == currentSequence else { return }
            switch choice {
            case .install, .skip:
                self.isUpdateReady = false
            case .dismiss:
                self.isUpdateReady = downloaded
            @unknown default:
                self.isUpdateReady = false
            }
        }
    }

    nonisolated func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock: @escaping () -> Void) -> Bool {
        // When automatic updates are enabled, Sparkle may default to installing the update
        // "on quit" (without relaunching). For BabySmash, we prefer applying the update
        // immediately so the app actually restarts into the new version.
        let autoUpdateEnabled = UserDefaults.standard.bool(forKey: defaultsKey)
        guard autoUpdateEnabled else { return true }

        DispatchQueue.main.async {
            immediateInstallationBlock()
        }

        // We initiated immediate installation; don't also install on quit.
        return false
    }

    nonisolated func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        // Clean up kiosk mode BEFORE Sparkle tries to quit/install.
        // This is critical - without this, the app may not be able to terminate.
        // Use async to avoid deadlock - never use sync on main queue
        DispatchQueue.main.async {
            SystemKeyBlocker.shared.stopBlocking()
            NSApp.presentationOptions = []
            print("[SparkleController] Cleaned up kiosk mode for update installation")
        }
    }

    nonisolated func updaterShouldRelaunchApplication(_ updater: SPUUpdater) -> Bool {
        true
    }

    nonisolated func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        // Extra safety: ensure kiosk restrictions are cleared before relaunch
        // Use async to avoid deadlock - never use sync on main queue
        DispatchQueue.main.async {
            SystemKeyBlocker.shared.stopBlocking()
            NSApp.presentationOptions = []
            print("[SparkleController] Preparing for relaunch")
        }
    }
}
#endif
