import 'dart:async';
import 'secure_screen_channel.dart';

class SecureScreenEvents {
  SecureScreenEvents._();

  static Stream<void> get onScreenshot => SecureScreenChannel.onScreenshot;

  static Stream<void> get onRecordingStart =>
      SecureScreenChannel.onRecordingStart;

  static Stream<void> get onRecordingStop =>
      SecureScreenChannel.onRecordingStop;
}
