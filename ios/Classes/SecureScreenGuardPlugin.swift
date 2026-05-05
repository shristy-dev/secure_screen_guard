import Flutter
import UIKit

public class SecureScreenGuardPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private static let methodChannelName = "secure_screen_guard/methods"
    private static let eventChannelName  = "secure_screen_guard/events"

    private var eventSink: FlutterEventSink?
    private var widgetProtectionEnabled = false
    private var mode: String = "balanced"
    private var wasRecording = false
    private var recordingCheckTimer: Timer?

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

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enable":
            widgetProtectionEnabled = true
            applyProtectionState()
            result(nil)

        case "disable":
            widgetProtectionEnabled = false
            applyProtectionState()
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
            result(shouldProtect())

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

    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        applyProtectionState()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        stopMonitoring()
        return nil
    }

    public func applicationWillResignActive(_ application: UIApplication) {}

    private func shouldProtect() -> Bool {
        switch mode {
        case "strict":
            return true
        case "off":
            return false
        default:
            return widgetProtectionEnabled
        }
    }

    private func applyProtectionState() {
        if shouldProtect() {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
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
        wasRecording = false
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

    private func handleMode(_ mode: String) {
        self.mode = mode
        applyProtectionState()
    }

    deinit {
        stopMonitoring()
    }
}
