# APK Installation Instructions

## Problem
If you cannot install the APK, it's likely because:
1. **Signature Mismatch**: A previous version of the app is installed with a different signature
2. **Unknown Sources**: Your device may block installation from unknown sources

## Solution

### Option 1: Uninstall Previous Version (Recommended)
1. Go to **Settings** → **Apps** → Find **AgriTrade**
2. Tap on the app and select **Uninstall**
3. Now install the new APK

### Option 2: Use Debug APK (Easier Installation)
The debug APK is easier to install and doesn't require uninstalling:
- **Location**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Size**: Larger than release (includes debug symbols)
- **Use for**: Testing and development

### Option 3: Enable Unknown Sources
1. Go to **Settings** → **Security** (or **Apps** → **Special Access**)
2. Enable **Install from Unknown Sources** or **Install Unknown Apps**
3. Select your file manager/browser and enable it
4. Try installing again

## APK Locations

### Debug APK (Recommended for Testing)
- **Path**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Use**: Easier to install, good for testing
- **Note**: Includes debug symbols, larger file size

### Release APK (For Distribution)
- **Path**: `build/app/outputs/flutter-apk/app-release.apk`
- **Size**: 57.7 MB (optimized)
- **Note**: Requires uninstalling previous version if signature differs

## Installation Steps

1. **Transfer APK to your device** (via USB, email, or cloud storage)
2. **Open the APK file** on your Android device
3. **Tap "Install"** when prompted
4. If you see "App not installed" error:
   - Uninstall the previous version first
   - Or use the debug APK instead

## For Proper Release Signing (Future)

To build a properly signed release APK, create `android/key.properties`:

```properties
storeFile=keystore.jks
storePassword=your_store_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

Then rebuild with: `flutter build apk --release`

## Troubleshooting

- **"App not installed"**: Uninstall previous version first
- **"Parse error"**: APK might be corrupted, rebuild it
- **"Unknown source blocked"**: Enable installation from unknown sources in settings
- **"Package conflicts"**: Another app with same package name exists, uninstall it

