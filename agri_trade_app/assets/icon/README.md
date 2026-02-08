# App Icon Setup Instructions

To replace the Flutter logo with your custom app icon:

1. **Place your logo image here:**
   - Save your logo as `app_icon.png` in this directory
   - Recommended size: 1024x1024 pixels (square)
   - Format: PNG with transparent background (if needed)
   - The icon should be simple and recognizable at small sizes

2. **Generate the icons:**
   After placing your `app_icon.png` file in this directory, run:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

3. **The package will automatically generate:**
   - Android app icons (all sizes: mipmap-hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)
   - iOS app icons
   - Web icons (favicon and various sizes)
   - Adaptive icons for Android

4. **After generation, rebuild your app:**
   ```bash
   flutter clean
   flutter run
   ```

**Note:** The icon background color is set to green (#4CAF50) to match your app's theme. You can change this in `pubspec.yaml` under `flutter_launcher_icons` if needed.

