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
      lockScreenView(context: context)
        .activityBackgroundTint(tintColor(context: context))
        .activitySystemActionForegroundColor(Color(red: 0.05, green: 0.06, blue: 0.05))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text("Pulse")
            .font(.headline)
            .foregroundColor(Color(red: 0.05, green: 0.06, blue: 0.05))
        }
        DynamicIslandExpandedRegion(.trailing) {
          remainingText(context: context)
            .font(.title2.bold().monospacedDigit())
            .foregroundColor(accentColor(context: context))
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack {
            Text(subtitle(context: context))
            Spacer()
            Text(status(context: context))
              .foregroundColor(accentColor(context: context))
          }
          .font(.subheadline)
        }
      } compactLeading: {
        Image(systemName: isWarning(context: context) ? "exclamationmark.circle.fill" : "timer")
          .foregroundColor(accentColor(context: context))
      } compactTrailing: {
        remainingText(context: context)
          .font(.caption.bold().monospacedDigit())
          .foregroundColor(accentColor(context: context))
      } minimal: {
        Image(systemName: isWarning(context: context) ? "exclamationmark.circle.fill" : "timer")
          .foregroundColor(accentColor(context: context))
      }
    }
  }

  @ViewBuilder
  private func lockScreenView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title(context: context))
          .font(.headline)
        Text(subtitle(context: context))
          .font(.subheadline)
          .foregroundColor(.secondary)
        Text(status(context: context))
          .font(.caption)
          .foregroundColor(accentColor(context: context))
      }
      Spacer()
      remainingText(context: context)
        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
        .foregroundColor(accentColor(context: context))
    }
    .padding(20)
  }

  @ViewBuilder
  private func remainingText(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
    if isPaused(context: context) {
      Text(fallbackRemainingLabel(context: context))
    } else if let end = endDate(context: context), end > Date() {
      // Native countdown keeps ticking even when Flutter updates throttle.
      Text(timerInterval: Date()...end, countsDown: true)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    } else {
      Text(fallbackRemainingLabel(context: context))
    }
  }

  private func string(_ context: ActivityViewContext<LiveActivitiesAppAttributes>, _ key: String) -> String {
    sharedDefault?.string(forKey: context.attributes.prefixedKey(key)) ?? ""
  }

  private func number(_ context: ActivityViewContext<LiveActivitiesAppAttributes>, _ key: String) -> Double? {
    let defaults = sharedDefault
    let fullKey = context.attributes.prefixedKey(key)
    if let value = defaults?.object(forKey: fullKey) as? NSNumber {
      return value.doubleValue
    }
    return nil
  }

  private func endDate(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Date? {
    guard let endAtMs = number(context, "endAtMs"), endAtMs > 0 else { return nil }
    return Date(timeIntervalSince1970: endAtMs / 1000.0)
  }

  private func title(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    let value = string(context, "title")
    return value.isEmpty ? "Pulse Focus" : value
  }

  private func subtitle(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    let value = string(context, "subtitle")
    return value.isEmpty ? "Focus session" : value
  }

  private func isPaused(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Bool {
    string(context, "status") == "paused"
  }

  private func status(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    if isPaused(context: context) { return "Paused" }
    if isWarning(context: context) { return "Wrapping up" }
    return "Focusing"
  }

  private func fallbackRemainingLabel(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    let value = string(context, "remainingLabel")
    return value.isEmpty ? "--:--" : value
  }

  private func isWarning(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Bool {
    if isPaused(context: context) { return false }
    if let remaining = number(context, "remainingSeconds") {
      return remaining > 0 && remaining <= 10
    }
    if let end = endDate(context: context) {
      return end.timeIntervalSinceNow > 0 && end.timeIntervalSinceNow <= 10
    }
    return false
  }

  private func accentColor(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Color {
    if isWarning(context: context) {
      return Color(red: 0.86, green: 0.45, blue: 0.12)
    }
    return Color(red: 0.18, green: 0.68, blue: 0.29)
  }

  private func tintColor(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Color {
    if isWarning(context: context) {
      return Color(red: 1.0, green: 0.93, blue: 0.84)
    }
    return Color(red: 0.89, green: 0.96, blue: 0.84)
  }
}
