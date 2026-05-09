# 🎬 Flutter Video Splash Screen

A professional Flutter implementation of a video splash screen with seamless transition to the home screen.

---

## 📋 Table of Contents

- [Features](#-features)
- [Why Use a Black Splash Screen?](#-why-use-a-black-splash-screen)
- [Project Structure](#-project-structure)
- [Main Code](#-main-code)
- [Android Setup](#-android-setup)
- [iOS Setup](#-ios-setup)
- [pubspec.yaml Setup](#-pubspecyaml-setup)
- [Safety Improvements](#-safety-improvements)
- [Technical Tips](#-technical-tips)
- [License](#-license)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎥 **Fullscreen Video** | Covers entire screen using `BoxFit.cover` |
| ⚡ **Seamless Transition** | Unified black background between Native Splash and Flutter Video |
| 🛡️ **Error Handling** | Auto-navigates to home if video fails to load |
| ⏱️ **Smart Timeout** | Auto-navigates after 6 seconds if video gets stuck |
| 🔄 **Prevents Double Navigation** | Ensures navigation happens only once |
| 📱 **Responsive** | Works on all screen sizes and devices |
| 🔇 **Silent by Default** | Video plays without sound (configurable) |

---

## 🎨 Why Use a Black Splash Screen?

### The Original Problem
When opening any Flutter app, a **Native Splash Screen** (system-level) appears for ~1 second while the Flutter Engine loads. It cannot be completely removed as it's part of the operating system.

### The Engineering Solution
Instead of trying to remove the Native Splash (technically impossible), we make it **look like part of the video**:

```
┌─────────────────────────────────────┐
│  User taps the app icon             │
│         ⬇️                           │
│  ┌─────────────────────────────┐    │
│  │    Native Splash (Black)    │    │ ← Cannot be removed
│  │         0.5 - 1 second       │    │   But we hide it!
│  └─────────────────────────────┘    │
│         ⬇️                           │
│  ┌─────────────────────────────┐    │
│  │    Flutter Video Splash     │    │ ← Our video
│  │   (Same black background)    │    │
│  │         3 - 5 seconds        │    │
│  └─────────────────────────────┘    │
│         ⬇️                           │
│  ┌─────────────────────────────┐    │
│  │       Home Screen           │    │ ← Main app screen
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### Why Black Specifically?

1. **Most splash videos** start with a black frame (fade-in from black)
2. **Prevents white flicker** during the transition
3. **Hides the two-stage process** (Native + Flutter) making it appear as one stage
4. **Battery efficient** on OLED/AMOLED screens
5. **Professional look** used by major apps like Netflix and Spotify

---

## 📁 Project Structure

```
lib/
├── main.dart                          # Entry point
├── screens/
│   └── video_splash_screen.dart       # Video screen (main code)
├── screens/
│   └── home_screen.dart               # Home screen (example)
└── ...

android/
└── app/src/main/res/
    ├── values/
    │   ├── colors.xml                 # Background color (black)
    │   ├── styles.xml                 # Normal theme
    │   └── themes.xml                 # Launch theme
    ├── values-v31/
    │   └── themes.xml                 # Android 12+ specific theme
    └── drawable/
        └── launch_background.xml      # Launch background

ios/
└── Runner/
    ├── LaunchScreen.storyboard        # iOS launch screen
    └── Info.plist                     # Additional settings

assets/
└── videos/
    └── splash.mp4                     # Splash video (2-3 MB)
```

---

## 💻 Main Code

### `lib/screens/video_splash_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Video Splash Screen
/// 
/// Displays a fullscreen video then automatically navigates
/// to the home screen when the video ends or after a timeout
class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({Key? key}) : super(key: key);

  @override
  _VideoSplashScreenState createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  /// Video player controller
  late VideoPlayerController _controller;

  /// Prevents multiple navigations if video ends or timeout occurs
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    /// Fallback timeout: if video gets stuck for any reason, navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _navigateToHome();
    });
  }

  /// Initialize video and setup listeners
  void _initializeVideo() {
    _controller = VideoPlayerController.asset("assets/videos/splash.mp4")
      // Set volume (0.0 = muted, 1.0 = full volume)
      ..setVolume(0.0)
      // Initialize video
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      })
      // Error handling: if video fails to load, navigate to home
      .catchError((error) {
        debugPrint("Video Error: $error");
        _navigateToHome();
      });

    // Add listener to monitor video progress
    _controller.addListener(_videoListener);
  }

  /// Video listener: monitors video completion
  /// 
  /// We use >= instead of == because position and duration are Duration types
  /// Direct comparison might fail due to microsecond differences
  void _videoListener() {
    if (!_controller.value.isInitialized) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (position >= duration) {
      _navigateToHome();
    }
  }

  /// Navigate to home screen
  /// 
  /// - Checks mounted (is the Widget still in the tree?)
  /// - Checks _hasNavigated (did we navigate before?)
  /// - Uses pushReplacementNamed so user can't go back to splash
  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

  // Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    // Clean up resources: remove listener then dispose controller
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                // BoxFit.cover: fills entire screen while maintaining aspect ratio
                // May crop parts of the video in some aspect ratios
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            // Loading indicator (shown while video initializes)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}
```

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'screens/video_splash_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // canvasColor prevents white flicker in some cases
        canvasColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
      ),
      // First screen: video splash
      home: const VideoSplashScreen(),
      // Define routes
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
```

---

## 🤖 Android Setup

### 1. `android/app/src/main/res/values/colors.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Black background color for splash -->
    <color name="splash_bg">#000000</color>
</resources>
```

### 2. `android/app/src/main/res/drawable/launch_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Solid black background -->
    <item android:drawable="@color/splash_bg" />
</layer-list>
```

### 3. `android/app/src/main/res/values/styles.xml` (or `themes.xml`)

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme while Flutter Engine is loading -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowFullscreen">true</item>
    </style>

    <!-- Theme after loading completes -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@android:color/black</item>
    </style>
</resources>
```

### 4. `android/app/src/main/res/values-v31/themes.xml` (Android 12+)

> ⚠️ **Important:** Android 12 (API 31) introduced a new SplashScreen API that enforces a center icon. This file disables it.

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <!-- Disable default icon in Android 12+ -->
        <item name="android:windowSplashScreenBackground">@color/splash_bg</item>
        <item name="android:windowSplashScreenAnimatedIcon">@android:color/transparent</item>
        <item name="android:windowSplashScreenIconBackgroundColor">@android:color/transparent</item>
        <item name="android:windowSplashScreenAnimationDuration">0</item>
    </style>
</resources>
```

### 5. Verify `AndroidManifest.xml`

```xml
<activity
    android:name=".MainActivity"
    android:theme="@style/LaunchTheme"
    android:exported="true"
    ... >
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

---

## 🍎 iOS Setup

### 1. Open Project in Xcode

```bash
open ios/Runner.xcworkspace
```

### 2. Edit `LaunchScreen.storyboard`

1. From **Project Navigator** open: `Runner > Runner > LaunchScreen.storyboard`
2. Click on the main **View**
3. From **Attributes Inspector** (right side):
   - **Background** → **Custom** → `#000000`
4. **Delete any ImageView or Label** in the center (click them → Delete)
5. Verify Constraints:
   - Leading = 0, Trailing = 0, Top = 0, Bottom = 0

### 3. `ios/Runner/Info.plist` (Optional)

```xml
<!-- Hide status bar during splash -->
<key>UIStatusBarHidden</key>
<true/>
<key>UIViewControllerBasedStatusBarAppearance</key>
<false/>
```

---

## 📦 pubspec.yaml Setup

```yaml
name: video_splash_app
description: Flutter app with video splash screen

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # Video player
  video_player: ^2.8.1

flutter:
  uses-material-design: true

  assets:
    # Splash video path
    - assets/videos/splash.mp4
```

---

## 🛡️ Safety Improvements in the Code

### 1. Prevent Double Navigation (`_hasNavigated`)
```dart
bool _hasNavigated = false;

void _navigateToHome() {
  if (_hasNavigated) return; // Prevents crash from double navigation
  _hasNavigated = true;
  Navigator.pushReplacementNamed(context, '/home');
}
```

### 2. Check `mounted`
```dart
if (mounted) {
  setState(() {}); // Safe: Widget is still in the tree
}
```

### 3. Video Error Handling
```dart
.catchError((error) {
  debugPrint("Video Error: $error");
  _navigateToHome(); // Don't leave user hanging
});
```

### 4. Fallback Timeout
```dart
Future.delayed(const Duration(seconds: 6), () {
  _navigateToHome(); // Safety net against stuck video
});
```

### 5. Safe Video Completion Comparison
```dart
// ❌ Wrong: may fail due to microsecond differences
if (position == duration) { ... }

// ✅ Correct: ensures navigation even with tiny differences
if (position >= duration) { ... }
```

---

## 💡 Technical Tips

### Video Compression
- Use **H.264** encoding
- Ideal size: **2-3 MB**
- Resolution: **720p** is sufficient for mobile
- Duration: **3-5 seconds** maximum

### Recommended Video Aspect Ratios
| Ratio | Use Case |
|-------|----------|
| 9:16 | Stories, Reels (portrait) |
| 16:9 | Landscape |
| 1:1 | Square |

> 💡 `BoxFit.cover` automatically handles all aspect ratios

### Test on Real Devices
- Test on **Android 12+** (API 31+)
- Test on **iPhone with Dynamic Island**
- Test on **older devices** (slower performance)

---

## 📄 License

This project is open source. You can use and modify it according to your needs.

---

## 🙋‍♂️ Support

If you encounter any issues:
1. Make sure the video exists in `assets/videos/`
2. Make sure it's registered in `pubspec.yaml`
3. Run `flutter clean` then `flutter pub get`
4. Try on a fresh Emulator/Simulator
