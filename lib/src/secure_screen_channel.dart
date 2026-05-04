import 'dart:async';
import 'package:flutter/services.dart';
import 'security_mode.dart';

class SecureScreenChannel {
  SecureScreenChannel._();

  static const MethodChannel _methodChannel =
      MethodChannel('secure_screen_guard/methods');

  static const EventChannel _eventChannel =
      EventChannel('secure_screen_guard/events');

  static Stream<String>? _rawEventStream;

  static Stream<String> get _events {
    _rawEventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as String);
    return _rawEventStream!;
  }

  static Future<void> enable() =>
      _methodChannel.invokeMethod('enable');

  static Future<void> disable() =>
      _methodChannel.invokeMethod('disable');

  static Future<void> setMode(SecurityMode mode) =>
      _methodChannel.invokeMethod('setMode', {'mode': mode.name});

  static Future<bool> isProtected() async {
    final result = await _methodChannel.invokeMethod<bool>('isProtected');
    return result ?? false;
  }

  static Future<bool> isRecording() async {
    final result = await _methodChannel.invokeMethod<bool>('isRecording');
    return result ?? false;
  }

  static Stream<void> get onScreenshot =>
      _events.where((e) => e == 'screenshot').map((_) {});

  static Stream<void> get onRecordingStart =>
      _events.where((e) => e == 'recordingStart').map((_) {});

  static Stream<void> get onRecordingStop =>
      _events.where((e) => e == 'recordingStop').map((_) {});
}
