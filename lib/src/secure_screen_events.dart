import 'dart:async';
import 'secure_screen_channel.dart';
import 'security_mode.dart';

/// Public event streams exposed by the package.
class SecureScreenEvents {
  SecureScreenEvents._();

  /// Fires when a screenshot is taken (iOS detection, Android: attempt logged).
  static Stream<void> get onScreenshot => SecureScreenChannel.onScreenshot;

  /// Fires when screen recording starts (iOS).
  static Stream<void> get onRecordingStart =>
      SecureScreenChannel.onRecordingStart;

  /// Fires when screen recording stops (iOS).
  static Stream<void> get onRecordingStop =>
      SecureScreenChannel.onRecordingStop;
}
