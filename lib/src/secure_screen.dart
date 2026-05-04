import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'secure_screen_channel.dart';

/// Wraps [child] with screenshot and screen-recording protection.
///
/// **Android**: enables [FLAG_SECURE] on the window while this widget is
/// in the tree, preventing screenshots and recordings at the OS level.
///
/// **iOS**: cannot block screenshots, but can detect them and optionally
/// blur or obscure [child] while recording is in progress.
///
/// ```dart
/// SecureScreen(
///   blurOnRecording: true,
///   blurOnScreenshot: true,
///   onScreenshot: () => showBanner('Screenshot detected!'),
///   child: PaymentScreen(),
/// )
/// ```
class SecureScreen extends StatefulWidget {
  const SecureScreen({
    super.key,
    required this.child,
    this.blurOnRecording = true,
    this.blurOnScreenshot = false,
    this.blurSigma = 20.0,
    this.obscureColor,
    this.onScreenshot,
    this.onRecordingStart,
    this.onRecordingStop,
    this.enabled = true,
  });

  /// The widget to protect.
  final Widget child;

  /// Whether to blur [child] when screen recording is detected (iOS).
  final bool blurOnRecording;

  /// Whether to momentarily blur [child] when a screenshot is taken (iOS).
  final bool blurOnScreenshot;

  /// Blur intensity when obscuring. Defaults to `20.0`.
  final double blurSigma;

  /// Solid colour to overlay instead of blur. If null, blur is used.
  final Color? obscureColor;

  /// Called when a screenshot event is received.
  final VoidCallback? onScreenshot;

  /// Called when screen recording starts (iOS).
  final VoidCallback? onRecordingStart;

  /// Called when screen recording stops (iOS).
  final VoidCallback? onRecordingStop;

  /// Set to false to bypass protection on this widget.
  final bool enabled;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen>
    with WidgetsBindingObserver {
  bool _isRecording = false;
  bool _screenshotFlash = false;

  final List<StreamSubscription<void>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) {
      _activate();
    }
  }

  void _activate() {
    SecureScreenChannel.enable();

    _subscriptions.add(
      SecureScreenChannel.onScreenshot.listen((_) {
        widget.onScreenshot?.call();
        if (widget.blurOnScreenshot) {
          _triggerScreenshotFlash();
        }
      }),
    );

    _subscriptions.add(
      SecureScreenChannel.onRecordingStart.listen((_) {
        widget.onRecordingStart?.call();
        if (widget.blurOnRecording && mounted) {
          setState(() => _isRecording = true);
        }
      }),
    );

    _subscriptions.add(
      SecureScreenChannel.onRecordingStop.listen((_) {
        widget.onRecordingStop?.call();
        if (mounted) {
          setState(() => _isRecording = false);
        }
      }),
    );
  }

  void _deactivate() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    SecureScreenChannel.disable();
  }

  Future<void> _triggerScreenshotFlash() async {
    if (!mounted) return;
    setState(() => _screenshotFlash = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _screenshotFlash = false);
  }

  @override
  void didUpdateWidget(SecureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      widget.enabled ? _activate() : _deactivate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check recording state after returning to foreground.
    if (state == AppLifecycleState.resumed && widget.enabled) {
      SecureScreenChannel.isRecording().then((recording) {
        if (mounted) setState(() => _isRecording = recording);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deactivate();
    super.dispose();
  }

  bool get _shouldObscure =>
      widget.enabled && (_isRecording || _screenshotFlash);

  @override
  Widget build(BuildContext context) {
    if (!_shouldObscure) return widget.child;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: widget.obscureColor != null
              ? ColoredBox(color: widget.obscureColor!)
              : ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blurSigma,
                      sigmaY: widget.blurSigma,
                    ),
                    child: const ColoredBox(color: Color(0x00000000)),
                  ),
                ),
        ),
      ],
    );
  }
}
