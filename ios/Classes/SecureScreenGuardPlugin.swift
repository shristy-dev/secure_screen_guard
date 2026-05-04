import Flutter
import UIKit

public class SecureScreenGuardPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    // ─── Channel names ─────────────────────────────────────────────────────
    private static let methodChannelName = "secure_screen_guard/methods"
    private static let eventChannelName  = "secure_screen_guard/events"

    // ─── State ─────────────────────────────────────────────────────────────
    private var eventSink: FlutterEventSink?
    private var isEnabled = false
    private var wasRecording = false
    private var recordingCheckTimer: Timer?

    // ─── Registration ──────────────────────────────────────────────────────

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SecureScreenGuardPlugin()

        let methodChannel = FlutterMethodChannel(
            name: methodChannelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)

        registrar.addApplicationDelegate(instance)
    }

    // ─── FlutterMethodCallDelegate ─────────────────────────────────────────

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enable":
            isEnabled = true
            startMonitoring()
            result(nil)

        case "disable":
            isEnabled = false
            stopMonitoring()
            result(nil)

        case "setMode":
            guard let args = call.arguments as? [String: Any],
                  let mode = args["mode"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "mode required", details: nil))
                return
            }
            handleMode(mode)
            result(nil)

        case "isProtected":
            result(isEnabled)

        case "isRecording":
            if #available(iOS 11.0, *) {
                result(UIScreen.main.isCaptured)
            } else {
                result(false)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ─── FlutterStreamHandler ──────────────────────────────────────────────

    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        if isEnabled { startMonitoring() }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        stopMonitoring()
        return nil
    }

    // ─── App lifecycle ─────────────────────────────────────────────────────

    public func applicationWillResignActive(_ application: UIApplication) {
        // Screen goes to app-switcher — nothing special needed on iOS;
        // FLAG_SECURE equivalent is handled per-screen on Android.
    }

    // ─── Monitoring ────────────────────────────────────────────────────────

    private func startMonitoring() {
        // Screenshot detection
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )

        // Screen recording detection (iOS 11+): poll UIScreen.isCaptured
        if #available(iOS 11.0, *) {
            recordingCheckTimer?.invalidate()
            recordingCheckTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0,
                repeats: true
            ) { [weak self] _ in
                self?.checkRecordingState()
            }
        }
    }

    private func stopMonitoring() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        recordingCheckTimer?.invalidate()
        recordingCheckTimer = nil
    }

    @objc private func screenshotTaken() {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?("screenshot")
        }
    }

    @available(iOS 11.0, *)
    private func checkRecordingState() {
        let recording = UIScreen.main.isCaptured
        if recording && !wasRecording {
            wasRecording = true
            DispatchQueue.main.async { [weak self] in
                self?.eventSink?("recordingStart")
            }
        } else if !recording && wasRecording {
            wasRecording = false
            DispatchQueue.main.async { [weak self] in
                self?.eventSink?("recordingStop")
            }
        }
    }

    // ─── Mode ─────────────────────────────────────────────────────────────

    private func handleMode(_ mode: String) {
        switch mode {
        case "strict":
            isEnabled = true
            startMonitoring()
        case "off":
            isEnabled = false
            stopMonitoring()
        default: // "balanced" — controlled per-widget
            break
        }
    }

    deinit {
        stopMonitoring()
    }
}
