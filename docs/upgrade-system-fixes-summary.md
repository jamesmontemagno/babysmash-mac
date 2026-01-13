# Upgrade System Fixes - Quick Reference

This document provides a quick summary of the issues found in the upgrade system analysis. For detailed explanations, see [upgrade-system-analysis.md](./upgrade-system-analysis.md).

## 🚨 Critical Fixes Required (Do First)

### 1. Deadlock in Update Installation Callbacks
**Files:** `SparkleController.swift` lines 225, 244  
**Problem:** Using `DispatchQueue.main.sync` can cause app to hang during update installation  
**Fix:** Replace with `DispatchQueue.main.async`

```swift
// Current code (DANGEROUS):
if Thread.isMainThread {
    SystemKeyBlocker.shared.stopBlocking()
    NSApp.presentationOptions = []
} else {
    DispatchQueue.main.sync {  // ⚠️ Can deadlock
        SystemKeyBlocker.shared.stopBlocking()
        NSApp.presentationOptions = []
    }
}

// Fixed code:
DispatchQueue.main.async {  // ✅ Never deadlocks
    SystemKeyBlocker.shared.stopBlocking()
    NSApp.presentationOptions = []
}
```

**Impact if not fixed:** App hangs during update, requires force-quit, updates fail  
**Estimated fix time:** 15 minutes  
**Risk level:** Low (simple, well-tested pattern)

---

## ⚠️ High Priority Fixes

### 2. Race Condition in SystemKeyBlocker.stopBlocking()
**File:** `SystemKeyBlocker.swift` lines 292-308  
**Problem:** Multiple threads can access `eventTap` and `runLoopSource` without synchronization  
**Fix:** Add serial DispatchQueue for thread safety

```swift
class SystemKeyBlocker: ObservableObject {
    private let queue = DispatchQueue(label: "com.babysmash.systemkeyblocker")
    
    func stopBlocking() {
        queue.sync {  // ✅ Serializes access
            guard isBlocking else { return }
            // ... cleanup code ...
        }
    }
    
    func startBlocking() -> Bool {
        queue.sync {  // ✅ Serializes access
            guard !isBlocking else { return true }
            // ... setup code ...
        }
    }
}
```

**Impact if not fixed:** Random crashes when stopping key blocking during updates  
**Estimated fix time:** 2-3 hours  
**Risk level:** Medium (requires careful testing)

### 3. Race Condition in handleEvent Callback
**File:** `SystemKeyBlocker.swift` line 322  
**Problem:** Event handler accesses `eventTap` while `stopBlocking()` is nullifying it  
**Fix:** Use the same serial queue from fix #2

**Impact if not fixed:** Crashes in event callback  
**Estimated fix time:** Included in fix #2  
**Risk level:** Medium

---

## 🔶 Medium Priority Fixes

### 4. Retain Cycle in SparkleController
**File:** `SparkleController.swift` line 108  
**Problem:** SparkleController → updater → delegate (self) creates cycle  
**Impact:** Memory leak (small but persistent)  
**Fix complexity:** Medium

### 5. Race on isUpdateReady State
**File:** `SparkleController.swift` lines 165-200  
**Problem:** Multiple callbacks update state concurrently without ordering  
**Impact:** UI shows wrong update status  
**Fix complexity:** Medium

### 6. Silent Failures in Hot Key Registration
**File:** `SystemKeyBlocker.swift` lines 215-250  
**Problem:** Errors logged but not reported, user thinks shortcuts blocked when they're not  
**Impact:** False sense of security  
**Fix complexity:** Medium

### 7. No Accessibility Permission Feedback
**File:** `SystemKeyBlocker.swift` lines 148-151  
**Problem:** Returns false but no user-visible error  
**Impact:** Poor UX, user confused  
**Fix complexity:** Low

### 8. Race on NSApp.presentationOptions
**Files:** Multiple  
**Problem:** AppDelegate and SparkleController both modify presentation options  
**Impact:** Flickering UI during updates  
**Fix complexity:** Medium

---

## Quick Win Fixes (Low-hanging fruit)

### 9. UserDefaults Blocking Call
**File:** `SparkleController.swift` line 206  
**Fix:** Cache the value or accept minor blocking  
**Time:** 15 minutes

### 10. Missing Cleanup on Termination
**File:** `babysmashApp.swift` line 68-71  
**Fix:** Add `SystemKeyBlocker.shared.stopBlocking()` call  
**Time:** 5 minutes

### 11. Unsafe CFDictionary Cast
**File:** `SparkleController.swift` line 148  
**Fix:** Add defensive logging  
**Time:** 10 minutes

---

## Implementation Roadmap

### Week 1: Critical Fixes
- [ ] Fix deadlock in `willInstallUpdate` (#1)
- [ ] Fix deadlock in `updaterWillRelaunchApplication` (#1)
- [ ] Add explicit cleanup on termination (#10)
- **Estimated time:** 2 hours
- **Risk:** Low
- **Impact:** Prevents app hangs during updates

### Week 2: High Priority
- [ ] Add synchronization to SystemKeyBlocker (#2, #3)
- [ ] Test race condition fixes thoroughly
- **Estimated time:** 6-8 hours
- **Risk:** Medium
- **Impact:** Prevents crashes during key blocking

### Week 3: Medium Priority
- [ ] Fix retain cycle in SparkleController (#4)
- [ ] Add sequencing to update state (#5)
- [ ] Improve error feedback (#6, #7)
- **Estimated time:** 8-10 hours
- **Risk:** Low-Medium
- **Impact:** Better UX, no memory leaks

### Week 4: Polish
- [ ] Centralize presentation options (#8)
- [ ] Add defensive logging (#11)
- [ ] Optimize initialization (#9)
- **Estimated time:** 4-6 hours
- **Risk:** Low
- **Impact:** Code quality improvements

---

## Testing Checklist

After implementing fixes, test these scenarios:

### Critical Path Tests
- [ ] Trigger update while in kiosk mode
- [ ] Cancel update mid-download
- [ ] Force quit app with key blocking active
- [ ] Update on slow network

### Edge Cases
- [ ] Rapid start/stop of key blocking
- [ ] Multiple screen connect/disconnect during update
- [ ] Update notification while app is starting
- [ ] System going to sleep during update

### Regression Tests
- [ ] Normal update flow still works
- [ ] Key blocking works after update
- [ ] Kiosk mode restores properly
- [ ] No performance degradation

---

## Verification Commands

```bash
# Check for deadlock patterns
grep -n "DispatchQueue.main.sync" babysmash/Services/*.swift

# Check for race conditions on properties
grep -n "@Published.*var.*Bool" babysmash/Services/*.swift

# Find all synchronization primitives
grep -n "NSLock\|DispatchQueue\|DispatchSemaphore" babysmash/Services/*.swift

# Memory leak detection (run in Instruments)
# Profile → Leaks → Start recording → Trigger update flow
```

---

## Risk Assessment

| Fix | Severity | Risk | Time | User Impact if Unfixed |
|-----|----------|------|------|------------------------|
| #1 (Deadlock) | CRITICAL | Low | 15m | App hangs, updates fail |
| #2 (Race in stopBlocking) | HIGH | Med | 3h | Random crashes |
| #3 (Race in handleEvent) | HIGH | Med | - | Random crashes |
| #4 (Retain cycle) | MEDIUM | Low | 2h | Memory leak |
| #5 (Update state race) | MEDIUM | Med | 2h | Wrong UI state |
| #6 (Silent failures) | MEDIUM | Low | 1h | False security |
| #7 (No feedback) | MEDIUM | Low | 1h | Confusion |
| #8 (Presentation race) | MEDIUM | Med | 3h | UI flicker |

**Total estimated time for all critical + high priority fixes:** 8-10 hours

---

## Success Metrics

After implementing fixes, verify:
- ✅ No deadlocks during 100 test update cycles
- ✅ No crashes during 1000 start/stop blocking cycles
- ✅ Update state always consistent with actual state
- ✅ No memory leaks over 24-hour run
- ✅ All error cases provide user feedback
- ✅ Kiosk mode never gets stuck

---

## References

- Full analysis: [upgrade-system-analysis.md](./upgrade-system-analysis.md)
- Sparkle documentation: https://sparkle-project.org
- Swift Concurrency: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
- Grand Central Dispatch: https://developer.apple.com/documentation/dispatch
