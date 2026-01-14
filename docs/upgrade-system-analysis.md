# BabySmash Upgrade System - Code Analysis Report

**Date:** January 13, 2026  
**Version:** 0.0.5  
**Scope:** SparkleController.swift, SystemKeyBlocker.swift, and related update infrastructure

---

## Executive Summary

This report presents a comprehensive analysis of the BabySmash upgrade system, focusing on the Sparkle auto-update integration and system key blocking functionality. The analysis identified **22 distinct issues** ranging from critical deadlock risks to minor code organization concerns.

### Risk Breakdown
- **Critical Issues:** 3 (Deadlock risks)
- **High Issues:** 2 (Race conditions leading to crashes)
- **Medium Issues:** 13 (Memory leaks, state races, error handling)
- **Low Issues:** 4 (Code organization, maintainability)

### Key Findings
1. **Deadlock hazards** in update lifecycle callbacks could hang the app during installation
2. **Race conditions** in SystemKeyBlocker could cause crashes or inconsistent state
3. **Memory leaks** from Carbon hot key handlers and retain cycles
4. **State management issues** with concurrent access to flags and update status
5. **Error handling gaps** providing false sense of security to users

---

## 1. Threading Issues (Critical & High Priority)

### 1.1 Deadlock Risk in `willInstallUpdate()` ⚠️ CRITICAL

**Location:** `SparkleController.swift`, lines 217-231

**Code:**
```swift
nonisolated func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
    // Use async to avoid potential deadlock if already on main thread
    if Thread.isMainThread {
        SystemKeyBlocker.shared.stopBlocking()
        NSApp.presentationOptions = []
    } else {
        DispatchQueue.main.sync {                   // ❌ DEADLOCK RISK
            SystemKeyBlocker.shared.stopBlocking()
            NSApp.presentationOptions = []
        }
    }
}
```

**Problem:**
- `DispatchQueue.main.sync` creates a deadlock hazard when called from certain contexts
- Even though there's a `Thread.isMainThread` check, this doesn't prevent all deadlock scenarios
- Sparkle may call this delegate from a queue that's waiting for main thread work
- The comment says "avoid potential deadlock" but the implementation still has the risk

**Impact:**
- App hangs during update installation
- User cannot proceed with update, requiring force-kill
- Updates fail to install properly

**Deadlock Scenario:**
```
1. Sparkle internal queue dispatches work to main thread
2. Main thread is processing something
3. Sparkle calls delegate from its queue (not main thread)
4. Delegate checks Thread.isMainThread (false)
5. Delegate calls DispatchQueue.main.sync
6. Main thread is still busy with Sparkle's first dispatch
7. DEADLOCK - each waits for the other
```

**Recommendation:**
Replace with `DispatchQueue.main.async` - there's no need to block during cleanup:
```swift
nonisolated func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
    DispatchQueue.main.async {
        SystemKeyBlocker.shared.stopBlocking()
        NSApp.presentationOptions = []
    }
    print("[SparkleController] Cleaned up kiosk mode for update installation")
}
```

---

### 1.2 Deadlock Risk in `updaterWillRelaunchApplication()` ⚠️ CRITICAL

**Location:** `SparkleController.swift`, lines 237-250

**Code:**
```swift
nonisolated func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
    // Extra safety: ensure kiosk restrictions are cleared before relaunch
    if Thread.isMainThread {
        SystemKeyBlocker.shared.stopBlocking()
        NSApp.presentationOptions = []
    } else {
        DispatchQueue.main.sync {                   // ❌ SAME DEADLOCK RISK
            SystemKeyBlocker.shared.stopBlocking()
            NSApp.presentationOptions = []
        }
    }
    print("[SparkleController] Preparing for relaunch")
}
```

**Problem:**
- Identical deadlock hazard as issue 1.1
- Called just before app relaunch, making it even more critical
- If deadlock occurs, app won't relaunch properly

**Impact:**
- Update installation fails
- App stuck in limbo state
- User sees frozen screen

**Recommendation:**
Same fix - replace with `DispatchQueue.main.async`

---

### 1.3 Race Condition in `stopBlocking()` ⚠️ HIGH

**Location:** `SystemKeyBlocker.swift`, lines 292-308

**Code:**
```swift
func stopBlocking() {
    guard isBlocking else { return }
    
    unregisterCarbonHotKeys()
    
    if let tap = eventTap {
        CGEvent.tapEnable(tap: tap, enable: false)   // ❌ Race condition
    }
    if let source = runLoopSource {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
    }
    eventTap = nil                                   // ❌ Not thread-safe
    runLoopSource = nil                              // ❌ Not thread-safe
    isBlocking = false                               // ❌ Not atomic
}
```

**Problem:**
- Multiple non-atomic operations on instance variables
- No synchronization protecting concurrent access
- The CGEvent callback (`handleEvent()` at line 311) can access these variables while they're being nullified
- Multiple threads can call `stopBlocking()` simultaneously

**Race Condition Scenario 1 (Use-after-free):**
```
Thread A (SparkleController): stopBlocking()
Thread B (CGEvent callback): handleEvent() reads blocker.eventTap

Timeline:
T1: Thread A enters stopBlocking()
T2: Thread B enters handleEvent(), reads blocker.eventTap (non-nil)
T3: Thread A sets eventTap = nil
T4: Thread B tries to use the tap → CRASH (accessing freed memory)
```

**Race Condition Scenario 2 (Double cleanup):**
```
Thread A: stopBlocking() checks isBlocking (true)
Thread B: stopBlocking() checks isBlocking (still true, no lock)
Thread A: Begins cleanup, sets isBlocking = false
Thread B: Also begins cleanup (parallel)
Result: Double cleanup, potential crashes in CFRunLoopRemoveSource
```

**Impact:**
- Crashes when accessing freed event tap
- Double-free crashes in Core Foundation
- Inconsistent state where blocking appears stopped but handlers remain active

**Recommendation:**
Add proper synchronization using a serial DispatchQueue:
```swift
class SystemKeyBlocker: ObservableObject {
    private let queue = DispatchQueue(label: "com.babysmash.systemkeyblocker")
    
    func stopBlocking() {
        queue.sync {
            guard isBlocking else { return }
            
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
        }
    }
}
```

---

### 1.4 Race Condition in `handleEvent()` Callback ⚠️ HIGH

**Location:** `SystemKeyBlocker.swift`, lines 311-326

**Code:**
```swift
private static func handleEvent(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let refcon = refcon {
            let blocker = Unmanaged<SystemKeyBlocker>.fromOpaque(refcon).takeUnretainedValue()
            if let tap = blocker.eventTap {           // ❌ Race with stopBlocking()
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
        return Unmanaged.passRetained(event)
    }
    // ...
}
```

**Problem:**
- Reading `blocker.eventTap` without synchronization
- The reference from `takeUnretainedValue()` is not retained
- Concurrent access while `stopBlocking()` nullifies the tap
- `blocker` could be deallocated during callback execution

**Impact:**
- Crash on nil dereference
- Use-after-free if blocker is deallocated
- Undefined behavior from concurrent access

**Recommendation:**
Either:
1. Use the serial queue from recommendation 1.3, OR
2. Make eventTap access thread-safe with atomic operations, OR
3. Keep a strong reference during the callback

---

### 1.5 Main Actor Isolation Concerns ⚠️ MEDIUM

**Location:** `SparkleController.swift`, lines 165-200

**Code:**
```swift
@MainActor
final class SparkleController: NSObject, ObservableObject {
    @Published private(set) var isUpdateReady: Bool = false
    
    // Delegate methods are nonisolated
    nonisolated func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        Task { @MainActor in
            self.isUpdateReady = true
        }
    }
}
```

**Problem:**
- Class is `@MainActor` but delegate methods are `nonisolated`
- Requires explicit `Task @MainActor` wrapping for every property access
- `state.stage` (line 189) is accessed in nonisolated context without protection
- No guarantee Task will execute if system is shutting down

**Impact:**
- Potential data race if Task wrapper is forgotten
- State updates may be lost during shutdown
- More complex code that's harder to verify

**Recommendation:**
Consider making properties accessible from any thread using thread-safe wrappers, or use explicit `DispatchQueue.main.async` for clarity.

---

## 2. Memory Management Issues

### 2.1 Memory Leak in Carbon Hot Key Registration ⚠️ MEDIUM

**Location:** `SystemKeyBlocker.swift`, lines 195-264

**Code:**
```swift
private func registerCarbonHotKeys() {
    var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), 
                                  eventKind: UInt32(kEventHotKeyPressed))
    
    let status = InstallEventHandler(
        GetEventDispatcherTarget(),
        hotKeyHandler,                              // Global C function
        1,
        &eventType,
        nil,
        &hotKeyEventHandler
    )
    
    if status != noErr {
        print("SystemKeyBlocker: Failed to install hot key handler, status: \(status)")
        // ❌ No cleanup, no recovery
    }
    
    // Register multiple hot keys...
}
```

**Problem:**
- If `InstallEventHandler` succeeds but hot key registration fails, handler leaks
- Multiple handlers can accumulate if start/stop is called repeatedly
- `unregisterCarbonHotKeys()` only removes if `hotKeyEventHandler` is set
- No tracking of partial registration state

**Impact:**
- Event handlers remain active after cleanup
- Memory leak (small, but grows with start/stop cycles)
- Ghost handlers may fire unexpectedly

**Recommendation:**
Track partial state and ensure cleanup:
```swift
private var didInstallEventHandler = false

private func registerCarbonHotKeys() {
    // Install handler
    let status = InstallEventHandler(...)
    if status == noErr {
        didInstallEventHandler = true
    }
    
    // Register hot keys with error tracking
    var registrationErrors: [String] = []
    if RegisterEventHotKey(...) != noErr {
        registrationErrors.append("Spotlight")
    }
    
    if !registrationErrors.isEmpty {
        print("Failed to register: \(registrationErrors.joined(separator: ", "))")
    }
}
```

---

### 2.2 Retain Cycle in SparkleController ⚠️ MEDIUM

**Location:** `SparkleController.swift`, lines 106-114

**Code:**
```swift
let controller = SPUStandardUpdaterController(
    startingUpdater: false,
    updaterDelegate: self,                         // ❌ Strong reference to self
    userDriverDelegate: nil
)
controller.startUpdater()
self.updater = controller                          // ❌ Strong reference to controller
```

**Problem:**
- SparkleController holds strong reference to `updater` controller
- Controller holds strong reference to `updaterDelegate` (self)
- Creates retain cycle: `SparkleController → controller → SparkleController`
- Cycle never breaks (singleton lives forever, but still wastes memory)

**Impact:**
- Memory leak of both objects
- Increased memory footprint (small, ~few KB)
- Not critical since singleton, but poor practice

**Recommendation:**
Use a separate delegate object or investigate if Sparkle uses weak references:
```swift
// Option 1: Separate delegate
private class DelegateObject: NSObject, SPUUpdaterDelegate {
    weak var controller: SparkleController?
    // Implement delegate methods
}

// Option 2: Check if Sparkle framework uses weak delegate
// (may require framework inspection)
```

---

### 2.3 CFRunLoopSource Not Retained Properly ⚠️ MEDIUM

**Location:** `SystemKeyBlocker.swift`, lines 174-178

**Code:**
```swift
eventTap = tap
runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

if let source = runLoopSource {
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
}
```

**Problem:**
- `CFMachPortCreateRunLoopSource` returns non-retained reference (create rule)
- Should be retained for storage in instance property
- May be deallocated while still in use by run loop

**Impact:**
- Potential use-after-free of run loop source
- Run loop may reference freed memory
- Intermittent crashes in event handling

**Recommendation:**
Properly bridge to ARC-managed type:
```swift
let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
if let source = source {
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    self.runLoopSource = source as RunLoopSource  // Bridge to retain
}
```

Or explicitly retain:
```swift
if let source = runLoopSource {
    CFRetain(source)  // Ensure retained
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
}
```

---

## 3. UI Blocking Operations

### 3.1 Blocking Main Thread with UserDefaults ⚠️ LOW-MEDIUM

**Location:** `SparkleController.swift`, line 206

**Code:**
```swift
nonisolated func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, 
                        immediateInstallationBlock: @escaping () -> Void) -> Bool {
    let autoUpdateEnabled = UserDefaults.standard.bool(forKey: defaultsKey)  // ❌ Blocking I/O
    guard autoUpdateEnabled else { return true }
    // ...
}
```

**Problem:**
- `UserDefaults.standard.bool()` is synchronous I/O operation
- May block if UserDefaults is syncing to disk
- Called from Sparkle delegate queue, blocks that queue

**Impact:**
- Minor delay during update check
- Potential timeout if disk I/O is slow
- Sparkle framework may timeout waiting for delegate

**Recommendation:**
Cache the preference or accept the minor blocking (low priority fix):
```swift
private var cachedAutoUpdateEnabled: Bool = false

init() {
    self.cachedAutoUpdateEnabled = UserDefaults.standard.bool(forKey: defaultsKey)
}
```

---

### 3.2 Blocking Security Framework Calls During Init ⚠️ MEDIUM

**Location:** `SparkleController.swift`, lines 139-158

**Code:**
```swift
private static func isDeveloperIDSigned(bundleURL: URL) -> Bool {
    var staticCode: SecStaticCode?
    guard SecStaticCodeCreateWithPath(bundleURL as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
          let code = staticCode else {
        return false
    }
    
    var infoCF: CFDictionary?
    guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), 
                                       &infoCF) == errSecSuccess,
          let info = infoCF as? [String: Any],
          let certs = info[kSecCodeInfoCertificates as String] as? [SecCertificate],
          let leaf = certs.first else {
        return false
    }
    // ...
}
```

**Problem:**
- `SecStaticCodeCreateWithPath` and `SecCodeCopySigningInformation` are synchronous
- Can block on filesystem I/O and cryptographic operations
- Called during `init` (line 87), blocking app startup
- Executed on main thread during app initialization

**Impact:**
- Noticeable app launch delay on slow storage
- Poor user experience on first launch
- May trigger watchdog timeout on very slow systems

**Recommendation:**
Defer signature check to background or accept sync call with documentation:
```swift
init() {
    self.updater = DisabledUpdaterController()
    super.init()
    
    // Defer signature check to avoid blocking init
    Task.detached(priority: .utility) { [weak self] in
        let canUseSparkle = await self?.checkSignature() ?? false
        if canUseSparkle {
            await self?.initializeSparkle()
        }
    }
}
```

---

## 4. State Management Problems

### 4.1 Race Condition in `isBlocking` Flag ⚠️ MEDIUM

**Location:** `SystemKeyBlocker.swift`, lines 145, 293, 306

**Code:**
```swift
@Published private(set) var isBlocking: Bool = false

func startBlocking() -> Bool {
    guard !isBlocking else { return true }         // ❌ Non-atomic read
    // ... setup ...
    isBlocking = true                              // ❌ Non-atomic write
    return true
}

func stopBlocking() {
    guard isBlocking else { return }               // ❌ Non-atomic read
    // ... cleanup ...
    isBlocking = false                             // ❌ Non-atomic write
}
```

**Problem:**
- No mutual exclusion between reads and writes
- Multiple threads can pass the guard check simultaneously
- State updates are not atomic

**Race Scenario (Double Start):**
```
Thread A: startBlocking() checks !isBlocking (true)
Thread B: startBlocking() checks !isBlocking (true)  [both pass]
Thread A: Proceeds to create event tap
Thread B: Also proceeds to create event tap
Both set isBlocking = true
Result: Two event taps created, memory leak, undefined behavior
```

**Race Scenario (Double Stop):**
```
Thread A: stopBlocking() checks isBlocking (true)
Thread B: stopBlocking() checks isBlocking (true)
Thread A: Begins cleanup, sets isBlocking = false
Thread B: Also begins cleanup (parallel)
Result: Double cleanup, crash in CFRunLoopRemoveSource
```

**Impact:**
- Duplicate event tap creation
- Crashes from double cleanup
- Inconsistent state

**Recommendation:**
Use serial queue for all state-modifying operations (combined with fix 1.3).

---

### 4.2 Lost Update State from Concurrent Callbacks ⚠️ MEDIUM

**Location:** `SparkleController.swift`, lines 165-200

**Code:**
```swift
nonisolated func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
    Task { @MainActor in
        self.isUpdateReady = true                   // ❌ No synchronization
    }
}

nonisolated func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, 
                        error: Error) {
    Task { @MainActor in
        self.isUpdateReady = false                  // ❌ Race with above
    }
}

nonisolated func userDidCancelDownload(_ updater: SPUUpdater) {
    Task { @MainActor in
        self.isUpdateReady = false                  // ❌ Race with both
    }
}
```

**Problem:**
- Multiple callbacks can fire in rapid succession
- Each schedules a `Task @MainActor` to update `isUpdateReady`
- Task execution order is not guaranteed
- No mutual exclusion between updates

**Race Scenario:**
```
T1: didDownloadUpdate() schedules Task(isUpdateReady = true)
T2: userDidCancelDownload() schedules Task(isUpdateReady = false)
T3: Task from T2 executes first → isUpdateReady = false
T4: Task from T1 executes second → isUpdateReady = true

Result: UI shows "update ready" even though user cancelled!
```

**Impact:**
- UI displays incorrect update status
- User confusion (sees "Update ready" when no update available)
- Potential attempt to install non-existent update

**Recommendation:**
Add sequence numbers or timestamps to order updates:
```swift
private var updateStateSequence: Int = 0

nonisolated func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
    let sequence = OSAtomicIncrement32(&updateStateSequence)
    Task { @MainActor in
        guard sequence >= self.lastAppliedSequence else { return }
        self.isUpdateReady = true
        self.lastAppliedSequence = sequence
    }
}
```

Or use a serial queue to order state updates.

---

## 5. Error Handling Gaps

### 5.1 Silent Failures in Hot Key Registration ⚠️ MEDIUM

**Location:** `SystemKeyBlocker.swift`, lines 215-250

**Code:**
```swift
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

// ❌ startBlocking() still returns true even if this failed
```

**Problem:**
- Errors are logged but not communicated to caller
- `startBlocking()` returns `true` even with partial failures
- User believes system keys are blocked when they're not
- No way to detect which shortcuts failed

**Impact:**
- False sense of security
- Cmd+Space (Spotlight) may still work, surprising users
- Baby can trigger blocked shortcuts

**Recommendation:**
Return detailed status or at minimum warn user:
```swift
struct BlockingStatus {
    let eventTapActive: Bool
    let carbonHotKeysRegistered: [String]  // Keys that succeeded
    let carbonHotKeysFailed: [String]      // Keys that failed
}

func startBlocking() -> BlockingStatus {
    var status = BlockingStatus(eventTapActive: false, 
                                carbonHotKeysRegistered: [], 
                                carbonHotKeysFailed: [])
    
    // Track each registration
    if RegisterEventHotKey(...) == noErr {
        status.carbonHotKeysRegistered.append("Spotlight")
    } else {
        status.carbonHotKeysFailed.append("Spotlight")
    }
    
    return status
}
```

---

### 5.2 No Accessibility Permission Feedback ⚠️ MEDIUM

**Location:** `SystemKeyBlocker.swift`, lines 148-151

**Code:**
```swift
func startBlocking() -> Bool {
    guard !isBlocking else { return true }
    
    guard AccessibilityManager.isAccessibilityEnabled() else {
        print("SystemKeyBlocker: Accessibility permission not granted")
        return false                                // ❌ No user-facing error
    }
    // ...
}
```

**Problem:**
- Returns `false` but user has no idea why
- Console log is not visible to users
- No guidance on how to fix the problem
- UI toggle just switches back with no explanation

**Impact:**
- User confusion - "Why isn't this working?"
- No path to resolution
- Poor user experience

**Recommendation:**
Integrate with permission request flow:
```swift
func startBlocking() -> Result<Void, BlockingError> {
    guard !isBlocking else { return .success(()) }
    
    guard AccessibilityManager.isAccessibilityEnabled() else {
        return .failure(.accessibilityPermissionRequired)
    }
    
    // Setup...
    return .success(())
}

// In SettingsView:
.onChange(of: blockSystemKeys) { _, newValue in
    if newValue {
        switch SystemKeyBlocker.shared.startBlocking() {
        case .success:
            break
        case .failure(.accessibilityPermissionRequired):
            showAccessibilityAlert = true
            blockSystemKeys = false
        }
    }
}
```

---

### 5.3 No Error Recovery in Kiosk Mode Cleanup ⚠️ MEDIUM

**Location:** `SparkleController.swift`, lines 221-230

**Code:**
```swift
nonisolated func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
    if Thread.isMainThread {
        SystemKeyBlocker.shared.stopBlocking()     // ❌ No error checking
        NSApp.presentationOptions = []              // ❌ Could fail silently
    } else {
        DispatchQueue.main.sync {
            SystemKeyBlocker.shared.stopBlocking()
            NSApp.presentationOptions = []
        }
    }
    print("[SparkleController] Cleaned up kiosk mode for update installation")
    // ❌ Assumes success, no verification
}
```

**Problem:**
- No verification that cleanup succeeded
- If `stopBlocking()` fails, update may hang
- If `presentationOptions` fails to restore menu bar, user has bad UX
- No recovery mechanism

**Impact:**
- Update installation may fail silently
- User stuck in kiosk mode during update
- Menu bar doesn't return, confusing user

**Recommendation:**
Add verification and retry:
```swift
nonisolated func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
    DispatchQueue.main.async {
        SystemKeyBlocker.shared.stopBlocking()
        NSApp.presentationOptions = []
        
        // Verify cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if SystemKeyBlocker.shared.isBlocking {
                print("[SparkleController] WARNING: Failed to stop blocking, retrying...")
                SystemKeyBlocker.shared.stopBlocking()
            }
        }
    }
    print("[SparkleController] Cleaned up kiosk mode for update installation")
}
```

---

## 6. Code Organization Issues

### 6.1 Inconsistent Isolation Model ⚠️ LOW-MEDIUM

**Location:** `SparkleController.swift`, lines 54, 165-250

**Problem:**
- Class is `@MainActor` but all delegate methods are `nonisolated`
- Requires manual `Task @MainActor` wrapping for every property access
- Easy to forget Task wrapper and introduce data race
- Makes code verbose and harder to maintain

**Recommendation:**
Consider one of:
1. Make the entire class nonisolated with explicit synchronization
2. Use `@MainActor` consistently and let Swift handle isolation
3. Document the isolation strategy clearly

---

### 6.2 Unsafe CFDictionary Cast ⚠️ LOW-MEDIUM

**Location:** `SparkleController.swift`, line 148

**Code:**
```swift
guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), 
                                   &infoCF) == errSecSuccess,
      let info = infoCF as? [String: Any],        // ❌ Unsafe cast
      let certs = info[kSecCodeInfoCertificates as String] as? [SecCertificate],
      let leaf = certs.first else {
    return false
}
```

**Problem:**
- `as?` cast may fail silently on OS updates
- No logging of why cast failed
- Legitimate certificates might be rejected
- Apple doesn't guarantee dictionary structure

**Recommendation:**
Add defensive logging:
```swift
guard let info = infoCF as? [String: Any] else {
    print("SparkleController: Failed to cast signing info to dictionary")
    return false
}

guard let certs = info[kSecCodeInfoCertificates as String] as? [SecCertificate] else {
    print("SparkleController: No certificates in signing info: \(info.keys)")
    return false
}
```

---

### 6.3 Flawed Thread.isMainThread Logic ⚠️ CRITICAL

**Location:** `SparkleController.swift`, lines 221, 240

**Problem:**
- `Thread.isMainThread` check gives false sense of safety
- `DispatchQueue.main.sync` is still dangerous even with the check
- Comments suggest awareness of deadlock risk but implementation doesn't fully address it

**Recommendation:**
Remove the conditional entirely and always use async (see fixes 1.1 and 1.2).

---

## 7. Component Interaction Issues

### 7.1 Race Condition with NSApp.presentationOptions ⚠️ MEDIUM

**Location:** Multiple files

**Code:**
```swift
// In AppDelegate.swift, line 146:
NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching]

// In SparkleController.swift, line 223:
NSApp.presentationOptions = []                     // ❌ Race condition
```

**Problem:**
- Multiple components modify `NSApp.presentationOptions` concurrently
- No coordination between AppDelegate and SparkleController
- Screen change notifications can fire during update

**Race Scenario:**
```
T1: User triggers update while in kiosk mode
T2: willInstallUpdate() clears presentation options
T3: Screen configuration change notification fires
T4: AppDelegate resets presentation options for kiosk
T5: Update tries to proceed with kiosk mode re-enabled
T6: Update fails or hangs
```

**Impact:**
- Inconsistent UI state during updates
- Menu bar/dock visibility flickers
- Update may not proceed correctly

**Recommendation:**
Centralize presentation options management:
```swift
class PresentationOptionsManager {
    static let shared = PresentationOptionsManager()
    
    private var requestedOptions: NSApplication.PresentationOptions = []
    private var overrideForUpdate: Bool = false
    
    func setKioskMode(_ enabled: Bool) {
        requestedOptions = enabled ? [.hideDock, .hideMenuBar, .disableProcessSwitching] : []
        updatePresentationOptions()
    }
    
    func setUpdateInProgress(_ inProgress: Bool) {
        overrideForUpdate = inProgress
        updatePresentationOptions()
    }
    
    private func updatePresentationOptions() {
        NSApp.presentationOptions = overrideForUpdate ? [] : requestedOptions
    }
}
```

---

### 7.2 Updater Lifecycle Timing Issues ⚠️ MEDIUM

**Location:** `SparkleController.swift`, line 113

**Code:**
```swift
controller.startUpdater()
self.updater = controller
```

**Problem:**
- Update check starts immediately
- May fire delegate callbacks before AppDelegate finishes initialization
- Kiosk mode might not be set up yet
- No defined shutdown sequence if update interrupts startup

**Impact:**
- Update dialogs appear before main window
- Kiosk cleanup may run before kiosk mode is established
- Timing-dependent behavior

**Recommendation:**
Defer updater start until app is fully initialized:
```swift
// In SparkleController:
private var controller: SPUStandardUpdaterController?

func startUpdaterWhenReady() {
    controller?.startUpdater()
}

// In AppDelegate:
func applicationDidFinishLaunching(_ notification: Notification) {
    createGameWindows()
    // Defer Sparkle start
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        SparkleController.shared.startUpdaterWhenReady()
    }
}
```

---

### 7.3 Missing Cleanup on Forced Exit ⚠️ MEDIUM

**Location:** `babysmashApp.swift`, line 68-71

**Code:**
```swift
func applicationWillTerminate(_ notification: Notification) {
    sharedViewModel.stopKeyboardMonitoring()
    closeAllGameWindows()
    // ❌ SystemKeyBlocker cleanup not explicitly called
}
```

**Problem:**
- `SystemKeyBlocker.deinit` calls `stopBlocking()` but deinit never runs (singleton)
- If app terminates abnormally, event taps may remain active
- Carbon hot keys may persist after crash
- CFRunLoopSource may not be removed

**Impact:**
- System event handlers remain active after app crash
- May interfere with other apps
- User has to restart to clear handlers

**Recommendation:**
Explicitly cleanup:
```swift
func applicationWillTerminate(_ notification: Notification) {
    sharedViewModel.stopKeyboardMonitoring()
    SystemKeyBlocker.shared.stopBlocking()  // Explicit cleanup
    closeAllGameWindows()
}
```

---

## Summary Table

| ID | Issue | Severity | File | Lines | Fix Complexity |
|----|-------|----------|------|-------|----------------|
| 1.1 | Deadlock in willInstallUpdate | **CRITICAL** | SparkleController | 225 | Low |
| 1.2 | Deadlock in updaterWillRelaunchApplication | **CRITICAL** | SparkleController | 244 | Low |
| 1.3 | Race in stopBlocking() | **HIGH** | SystemKeyBlocker | 298-305 | High |
| 1.4 | Race in handleEvent callback | **HIGH** | SystemKeyBlocker | 322 | High |
| 1.5 | Main Actor isolation | **MEDIUM** | SparkleController | 165-200 | Medium |
| 2.1 | Handler leak in registerCarbonHotKeys | **MEDIUM** | SystemKeyBlocker | 202 | Medium |
| 2.2 | Retain cycle SparkleController | **MEDIUM** | SparkleController | 108 | Medium |
| 2.3 | CFRunLoopSource retention | **MEDIUM** | SystemKeyBlocker | 174 | Medium |
| 3.1 | UserDefaults blocking | **LOW-MED** | SparkleController | 206 | Low |
| 3.2 | Security framework blocking | **MEDIUM** | SparkleController | 141-157 | High |
| 4.1 | Race in isBlocking flag | **MEDIUM** | SystemKeyBlocker | 145,293 | High |
| 4.2 | Lost update state | **MEDIUM** | SparkleController | 167-195 | Medium |
| 5.1 | Silent failures in hot keys | **MEDIUM** | SystemKeyBlocker | 215-250 | Medium |
| 5.2 | No permission feedback | **MEDIUM** | SystemKeyBlocker | 148-151 | Low |
| 5.3 | No error recovery | **MEDIUM** | SparkleController | 221-248 | Medium |
| 6.1 | Mixed isolation | **LOW-MED** | SparkleController | 165-250 | Low |
| 6.2 | Unsafe CFDictionary cast | **LOW-MED** | SparkleController | 148 | Low |
| 6.3 | Flawed thread check | **CRITICAL** | SparkleController | 221,240 | Low |
| 7.1 | Race in presentation options | **MEDIUM** | Multiple | - | Medium |
| 7.2 | Updater lifecycle timing | **MEDIUM** | SparkleController | 113 | Medium |
| 7.3 | Missing cleanup on exit | **MEDIUM** | babysmashApp | 68-71 | Low |

---

## Recommended Fix Priority

### Phase 1: Critical Deadlock Fixes (Immediate)
1. **Issue 1.1 & 1.2**: Replace `DispatchQueue.main.sync` with `async` in both delegate methods
2. **Issue 6.3**: Remove flawed `Thread.isMainThread` conditional logic

**Estimated Time:** 1 hour  
**Risk:** Low (simple change, well-tested pattern)

### Phase 2: High-Priority Race Conditions (Short-term)
3. **Issue 1.3**: Add serial DispatchQueue synchronization to `SystemKeyBlocker`
4. **Issue 1.4**: Fix race condition in `handleEvent` callback
5. **Issue 4.1**: Make `isBlocking` flag access atomic

**Estimated Time:** 4-6 hours  
**Risk:** Medium (requires careful synchronization design)

### Phase 3: Memory & State Management (Medium-term)
6. **Issue 2.2**: Break retain cycle in SparkleController
7. **Issue 2.3**: Properly retain CFRunLoopSource
8. **Issue 4.2**: Add sequencing to `isUpdateReady` updates
9. **Issue 2.1**: Track and cleanup Carbon hot key handlers

**Estimated Time:** 6-8 hours  
**Risk:** Medium (requires testing for leaks)

### Phase 4: Error Handling & UX (Medium-term)
10. **Issue 5.1**: Return detailed status from hot key registration
11. **Issue 5.2**: Add user-facing permission feedback
12. **Issue 5.3**: Add verification to kiosk cleanup
13. **Issue 7.1**: Centralize presentation options management

**Estimated Time:** 6-8 hours  
**Risk:** Low (mainly UI and messaging improvements)

### Phase 5: Optimization & Polish (Long-term)
14. **Issue 3.2**: Move security checks to background
15. **Issue 7.2**: Improve updater lifecycle timing
16. **Issue 7.3**: Add explicit cleanup on termination
17. **Issues 6.1, 6.2**: Code organization improvements

**Estimated Time:** 4-6 hours  
**Risk:** Low (quality-of-life improvements)

---

## Testing Recommendations

### Unit Tests Needed
- `SystemKeyBlocker.startBlocking()` / `stopBlocking()` called concurrently
- `SparkleController` delegate methods firing in rapid succession
- Carbon hot key registration failures
- CFRunLoopSource lifecycle

### Integration Tests Needed
- Update installation while in kiosk mode
- Update cancellation during download
- Multiple screen configuration changes during update
- Forced app termination with active key blocking

### Manual Testing Scenarios
1. Trigger update while baby is using app in kiosk mode
2. Cancel update mid-download
3. Disconnect/reconnect external monitor during update
4. Force quit app (Cmd+Opt+Esc) with key blocking active
5. Trigger update on slow network to test race conditions
6. Test on M1/M2/M3 Macs and Intel Macs

---

## Conclusion

The BabySmash upgrade system is functional but has several critical threading issues that could cause deadlocks or crashes in production. The most urgent fixes are:

1. **Eliminating `DispatchQueue.main.sync` calls** to prevent deadlocks
2. **Adding proper synchronization to `SystemKeyBlocker`** to prevent race conditions
3. **Improving error handling** to provide better user feedback

The good news is that most critical issues have straightforward fixes with low risk. The codebase shows good intent (e.g., comments about deadlock avoidance) but implementation doesn't fully address the concerns.

**Recommended Action:** Implement Phase 1 fixes immediately, then tackle Phase 2 within the next release cycle.

---

## Appendix A: Threading Safety Patterns

### Pattern 1: Serial Queue for State Protection
```swift
class ThreadSafeController {
    private let queue = DispatchQueue(label: "com.app.controller", qos: .userInitiated)
    private var _state: State = .idle
    
    var state: State {
        queue.sync { _state }
    }
    
    func updateState(_ newState: State) {
        queue.async {
            self._state = newState
        }
    }
}
```

### Pattern 2: Avoiding Deadlocks with Async
```swift
// ❌ BAD: Can deadlock
func delegate() {
    if Thread.isMainThread {
        doWork()
    } else {
        DispatchQueue.main.sync { doWork() }
    }
}

// ✅ GOOD: Never deadlocks
func delegate() {
    DispatchQueue.main.async { doWork() }
}
```

### Pattern 3: Ordered State Updates
```swift
class OrderedStateManager {
    private var sequence = AtomicInt(0)
    private var lastApplied = AtomicInt(0)
    
    func updateState(_ update: () -> Void) {
        let seq = sequence.increment()
        DispatchQueue.main.async {
            guard seq >= self.lastApplied.value else { return }
            update()
            self.lastApplied.value = seq
        }
    }
}
```

---

**End of Report**
