import ActivityKit
import AVFoundation
import Flutter
import UIKit
import UserNotifications
import live_activities

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let warnId = "pulse.focus.warn"
  private let completeId = "pulse.focus.complete"
  private let tickIdPrefix = "pulse.focus.tick."
  private var alertsChannel: FlutterMethodChannel?

  private var focusEndAt: Date?
  private var endLiveActivityWork: DispatchWorkItem?
  private var focusBgTask: UIBackgroundTaskIdentifier = .invalid
  private var soundPack: String = "soft"
  private var completionEnabled: Bool = true
  private var cuePlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { _, _ in }
    prepareAudioSession()

    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupFocusAlertsChannel()
    return ok
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    guard let end = focusEndAt else { return }
    let remaining = end.timeIntervalSinceNow
    guard remaining > 0, remaining <= 32 else { return }
    beginFocusBackgroundTaskIfNeeded()
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    if let end = focusEndAt, end.timeIntervalSinceNow <= 0 {
      dismissFocusLiveActivityAndNotifyFlutter(playNativeComplete: true)
    }
    endFocusBackgroundTaskIfNeeded()
  }

  private func setupFocusAlertsChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
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
        let pack = args["soundPack"] as? String ?? "soft"
        self.scheduleFocusAlerts(
          remainingSeconds: remaining,
          endAtMs: endAtMs,
          quote: quote,
          paused: paused,
          warningEnabled: warningEnabled,
          ticksEnabled: ticksEnabled,
          completionEnabled: completionEnabled,
          soundPack: pack
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
    endLiveActivityWork?.cancel()
    endLiveActivityWork = nil
    focusEndAt = nil
    endFocusBackgroundTaskIfNeeded()
  }

  private func scheduleFocusAlerts(
    remainingSeconds: Double,
    endAtMs: Double?,
    quote: String,
    paused: Bool,
    warningEnabled: Bool,
    ticksEnabled: Bool,
    completionEnabled: Bool,
    soundPack: String
  ) {
    cancelFocusAlerts()
    self.soundPack = soundPack
    self.completionEnabled = completionEnabled && soundPack != "silent"
    guard !paused, remainingSeconds > 0, soundPack != "silent" else { return }

    let now = Date().timeIntervalSince1970
    let end: Date
    if let endAtMs, endAtMs / 1000.0 > now {
      end = Date(timeIntervalSince1970: endAtMs / 1000.0)
    } else {
      end = Date().addingTimeInterval(remainingSeconds)
    }
    focusEndAt = end
    scheduleLiveActivityDismiss(at: end)

    // Flutter plays ticks in the foreground; OS schedules cover lock/suspend.
    if warningEnabled && remainingSeconds > 10 {
      let warnAt = end.addingTimeInterval(-10)
      if warnAt.timeIntervalSinceNow > 0.4 {
        schedule(
          id: warnId,
          title: "Almost done",
          body: quote.isEmpty ? "10 seconds left" : "\(quote) · 10 seconds left",
          at: warnAt,
          kind: .warning
        )
      }
    }

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
          kind: .tick
        )
      }
    }

    if self.completionEnabled && end.timeIntervalSinceNow > 0.4 {
      schedule(
        id: completeId,
        title: "Focus complete",
        body: quote.isEmpty ? "Nice work — session finished" : quote,
        at: end,
        kind: .complete
      )
    }
  }

  private enum CueKind { case tick, warning, complete }

  private func scheduleLiveActivityDismiss(at end: Date) {
    endLiveActivityWork?.cancel()
    let work = DispatchWorkItem { [weak self] in
      self?.dismissFocusLiveActivityAndNotifyFlutter(playNativeComplete: true)
    }
    endLiveActivityWork = work
    // After the chime window so sound and dismiss feel paired.
    let delay = max(end.timeIntervalSinceNow + 0.35, 0.25)
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
  }

  private func dismissFocusLiveActivityAndNotifyFlutter(playNativeComplete: Bool) {
    endLiveActivityWork?.cancel()
    endLiveActivityWork = nil
    if playNativeComplete && completionEnabled {
      playBundledCue(.complete)
    }
    if #available(iOS 16.1, *) {
      LiveActivitiesPlugin.endAllLiveActivitiesImmediately()
    }
    alertsChannel?.invokeMethod(
      "focusNativeComplete",
      arguments: ["nativePlayed": playNativeComplete]
    )
    focusEndAt = nil
    endFocusBackgroundTaskIfNeeded()
  }

  private func beginFocusBackgroundTaskIfNeeded() {
    guard focusBgTask == .invalid else { return }
    focusBgTask = UIApplication.shared.beginBackgroundTask(withName: "pulse.focus.end") { [weak self] in
      self?.endFocusBackgroundTaskIfNeeded()
    }
  }

  private func endFocusBackgroundTaskIfNeeded() {
    guard focusBgTask != .invalid else { return }
    UIApplication.shared.endBackgroundTask(focusBgTask)
    focusBgTask = .invalid
  }

  private func prepareAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
      try session.setActive(true, options: [])
    } catch {
      NSLog("Pulse audio session failed: \(error)")
    }
  }

  private func soundFileName(for kind: CueKind) -> String {
    let wood = soundPack == "wood"
    switch kind {
    case .tick:
      return wood ? "focus_tick_wood.wav" : "focus_tick.wav"
    case .warning:
      return wood ? "focus_warning_wood.wav" : "focus_warning.wav"
    case .complete:
      return wood ? "focus_complete_wood.wav" : "focus_complete.wav"
    }
  }

  private func notificationSound(for kind: CueKind) -> UNNotificationSound {
    let name = soundFileName(for: kind)
    if Bundle.main.url(forResource: name.replacingOccurrences(of: ".wav", with: ""), withExtension: "wav") != nil
        || Bundle.main.url(forResource: name, withExtension: nil) != nil {
      return UNNotificationSound(named: UNNotificationSoundName(name))
    }
    return .default
  }

  /// Plays even when the mute switch is on (playback session).
  private func playBundledCue(_ kind: CueKind) {
    prepareAudioSession()
    let name = soundFileName(for: kind)
    let base = name.replacingOccurrences(of: ".wav", with: "")
    guard let url = Bundle.main.url(forResource: base, withExtension: "wav")
            ?? Bundle.main.url(forResource: name, withExtension: nil) else {
      NSLog("Pulse cue missing in bundle: \(name)")
      return
    }
    do {
      cuePlayer?.stop()
      cuePlayer = try AVAudioPlayer(contentsOf: url)
      cuePlayer?.prepareToPlay()
      cuePlayer?.volume = 1.0
      cuePlayer?.play()
    } catch {
      NSLog("Pulse cue play failed: \(error)")
    }
  }

  private func schedule(
    id: String,
    title: String,
    body: String,
    at date: Date,
    kind: CueKind
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = notificationSound(for: kind)
    if #available(iOS 15.0, *) {
      content.interruptionLevel = kind == .tick ? .passive : .timeSensitive
    }

    let seconds = max(date.timeIntervalSinceNow, 0.5)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let id = notification.request.identifier
    let isTick = id.hasPrefix(tickIdPrefix)
    if id == completeId {
      // Flutter owns the foreground chime (pack WAV). Avoid stacking system sound.
      dismissFocusLiveActivityAndNotifyFlutter(playNativeComplete: false)
      if #available(iOS 14.0, *) {
        completionHandler([.banner, .list])
      } else {
        completionHandler([.alert])
      }
      return
    }
    if isTick {
      // Flutter ticker owns foreground ticks — skip notification sound.
      completionHandler([])
      return
    }
    if id == warnId {
      // Flutter plays the pack warning in-app; keep a quiet banner only.
      if #available(iOS 14.0, *) {
        completionHandler([.banner, .list])
      } else {
        completionHandler([.alert])
      }
      return
    }
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }
}
