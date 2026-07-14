import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let warnId = "pulse.focus.warn"
  private let completeId = "pulse.focus.complete"
  private let tickIdPrefix = "pulse.focus.tick."
  private var alertsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { _, _ in }

    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupFocusAlertsChannel()
    return ok
  }

  private func setupFocusAlertsChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      // Scene-based Flutter may attach later.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.setupFocusAlertsChannel()
      }
      return
    }
    if alertsChannel != nil { return }
    let channel = FlutterMethodChannel(
      name: "pulse/focus_alerts",
      binaryMessenger: controller.binaryMessenger
    )
    alertsChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "gone", message: nil, details: nil))
        return
      }
      switch call.method {
      case "schedule":
        let args = call.arguments as? [String: Any] ?? [:]
        let remaining = (args["remainingSeconds"] as? NSNumber)?.doubleValue ?? 0
        let endAtMs = (args["endAtMs"] as? NSNumber)?.doubleValue
        let quote = args["quote"] as? String ?? ""
        let paused = args["paused"] as? Bool ?? false
        let warningEnabled = args["warningEnabled"] as? Bool ?? true
        let ticksEnabled = args["ticksEnabled"] as? Bool ?? true
        let completionEnabled = args["completionEnabled"] as? Bool ?? true
        self.scheduleFocusAlerts(
          remainingSeconds: remaining,
          endAtMs: endAtMs,
          quote: quote,
          paused: paused,
          warningEnabled: warningEnabled,
          ticksEnabled: ticksEnabled,
          completionEnabled: completionEnabled
        )
        result(nil)
      case "cancel":
        self.cancelFocusAlerts()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func cancelFocusAlerts() {
    var ids = [warnId, completeId]
    for sec in 1...9 {
      ids.append("\(tickIdPrefix)\(sec)")
    }
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
  }

  private func scheduleFocusAlerts(
    remainingSeconds: Double,
    endAtMs: Double?,
    quote: String,
    paused: Bool,
    warningEnabled: Bool,
    ticksEnabled: Bool,
    completionEnabled: Bool
  ) {
    cancelFocusAlerts()
    guard !paused, remainingSeconds > 0 else { return }

    let now = Date().timeIntervalSince1970
    let end: Date
    if let endAtMs, endAtMs / 1000.0 > now {
      end = Date(timeIntervalSince1970: endAtMs / 1000.0)
    } else {
      end = Date().addingTimeInterval(remainingSeconds)
    }

    if warningEnabled && remainingSeconds > 10 {
      let warnAt = end.addingTimeInterval(-10)
      if warnAt.timeIntervalSinceNow > 0.4 {
        schedule(
          id: warnId,
          title: "Almost done",
          body: quote.isEmpty ? "10 seconds left" : "\(quote) · 10 seconds left",
          at: warnAt,
          tick: false
        )
      }
    }

    // Ticks for remaining 9..1 (sound-only when app is foregrounded).
    if ticksEnabled {
      for secLeft in 1...9 {
        guard remainingSeconds > Double(secLeft) else { continue }
        let tickAt = end.addingTimeInterval(-Double(secLeft))
        guard tickAt.timeIntervalSinceNow > 0.4 else { continue }
        schedule(
          id: "\(tickIdPrefix)\(secLeft)",
          title: "Focus",
          body: "\(secLeft)s",
          at: tickAt,
          tick: true
        )
      }
    }

    if completionEnabled && end.timeIntervalSinceNow > 0.4 {
      schedule(
        id: completeId,
        title: "Focus complete",
        body: quote.isEmpty ? "Nice work — session finished" : quote,
        at: end,
        tick: false
      )
    }
  }

  private func schedule(
    id: String,
    title: String,
    body: String,
    at date: Date,
    tick: Bool
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    if #available(iOS 15.0, *) {
      content.interruptionLevel = tick ? .passive : .timeSensitive
    }

    let seconds = max(date.timeIntervalSinceNow, 0.5)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }

  // Show banners even when Pulse is in foreground so QA can hear/see alerts.
  // Tick cues stay sound-only to avoid a banner every second.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let isTick = notification.request.identifier.hasPrefix(tickIdPrefix)
    if #available(iOS 14.0, *) {
      completionHandler(isTick ? [.sound] : [.banner, .list, .sound])
    } else {
      completionHandler(isTick ? [.sound] : [.alert, .sound])
    }
  }
}
