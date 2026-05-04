import 'dart:async';
import 'secure_screen_channel.dart';
import 'security_mode.dart';

/// Global controller for [SecureScreenGuard].
///
/// Use this to enable/disable protection and listen to events without
/// wrapping widgets.
///
/// ```dart
/// await SecureScreenGuard.enable();
/// await SecureScreenGuard.setMode(SecurityMode.strict);
///
/// SecureScreenGuard.onScreenshot.listen((_) {
///   print('Screenshot detected!');
/// });
/// ```
class SecureScreenGuard {
  SecureScreenGuard._();

  // ─── Mode & Protection ───────────────────────────────────────────────────

  /// Enable screen protection globally.
  static Future<void> enable() => SecureScreenChannel.enable();

  /// Disable screen protection globally.
  static Future<void> disable() => SecureScreenChannel.disable();

  /// Set the [SecurityMode].
  ///
  /// - [SecurityMode.strict] — always protected.
  /// - [SecurityMode.balanced] — only screens explicitly wrapped.
  /// - [SecurityMode.off] — fully disabled.
  static Future<void> setMode(SecurityMode mode) =>
      SecureScreenChannel.setMode(mode);

  /// Returns whether protection is currently active.
  static Future<bool> get isProtected => SecureScreenChannel.isProtected();

  /// Returns whether the screen is currently being recorded (iOS).
  static Future<bool> get isRecording => SecureScreenChannel.isRecording();

  // ─── Events ───────────────────────────────────────────────────────────────

  /// Fires when a screenshot is taken.
  ///
  /// Android: fires on attempt (screen is blocked by FLAG_SECURE).
  /// iOS: fires after the screenshot is captured.
  static Stream<void> get onScreenshot => SecureScreenChannel.onScreenshot;

  /// Fires when screen recording begins (iOS only).
  static Stream<void> get onRecordingStart =>
      SecureScreenChannel.onRecordingStart;

  /// Fires when screen recording ends (iOS only).
  static Stream<void> get onRecordingStop =>
      SecureScreenChannel.onRecordingStop;
}
