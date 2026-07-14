import ActivityKit
import WidgetKit
import SwiftUI

@main
struct PulseLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    PulseFocusLiveActivity()
    PulseHomeWidget()
  }
}

struct PulseFocusLiveActivity: Widget {
  let sharedDefault = UserDefaults(suiteName: "group.com.anurag.pulse")

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      LockScreenLiveView(context: context, sharedDefault: sharedDefault)
    } dynamicIsland: { context in
      let palette = PulseLivePalette.island
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text(PulseLiveContent.title(context: context, sharedDefault: sharedDefault))
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        DynamicIslandExpandedRegion(.trailing) {
          RemainingText(context: context, sharedDefault: sharedDefault)
            .font(.title2.bold().monospacedDigit())
            .foregroundColor(palette.accent(warning: isWarning(context: context)))
        }
        DynamicIslandExpandedRegion(.center) {
          Text(quoteLine(context: context))
            .font(.caption.weight(.semibold))
            .foregroundColor(palette.accent(warning: isWarning(context: context)))
            .lineLimit(2)
            .multilineTextAlignment(.center)
        }
        DynamicIslandExpandedRegion(.bottom) {
          ControlButtons(
            context: context,
            sharedDefault: sharedDefault,
            compact: true,
            onDarkIsland: true
          )
        }
      } compactLeading: {
        Image(systemName: isWarning(context: context) ? "exclamationmark.circle.fill" : "timer")
          .foregroundColor(palette.accent(warning: isWarning(context: context)))
      } compactTrailing: {
        RemainingText(context: context, sharedDefault: sharedDefault)
          .font(.caption.bold().monospacedDigit())
          .foregroundColor(.white)
      } minimal: {
        Image(systemName: isWarning(context: context) ? "exclamationmark.circle.fill" : "timer")
          .foregroundColor(palette.accent(warning: isWarning(context: context)))
      }
    }
  }

  private func quoteLine(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    PulseLiveContent.quoteLine(context: context, sharedDefault: sharedDefault)
  }

  private func isWarning(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Bool {
    PulseLiveContent.isWarning(context: context, sharedDefault: sharedDefault)
  }
}

private struct LockScreenLiveView: View {
  let context: ActivityViewContext<LiveActivitiesAppAttributes>
  let sharedDefault: UserDefaults?

  var body: some View {
    // Re-evaluate after 0:00 so Pause/Finish drop even if Flutter is suspended.
    TimelineView(.periodic(from: .now, by: 1)) { timeline in
      let palette = PulseLivePalette.lock
      let warning = PulseLiveContent.isWarning(context: context, sharedDefault: sharedDefault)
      let finished = PulseLiveContent.isFinished(
        context: context,
        sharedDefault: sharedDefault,
        now: timeline.date
      )

      VStack(spacing: 12) {
        HStack(alignment: .top, spacing: 12) {
          VStack(alignment: .leading, spacing: 4) {
            Text(PulseLiveContent.title(context: context, sharedDefault: sharedDefault))
              .font(.headline.weight(.semibold))
              .foregroundColor(palette.ink)
            Text(
              finished
                ? "Session complete"
                : PulseLiveContent.quoteLine(context: context, sharedDefault: sharedDefault)
            )
              .font(.caption.weight(.medium))
              .foregroundColor(palette.muted)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
          }
          Spacer(minLength: 8)
          RemainingText(context: context, sharedDefault: sharedDefault)
            .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundColor(palette.ink)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
        }

        if !finished {
          ControlButtons(
            context: context,
            sharedDefault: sharedDefault,
            compact: false
          )
        }
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 14)
      .activityBackgroundTint(palette.tint(warning: warning))
      .activitySystemActionForegroundColor(palette.ink)
    }
  }
}

private struct ControlButtons: View {
  let context: ActivityViewContext<LiveActivitiesAppAttributes>
  let sharedDefault: UserDefaults?
  let compact: Bool
  /// Dynamic Island stays dark; lock screen uses light mint chips.
  var onDarkIsland: Bool = false

  var body: some View {
    let paused = PulseLiveContent.isPaused(context: context, sharedDefault: sharedDefault)
    HStack(spacing: 10) {
      if paused {
        Link(destination: URL(string: "pulse://focus/resume")!) {
          ControlChip(
            title: "Resume",
            systemImage: "play.fill",
            filled: true,
            compact: compact,
            onDarkIsland: onDarkIsland
          )
        }
        .buttonStyle(.plain)
      } else {
        Link(destination: URL(string: "pulse://focus/pause")!) {
          ControlChip(
            title: "Pause",
            systemImage: "pause.fill",
            filled: false,
            compact: compact,
            onDarkIsland: onDarkIsland
          )
        }
        .buttonStyle(.plain)
      }

      Link(destination: URL(string: "pulse://focus/finish")!) {
        ControlChip(
          title: "Finish",
          systemImage: "checkmark",
          filled: true,
          compact: compact,
          onDarkIsland: onDarkIsland
        )
      }
      .buttonStyle(.plain)
    }
  }
}

private struct ControlChip: View {
  let title: String
  let systemImage: String
  let filled: Bool
  let compact: Bool
  var onDarkIsland: Bool = false

  var body: some View {
    let palette = PulseLivePalette.lock
    HStack(spacing: 6) {
      Image(systemName: systemImage)
        .font(.system(size: compact ? 12 : 13, weight: .semibold))
      Text(title)
        .font(.system(size: compact ? 13 : 14, weight: .semibold))
    }
    .foregroundColor(filled ? Color(red: 0.05, green: 0.06, blue: 0.05) : (onDarkIsland ? .white : palette.ink))
    .frame(maxWidth: .infinity)
    .padding(.vertical, compact ? 8 : 10)
    .background(
      Capsule()
        .fill(
          filled
            ? Color(red: 0.62, green: 0.91, blue: 0.44)
            : (onDarkIsland ? Color.white.opacity(0.16) : Color.white.opacity(0.72))
        )
    )
  }
}

private struct RemainingText: View {
  let context: ActivityViewContext<LiveActivitiesAppAttributes>
  let sharedDefault: UserDefaults?

  var body: some View {
    if PulseLiveContent.isPaused(context: context, sharedDefault: sharedDefault) {
      Text(PulseLiveContent.fallbackRemaining(context: context, sharedDefault: sharedDefault))
    } else if let end = PulseLiveContent.endDate(context: context, sharedDefault: sharedDefault),
              end > Date() {
      // Stable closed range from segment start → end so rebuilds never invent a
      // new deadline (Date()...end would still count down, but startAtMs keeps
      // the interval identical to the app's wall-clock segment).
      let start = PulseLiveContent.startDate(context: context, sharedDefault: sharedDefault)
        ?? end.addingTimeInterval(-max(end.timeIntervalSinceNow, 1))
      let intervalStart = min(start, end.addingTimeInterval(-1))
      Text(timerInterval: intervalStart...end, countsDown: true)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    } else if PulseLiveContent.isFinished(
      context: context,
      sharedDefault: sharedDefault
    ) {
      Text("0:00")
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    } else {
      Text(PulseLiveContent.fallbackRemaining(context: context, sharedDefault: sharedDefault))
    }
  }
}

private enum PulseLivePalette {
  /// Soft mint lock screen — fixed light, never dark green.
  case lock
  case island

  func tint(warning: Bool) -> Color {
    switch self {
    case .lock:
      if warning {
        return Color(red: 1.0, green: 0.93, blue: 0.84)
      }
      return Color(red: 0.89, green: 0.96, blue: 0.84)
    case .island:
      return .clear
    }
  }

  var ink: Color {
    switch self {
    case .lock:
      return Color(red: 0.05, green: 0.06, blue: 0.05)
    case .island:
      return .white
    }
  }

  var muted: Color {
    switch self {
    case .lock:
      return Color(red: 0.27, green: 0.28, blue: 0.27)
    case .island:
      return Color.white.opacity(0.8)
    }
  }

  func accent(warning: Bool) -> Color {
    if warning {
      return Color(red: 0.95, green: 0.62, blue: 0.22)
    }
    return Color(red: 0.49, green: 0.86, blue: 0.42)
  }
}

private enum PulseLiveContent {
  static func string(
    _ context: ActivityViewContext<LiveActivitiesAppAttributes>,
    _ sharedDefault: UserDefaults?,
    _ key: String
  ) -> String {
    sharedDefault?.string(forKey: context.attributes.prefixedKey(key)) ?? ""
  }

  static func number(
    _ context: ActivityViewContext<LiveActivitiesAppAttributes>,
    _ sharedDefault: UserDefaults?,
    _ key: String
  ) -> Double? {
    let fullKey = context.attributes.prefixedKey(key)
    if let value = sharedDefault?.object(forKey: fullKey) as? NSNumber {
      return value.doubleValue
    }
    return nil
  }

  static func endDate(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?
  ) -> Date? {
    guard let endAtMs = number(context, sharedDefault, "endAtMs"), endAtMs > 0 else { return nil }
    return Date(timeIntervalSince1970: endAtMs / 1000.0)
  }

  static func startDate(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?
  ) -> Date? {
    guard let startAtMs = number(context, sharedDefault, "startAtMs"), startAtMs > 0 else {
      return nil
    }
    return Date(timeIntervalSince1970: startAtMs / 1000.0)
  }

  static func title(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?
  ) -> String {
    let value = string(context, sharedDefault, "title")
    return value.isEmpty ? "Pulse" : value
  }

  static func subtitle(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?
  ) -> String {
    let quote = string(context, sharedDefault, "quote")
    if !quote.isEmpty { return quote }
    let value = string(context, sharedDefault, "subtitle")
    return value.isEmpty ? "Stay with it" : value
  }

  static func quoteLine(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?
  ) -> String {
    let quote = subtitle(context: context, sharedDefault: sharedDefault)
    if isPaused(context: context, sharedDefault: sharedDefault) {
      return "\(quote) · Paused"
    }
    if isWarning(context: context, sharedDefault: sharedDefault) {
      return "\(quote) · Wrapping up"
    }
    return quote
  }

  static func isPaused(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?
  ) -> Bool {
    string(context, sharedDefault, "status") == "paused"
  }

  static func isFinished(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?,
    now: Date = Date()
  ) -> Bool {
    if isPaused(context: context, sharedDefault: sharedDefault) { return false }
    if let end = endDate(context: context, sharedDefault: sharedDefault), end <= now {
      return true
    }
    if let remaining = number(context, sharedDefault, "remainingSeconds") {
      return remaining <= 0
    }
    return false
  }

  static func fallbackRemaining(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?
  ) -> String {
    let value = string(context, sharedDefault, "remainingLabel")
    return value.isEmpty ? "--:--" : value
  }

  static func isWarning(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?
  ) -> Bool {
    if isPaused(context: context, sharedDefault: sharedDefault) { return false }
    if let remaining = number(context, sharedDefault, "remainingSeconds") {
      return remaining > 0 && remaining <= 10
    }
    if let end = endDate(context: context, sharedDefault: sharedDefault) {
      return end.timeIntervalSinceNow > 0 && end.timeIntervalSinceNow <= 10
    }
    return false
  }
}
