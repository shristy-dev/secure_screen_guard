import 'dart:async';
import 'secure_screen_channel.dart';
import 'security_mode.dart';

class SecureScreenGuard {
  SecureScreenGuard._();

  static Future<void> enable() => SecureScreenChannel.enable();

  static Future<void> disable() => SecureScreenChannel.disable();

  static Future<void> setMode(SecurityMode mode) =>
      SecureScreenChannel.setMode(mode);

  static Future<bool> get isProtected => SecureScreenChannel.isProtected();

  static Future<bool> get isRecording => SecureScreenChannel.isRecording();

  static Stream<void> get onScreenshot => SecureScreenChannel.onScreenshot;

  static Stream<void> get onRecordingStart =>
      SecureScreenChannel.onRecordingStart;

  static Stream<void> get onRecordingStop =>
      SecureScreenChannel.onRecordingStop;
}
