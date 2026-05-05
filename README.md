# secure_screen_guard

> Protect sensitive Flutter screens from screenshots and recording — with smart cross-platform handling.

| Platform | Screenshot | Screen Recording |
|----------|-----------|-----------------|
| **Android** | ✅ Blocked (FLAG_SECURE) | ✅ Blocked (FLAG_SECURE) |
| **iOS** | ⚠️ Detected & blurred | ✅ Detected & blurred |

---

## Installation

```yaml
dependencies:
  secure_screen_guard: ^0.0.1
```

---

## Quick Start

### 1. Wrap a screen

```dart
import 'package:secure_screen_guard/secure_screen_guard.dart';

SecureScreen(
  blurOnRecording: true,
  blurOnScreenshot: true,
  child: PaymentScreen(),
)
```

### 2. Manual control

```dart
// Enable globally (e.g. on login)
await SecureScreenGuard.enable();

// Disable (e.g. on logout)
await SecureScreenGuard.disable();
```

### 3. Set a security mode

```dart
await SecureScreenGuard.setMode(SecurityMode.strict);
```

| Mode | Behaviour |
|------|-----------|
| `strict` | Always protected — FLAG_SECURE always on (Android), always monitoring (iOS) |
| `balanced` | Protected when `SecureScreenGuard.enable()` is active (the `SecureScreen` widget does this automatically while mounted) *(default)* |
| `off` | Fully disabled |

### 4. Listen to events

```dart
SecureScreenGuard.onScreenshot.listen((_) {
  print('Screenshot taken!');
});

SecureScreenGuard.onRecordingStart.listen((_) {
  print('Screen recording started');
});

SecureScreenGuard.onRecordingStop.listen((_) {
  print('Screen recording stopped');
});
```

---

## `SecureScreen` Widget Reference

```dart
SecureScreen(
  // Whether to blur when recording is detected (iOS). Default: true
  blurOnRecording: true,

  // Whether to momentarily blur after a screenshot (iOS). Default: false
  blurOnScreenshot: false,

  // Blur intensity. Default: 20.0
  blurSigma: 20.0,

  // Solid colour overlay instead of blur (optional)
  obscureColor: Colors.black,

  // Callbacks
  onScreenshot: () { },
  onRecordingStart: () { },
  onRecordingStop: () { },

  // Set false to temporarily bypass protection on this widget
  enabled: true,

  child: MySensitiveWidget(),
)
```

---

## Platform Notes

### Android
Protection is applied via `FLAG_SECURE` on the Activity window. This:
- Prevents screenshots and screen recordings at the **OS level**.
- Blocks content from appearing in the **app switcher preview**.
- Works even if the user uses a third-party recorder.

Note: Android does not provide a reliable public callback for screenshot events in this plugin, so event streams are mainly useful on iOS.

### iOS
Apple does not allow apps to block screenshots. This package:
- **Detects** screenshots via `UIApplication.userDidTakeScreenshotNotification`.
- **Detects** screen recording via polling `UIScreen.main.isCaptured`.
- **Blurs** the wrapped widget automatically while recording is active.

Note: screenshot detection fires after the screenshot is taken, so screenshot blur is a post-capture visual response.

---

## License

MIT
