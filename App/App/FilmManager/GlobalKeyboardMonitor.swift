import Foundation
import Carbon
import Cocoa

// MARK: - GlobalKeyboardMonitor - Monitors for backtick (`) key globally

class GlobalKeyboardMonitor {

    // MARK: - Properties
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isMonitoring: Bool = false
    private var healthCheckTimer: Timer?

    // Callback to trigger when backtick is pressed
    var onBacktickPressed: (() -> Void)?

    // MARK: - Backtick Key Code
    // On US keyboard: ` (backtick/grave) is keycode 50
    private let backtickKeyCode: CGKeyCode = 50

    // MARK: - Start Monitoring
    func startMonitoring() {
        guard !isMonitoring else {
            print("⚠️ Global keyboard monitor already running")
            return
        }

        // Check if we have accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️ Accessibility permissions not granted")
            requestAccessibilityPermissions()
            return
        }

        // Create event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Cast refcon back to self
                let mySelf = Unmanaged<GlobalKeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                return mySelf.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ Failed to create event tap")
            return
        }

        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the event tap
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        isMonitoring = true

        // Start health check timer to re-enable tap if macOS disables it
        startHealthCheckTimer()

        print("[Sora] ✅ Global keyboard monitor started (listening for backtick key)")
    }

    // MARK: - Stop Monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }

        // Stop health check timer
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isMonitoring = false

        print("[Sora] 🛑 Global keyboard monitor stopped")
    }

    // MARK: - Health Check
    private func startHealthCheckTimer() {
        // Check every 2 seconds if the event tap is still enabled
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkEventTapHealth()
        }
    }

    private func checkEventTapHealth() {
        guard let tap = eventTap, isMonitoring else { return }

        // Check if tap is still enabled
        let isEnabled = CGEvent.tapIsEnabled(tap: tap)

        if !isEnabled {
            print("[Sora] ⚠️ Event tap was disabled by macOS - re-enabling...")
            CGEvent.tapEnable(tap: tap, enable: true)
            print("[Sora] ✅ Event tap re-enabled")
        }
    }

    // MARK: - Event Handler
    private func handleKeyEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // Check if it's a key down event
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        // Get the key code
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Check if it's the backtick key
        if keyCode == Int64(backtickKeyCode) {
            print("[Sora] ⌨️ Backtick key intercepted in event handler")

            // Trigger callback on main thread asynchronously (non-blocking)
            DispatchQueue.main.async { [weak self] in
                print("[Sora] 🔔 Executing backtick callback on main thread")
                self?.onBacktickPressed?()
            }

            // IMPORTANT: Return immediately to avoid blocking the event stream
            // Consume the event (don't pass it through)
            return nil
        }

        // Pass through other keys
        return Unmanaged.passRetained(event)
    }

    // MARK: - Request Accessibility Permissions
    private func requestAccessibilityPermissions() {
        print("📝 Requesting accessibility permissions...")

        // Show system dialog to grant accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("⚠️ User needs to grant accessibility permissions in System Settings")
            showPermissionAlert()
        }
    }

    // MARK: - Show Permission Alert
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            FilmManager needs Accessibility permissions to monitor the backtick (`) key for quick import.

            Please grant permission in:
            System Settings → Privacy & Security → Accessibility

            Then restart the app and activate Veo Import Mode again.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open System Settings to Accessibility
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    // MARK: - Check Permissions
    func hasAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    // MARK: - Manual Re-enable (can be called if backtick stops working)
    func reEnableEventTap() {
        guard let tap = eventTap, isMonitoring else {
            print("[Sora] ⚠️ Cannot re-enable - not monitoring")
            return
        }

        print("[Sora] 🔄 Manually re-enabling event tap...")
        CGEvent.tapEnable(tap: tap, enable: true)
        print("[Sora] ✅ Event tap manually re-enabled")
    }

    deinit {
        stopMonitoring()
    }
}
