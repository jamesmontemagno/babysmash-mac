# Accessibility Permissions

BabySmash has an optional feature to block system keyboard shortcuts, preventing babies from accidentally exiting the app or triggering macOS system features like Mission Control.

## Why Accessibility Access is Needed

When the "Block System Keys" setting is enabled, BabySmash uses macOS Accessibility APIs to intercept and block a comprehensive set of keyboard shortcuts and special keys:

### Command Key Shortcuts (⌘+key)

| Blocked Shortcut | Normal Function |
|------------------|-----------------|
| ⌘+Tab | Switch applications |
| ⌘+Q | Quit application |
| ⌘+W | Close window |
| ⌘+H | Hide application |
| ⌘+M | Minimize window |
| ⌘+Space | Spotlight search |
| ⌘+` | Switch windows |
| ⌘+N | New window |
| ⌘+T | New tab |
| ⌘+O | Open file |
| ⌘+S | Save |
| ⌘+P | Print |
| ⌘+Z | Undo |
| ⌘+X/C/V | Cut/Copy/Paste |
| ⌘+A | Select all |
| ⌘+F | Find |
| ⌘+Delete | Delete file |
| ⌘+[/] | Indent/Outdent |
| ⌘+-/=/0 | Zoom controls |

### Control Key Shortcuts (Ctrl+key)

| Blocked Shortcut | Normal Function |
|------------------|-----------------|
| Ctrl+↑ | Mission Control |
| Ctrl+↓ | App Exposé |
| Ctrl+←/→ | Switch Spaces |
| Ctrl+1-9 | Switch to Desktop 1-9 |

### Function & Media Keys

| Blocked Key | Normal Function |
|-------------|-----------------|
| F1 | Help / Brightness down |
| F2 | Brightness up |
| F3 | Mission Control |
| F4 | Launchpad |
| F5/F6 | Keyboard brightness |
| F7/F8/F9 | Media controls (Previous/Play/Next) |
| F10 | Mute |
| F11 | Show Desktop / Volume down |
| F12 | Volume up |
| F13-F20 | Various functions |

### Media & Special Keys

| Blocked Key | Normal Function |
|-------------|-----------------|
| Play/Pause | Media playback |
| Previous/Next Track | Media navigation |
| Volume Up/Down/Mute | Audio control |
| Brightness Up/Down | Display brightness |
| Keyboard Backlight | Keyboard brightness |
| Eject | Eject disc |
| Launchpad key | Open Launchpad |
| Mission Control key | Open Mission Control |

### Other Blocked Keys

| Blocked Key | Normal Function |
|-------------|-----------------|
| Escape | Cancel/Close |
| Home/End | Navigation |
| Page Up/Down | Scrolling |
| Forward Delete | Delete forward |
| Help/Insert | Help system |

### Modifier Combinations

- All **⌘+Shift** combinations are blocked
- All **⌘+Option** combinations are blocked (except the emergency exit)

### Emergency Exit

Even with comprehensive key blocking enabled, you can always:
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
