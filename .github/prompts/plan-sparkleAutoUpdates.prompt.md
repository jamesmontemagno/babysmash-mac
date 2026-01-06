# Plan: Integrate Sparkle Auto-Updates with GitHub Actions Workflow

BabySmash will use GitHub Actions for complete automation: build with xcodebuild, sign, notarize, download Sparkle tools, generate appcast, and deploy. Appcast.xml hosted on GitHub Pages, binaries (.zip, .delta) on GitHub Releases. Release notes use GitHub's markdown format embedded in appcast. Starting with v0.0.1 for testing.

## Steps

1. **Add Sparkle via SPM and generate keys** - File → Add Packages → `https://github.com/sparkle-project/Sparkle`, navigate to `../artifacts/sparkle/Sparkle/bin/` in Finder via package navigator, run `./generate_keys`, backup private key with `./generate_keys -x ~/Desktop/sparkle_private.key`, add `SPARKLE_PRIVATE_KEY` to repository Settings → Secrets → Actions with full private key contents, copy public key for [Info.plist](babysmash/Info.plist).

2. **Configure Info.plist with Sparkle settings** - Add `SUFeedURL` as `https://jamesmontemagno.github.io/babysmash-mac/appcast.xml` and `SUPublicEDKey` with generated key to [Info.plist](babysmash/Info.plist), set `CFBundleVersion` to `1` and `CFBundleShortVersionString` to `0.0.1`, add `SUEnableAutomaticChecks` as `YES`.

3. **Create SparkleController service singleton** - Build [Services/SparkleController.swift](babysmash/Services/SparkleController.swift) with `SPUStandardUpdaterController`, detect unsigned builds by checking if bundle path contains "DerivedData" to disable Sparkle in development, initialize in [babysmashApp.swift](babysmash/babysmashApp.swift) app init, follow RepoBar's pattern for [SparkleController](https://github.com/steipete/repobar/blob/main/Sources/RepoBar/Support/SparkleController.swift).

4. **Add Check for Updates UI to Settings** - Create `CheckForUpdatesViewModel` and `CheckForUpdatesView` following Sparkle's SwiftUI documentation pattern in [SettingsView.swift](babysmash/Views/SettingsView.swift) About section, insert below version display using `L10n.Settings.CheckForUpdates` localized strings, bind to `SparkleController.shared.updaterController.updater`.

5. **Enable GitHub Pages and add placeholder appcast** - Repository Settings → Pages → Source: `main` branch → `/docs` folder, create [docs/appcast.xml](docs/appcast.xml) with minimal RSS structure `<?xml version="1.0"?><rss version="2.0"><channel><title>BabySmash Updates</title></channel></rss>`, commit to activate Pages at `https://jamesmontemagno.github.io/babysmash-mac/appcast.xml`.

6. **Configure Apple Developer ID credentials** - Generate app-specific password at appleid.apple.com for notarization, run `xcrun notarytool store-credentials "notarytool-profile" --apple-id YOUR_EMAIL --team-id TEAM_ID`, add `APPLE_ID`, `APP_PASSWORD`, and `APPLE_TEAM_ID` to GitHub Secrets, configure Xcode Signing & Capabilities to use Developer ID Application certificate for Release scheme.

7. **Create GitHub Actions release workflow** - Build [.github/workflows/release.yml](.github/workflows/release.yml) triggered on `v*.*.*` tags with: checkout code, build with `xcodebuild -scheme babysmash -configuration Release archive`, export with Developer ID using `xcodebuild -exportArchive` with automatic signing, notarize with `xcrun notarytool submit --wait --apple-id ${{ secrets.APPLE_ID }}`, create ZIP with `ditto -c -k --sequesterRsrc --keepParent`, download Sparkle 2.8+ release from GitHub and extract `generate_appcast` binary, generate appcast with `--download-url-prefix "https://github.com/jamesmontemagno/babysmash-mac/releases/download/${{ github.ref_name }}/"` and `--ed-key-file` using secret, extract GitHub Release body markdown via API and embed in appcast `<description><![CDATA[...]]></description>`, upload `.zip` and generated `.delta` files to GitHub Release using `softprops/action-gh-release@v2` with `generate_release_notes: true`, deploy appcast.xml to Pages with `peaceiris/actions-gh-pages@v4` publishing `docs/` folder.

## Further Considerations

1. **Xcodebuild scheme configuration?** Ensure `babysmash` scheme is shared (checked in `.xcodeproj/xcshareddata/xcschemes/`), set Release configuration to use Developer ID certificate in Signing & Capabilities, verify Sparkle framework is embedded in Copy Frameworks build phase.

2. **Sparkle version pinning?** Currently SPM will use latest 2.x. Pin to specific version like `from: "2.8.1"` or `exact: "2.8.1"` in Xcode package settings to ensure consistent behavior across builds and avoid breaking changes?

3. **Initial testing workflow?** After v0.0.1 release: download ZIP from GitHub Release, verify with `spctl -a -vv BabySmash.app`, launch and check Console.app for Sparkle initialization logs, manually trigger "Check for Updates", create v0.0.2 with same process to test actual update flow including delta generation?
