import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'secure_screen_channel.dart';


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

  final Widget child;
  final bool blurOnRecording;
  final bool blurOnScreenshot;
  final double blurSigma;
  final Color? obscureColor;
  final VoidCallback? onScreenshot;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingStop;
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
