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
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text("Pulse")
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
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
            scheme: .dark
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

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let palette = PulseLivePalette.lock(colorScheme)
    let warning = PulseLiveContent.isWarning(context: context, sharedDefault: sharedDefault)

    VStack(spacing: 12) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(PulseLiveContent.title(context: context, sharedDefault: sharedDefault))
            .font(.headline.weight(.semibold))
            .foregroundColor(palette.ink)
          Text(PulseLiveContent.quoteLine(context: context, sharedDefault: sharedDefault))
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

      ControlButtons(
        context: context,
        sharedDefault: sharedDefault,
        compact: false,
        scheme: colorScheme
      )
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
    .activityBackgroundTint(palette.tint(warning: warning))
    .activitySystemActionForegroundColor(palette.ink)
  }
}

private struct ControlButtons: View {
  let context: ActivityViewContext<LiveActivitiesAppAttributes>
  let sharedDefault: UserDefaults?
  let compact: Bool
  let scheme: ColorScheme

  var body: some View {
    let paused = PulseLiveContent.isPaused(context: context, sharedDefault: sharedDefault)
    HStack(spacing: 10) {
      if paused {
        Link(destination: URL(string: "pulse://focus/resume")!) {
          ControlChip(title: "Resume", systemImage: "play.fill", filled: true, compact: compact, scheme: scheme)
        }
        .buttonStyle(.plain)
      } else {
        Link(destination: URL(string: "pulse://focus/pause")!) {
          ControlChip(title: "Pause", systemImage: "pause.fill", filled: false, compact: compact, scheme: scheme)
        }
        .buttonStyle(.plain)
      }

      Link(destination: URL(string: "pulse://focus/finish")!) {
        ControlChip(title: "Finish", systemImage: "checkmark", filled: true, compact: compact, scheme: scheme)
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
  let scheme: ColorScheme

  var body: some View {
    let palette = PulseLivePalette.lock(scheme)
    HStack(spacing: 6) {
      Image(systemName: systemImage)
        .font(.system(size: compact ? 12 : 13, weight: .semibold))
      Text(title)
        .font(.system(size: compact ? 13 : 14, weight: .semibold))
    }
    .foregroundColor(filled ? Color(red: 0.05, green: 0.06, blue: 0.05) : palette.ink)
    .frame(maxWidth: .infinity)
    .padding(.vertical, compact ? 8 : 10)
    .background(
      Capsule()
        .fill(
          filled
            ? Color(red: 0.62, green: 0.91, blue: 0.44)
            : (scheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.72))
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
      Text(timerInterval: Date()...end, countsDown: true)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    } else {
      Text(PulseLiveContent.fallbackRemaining(context: context, sharedDefault: sharedDefault))
    }
  }
}

private enum PulseLivePalette {
  case lock(ColorScheme)
  case island

  func tint(warning: Bool) -> Color {
    switch self {
    case .lock(let scheme):
      if warning {
        return scheme == .dark
          ? Color(red: 0.32, green: 0.20, blue: 0.08)
          : Color(red: 1.0, green: 0.93, blue: 0.84)
      }
      return scheme == .dark
        ? Color(red: 0.10, green: 0.18, blue: 0.11)
        : Color(red: 0.89, green: 0.96, blue: 0.84)
    case .island:
      return .clear
    }
  }

  var ink: Color {
    switch self {
    case .lock(let scheme):
      return scheme == .dark
        ? Color(red: 0.95, green: 0.96, blue: 0.94)
        : Color(red: 0.05, green: 0.06, blue: 0.05)
    case .island:
      return .white
    }
  }

  var muted: Color {
    switch self {
    case .lock(let scheme):
      return scheme == .dark
        ? Color(red: 0.70, green: 0.73, blue: 0.68)
        : Color(red: 0.27, green: 0.28, blue: 0.27)
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

  static func title(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    sharedDefault: UserDefaults?
  ) -> String {
    let value = string(context, sharedDefault, "title")
    return value.isEmpty ? "Pulse Focus" : value
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
