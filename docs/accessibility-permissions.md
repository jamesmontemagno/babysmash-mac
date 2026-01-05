# Accessibility Permissions

BabySmash has an optional feature to block system keyboard shortcuts, preventing babies from accidentally exiting the app or triggering macOS system features like Mission Control.

## Why Accessibility Access is Needed

When the "Block System Keys" setting is enabled, BabySmash uses macOS Accessibility APIs to intercept and block certain keyboard shortcuts:

| Blocked Shortcut | Normal Function |
|------------------|-----------------|
| ⌘+Tab | Switch applications |
| ⌘+Q | Quit application |
| ⌘+W | Close window |
| ⌘+H | Hide application |
| ⌘+M | Minimize window |
| Ctrl+↑ | Mission Control |
| Ctrl+↓ | App Exposé |
| Ctrl+←/→ | Switch Spaces |
| F3 | Mission Control |
| F11 | Show Desktop |

### Emergency Exit

Even with system key blocking enabled, you can always:
- Press **⌥⌘+Esc** (Option+Command+Escape) to open the Force Quit dialog
- Press **⌥+S** (Option+S) to open BabySmash settings

## Granting Permission

When you first enable "Block System Keys" in settings, macOS will prompt you to grant Accessibility access:

1. Click **"Open System Preferences"** when prompted
2. In **Privacy & Security → Accessibility**, find BabySmash in the list
3. Toggle the switch to enable access
4. You may need to restart BabySmash for the change to take effect

### Manual Setup

If you need to grant permission manually:

1. Open **System Settings** (or System Preferences on older macOS)
2. Go to **Privacy & Security → Accessibility**
3. Click the **lock icon** and authenticate if needed
4. Click **+** to add an application
5. Navigate to BabySmash and select it
6. Ensure the toggle next to BabySmash is **enabled**

## Configuration Files

### Info.plist

The app includes an `NSAccessibilityUsageDescription` key that explains to users why accessibility access is requested:

```xml
<key>NSAccessibilityUsageDescription</key>
<string>BabySmash needs accessibility access to block system keyboard shortcuts (like Cmd+Tab and Mission Control) so your baby can't accidentally exit the app. This is optional - the app works without it.</string>
```

### Entitlements

The app uses `babysmash.entitlements` with the sandbox disabled:

```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

**Note:** CGEvent taps (used for intercepting system keys) are not allowed in sandboxed applications. This means BabySmash cannot be distributed through the Mac App Store with this feature enabled. For App Store distribution, the system key blocking feature would need to be removed or made unavailable.

## Technical Implementation

The system key blocking is implemented in `Services/SystemKeyBlocker.swift` using:

- `CGEvent.tapCreate()` - Creates an event tap to intercept keyboard events
- `CGEventTapProxy` - Processes events before they reach other applications
- Events are filtered and blocked by returning `nil` from the callback

The feature gracefully degrades - if accessibility permission is not granted, the app continues to work normally without blocking system keys.

## Troubleshooting

### "Block System Keys" doesn't work

1. Check that BabySmash has Accessibility permission in System Settings
2. Try toggling the permission off and on
3. Restart BabySmash after granting permission

### Permission prompt doesn't appear

If you've previously denied permission, macOS won't prompt again. You'll need to manually add the app in System Settings → Privacy & Security → Accessibility.

### App was working but stopped blocking keys

macOS may revoke accessibility permissions after app updates. Re-grant permission in System Settings if needed.
