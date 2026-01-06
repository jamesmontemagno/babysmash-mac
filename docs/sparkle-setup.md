# Sparkle Auto-Updates Setup Guide

This document describes the manual setup steps required to enable Sparkle auto-updates for BabySmash.

## Prerequisites

- Xcode 16+
- Apple Developer ID certificate
- GitHub repository with Actions enabled

## Step 1: Add Sparkle via Swift Package Manager (REQUIRED)

**⚠️ IMPORTANT: Sparkle must be added via Xcode's UI. The package reference is NOT included in the repository.**

1. Open `babysmash.xcodeproj` in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter URL: `https://github.com/sparkle-project/Sparkle`
4. Select version rule: **Up to Next Major Version** from `2.8.1`
5. Click **Add Package**
6. In the dialog, select `Sparkle` framework for the `babysmash` target
7. Click **Add Package**

### Verify Sparkle Integration

After adding, ensure:
- The Sparkle framework appears in your project's **Frameworks, Libraries, and Embedded Content**
- In Project Navigator, you should see **Package Dependencies** with Sparkle listed
- Build the project to verify no linking errors

### Why Manual Addition?

Xcode's project file format is complex and version-specific. Adding SPM packages programmatically can cause project corruption. Adding via Xcode's UI ensures proper integration with your specific Xcode version.

## Step 2: Generate Sparkle Keys

Sparkle uses EdDSA (Ed25519) signatures for security. Generate your key pair:

### Using Sparkle's generate_keys Tool

1. After adding Sparkle via SPM, find the tools in:
   - In Xcode, expand **Package Dependencies → Sparkle**
   - Right-click and **Show in Finder**
   - Navigate to `artifacts/sparkle/Sparkle/bin/`

2. Generate keys:
   ```bash
   cd /path/to/Sparkle/bin
   ./generate_keys
   ```

3. The tool will:
   - Generate a new private/public key pair
   - Store the private key in your Keychain (Sparkle Private Key)
   - Display the **public key** - copy this for Info.plist

4. **Backup your private key** (IMPORTANT):
   ```bash
   ./generate_keys -x ~/Desktop/sparkle_private_key.txt
   ```
   Store this backup securely - you cannot recover it if lost!

### Add Public Key to Info.plist

The public key has already been added to `babysmash/Info.plist` as a placeholder:

```xml
<key>SUPublicEDKey</key>
<string>REPLACE_WITH_YOUR_PUBLIC_ED_KEY</string>
```

Replace `REPLACE_WITH_YOUR_PUBLIC_ED_KEY` with your actual public key from step 2.

## Step 3: Configure GitHub Secrets

Add these secrets to your GitHub repository (**Settings → Secrets and variables → Actions**):

### Required Secrets

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `SPARKLE_PRIVATE_KEY` | Full contents of exported private key file | From `./generate_keys -x` output |
| `DEVELOPER_ID_CERTIFICATE_BASE64` | Base64-encoded Developer ID certificate (.p12) | Export from Keychain, then `base64 -i certificate.p12` |
| `DEVELOPER_ID_CERTIFICATE_PASSWORD` | Password for the .p12 certificate | Set when exporting |
| `KEYCHAIN_PASSWORD` | Any strong password for temporary keychain | Generate a random password |
| `APPLE_ID` | Your Apple ID email | Your Apple Developer account email |
| `APP_PASSWORD` | App-specific password | Generate at [appleid.apple.com](https://appleid.apple.com) → Security → App-Specific Passwords |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID | Find in [developer.apple.com](https://developer.apple.com) → Membership |

### Creating the Developer ID Certificate

1. Open **Keychain Access**
2. Find your **Developer ID Application** certificate
3. Right-click → **Export**
4. Save as `.p12` with a strong password
5. Convert to base64:
   ```bash
   base64 -i DeveloperID.p12 | pbcopy
   ```
6. Paste into GitHub secret `DEVELOPER_ID_CERTIFICATE_BASE64`

### Creating App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in → **Security** section
3. Under **App-Specific Passwords**, click **Generate Password**
4. Name it "BabySmash Notarization"
5. Copy the generated password to `APP_PASSWORD` secret

## Step 4: Enable GitHub Pages

1. Go to repository **Settings → Pages**
2. Under **Source**, select:
   - Branch: `main`
   - Folder: `/docs`
3. Click **Save**
4. Wait for deployment (may take a few minutes)
5. Verify appcast is accessible at:
   `https://jamesmontemagno.github.io/babysmash-mac/appcast.xml`

## Step 5: Configure Xcode Signing

**Note:** No provisioning profile is needed for Developer ID distribution. Only the certificate is required.

### For Release Builds

1. Open project settings in Xcode
2. Select `babysmash` target
3. Go to **Signing & Capabilities** tab
4. For **Release** configuration:
   - Set **Team** to your Developer ID team
   - Set **Signing Certificate** to **Developer ID Application**
   - **Provisioning Profile**: Should show "None" (this is correct)

### Share the Scheme

The build scheme must be shared for CI:

1. In Xcode, go to **Product → Scheme → Manage Schemes**
2. Find `babysmash` scheme
3. Ensure **Shared** checkbox is checked
4. Commit the `.xcscheme` file in `.xcodeproj/xcshareddata/xcschemes/`

## Step 6: Create a Release

To trigger the workflow and create a release:

```bash
# Tag a version
git tag v0.0.1
git push origin v0.0.1
```

The GitHub Action will:
1. Build the app with Release configuration
2. Sign with Developer ID certificate
3. Notarize with Apple
4. Create a signed ZIP
5. Generate delta updates (if previous versions exist)
6. Update the appcast.xml
7. Create a GitHub Release with the artifacts
8. Deploy appcast to GitHub Pages

## Testing Updates

### Initial Test (v0.0.1)

1. After creating v0.0.1 release, download from GitHub Releases
2. Verify signature: `spctl -a -vv BabySmash.app`
3. Launch the app
4. Check Console.app for Sparkle initialization logs:
   - Filter by "SparkleController" or "Sparkle"
   - Should see "Started with auto-check: true"
5. Open Settings and click "Check for Updates"

### Testing Update Flow (v0.0.2)

1. With v0.0.1 installed, create v0.0.2:
   ```bash
   # Update version in project settings
   git tag v0.0.2
   git push origin v0.0.2
   ```
2. Wait for workflow to complete
3. Launch v0.0.1 app
4. Click "Check for Updates" in Settings
5. Sparkle should find and offer v0.0.2

## Troubleshooting

### "Updates not available in development builds"

This is expected when running from Xcode. The app detects:
- Running from DerivedData folder
- Not signed with Developer ID

Only downloaded release builds can check for updates.

### Notarization Fails

- Ensure app-specific password is valid
- Check Apple ID has accepted latest agreements
- Verify Team ID is correct
- Check Console.app logs for detailed errors

### Appcast Not Found

- Verify GitHub Pages is enabled for `/docs` folder
- Check the URL in Info.plist matches: `https://jamesmontemagno.github.io/babysmash-mac/appcast.xml`
- Wait for Pages deployment after workflow completes

### Signature Verification Fails

```bash
# Check signature
codesign -dvv BabySmash.app

# Check Gatekeeper assessment
spctl -a -vv BabySmash.app
```

If rejected, ensure:
- Developer ID certificate is valid
- Notarization completed successfully
- Stapling was applied

## Version Numbering

- `CFBundleShortVersionString` (Marketing Version): `0.0.1`, `0.0.2`, `1.0.0`
- `CFBundleVersion` (Build Number): `1`, `2`, `3` (increment each build)

Sparkle compares versions semantically. Use standard semver format.
