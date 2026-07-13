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

  // Lock-screen Live Activities inherit dark-mode text (white) by default.
  // Our tint is light lime — force dark ink for readable contrast.
  private let ink = Color(red: 0.05, green: 0.06, blue: 0.05)
  private let bodyMuted = Color(red: 0.27, green: 0.28, blue: 0.27)

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      lockScreenView(context: context)
        .activityBackgroundTint(tintColor(context: context))
        .activitySystemActionForegroundColor(ink)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text("Pulse")
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
        }
        DynamicIslandExpandedRegion(.trailing) {
          remainingText(context: context)
            .font(.title2.bold().monospacedDigit())
            .foregroundColor(accentColor(context: context))
        }
        DynamicIslandExpandedRegion(.center) {
          Text(quoteLine(context: context))
            .font(.caption.weight(.semibold))
            .foregroundColor(accentColor(context: context))
            .lineLimit(2)
            .multilineTextAlignment(.center)
        }
        DynamicIslandExpandedRegion(.bottom) {
          controlButtons(context: context, compact: true)
        }
      } compactLeading: {
        Image(systemName: isWarning(context: context) ? "exclamationmark.circle.fill" : "timer")
          .foregroundColor(accentColor(context: context))
      } compactTrailing: {
        remainingText(context: context)
          .font(.caption.bold().monospacedDigit())
          .foregroundColor(.white)
      } minimal: {
        Image(systemName: isWarning(context: context) ? "exclamationmark.circle.fill" : "timer")
          .foregroundColor(accentColor(context: context))
      }
    }
  }

  @ViewBuilder
  private func lockScreenView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
    VStack(spacing: 12) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(title(context: context))
            .font(.headline.weight(.semibold))
            .foregroundColor(ink)
          Text(quoteLine(context: context))
            .font(.caption.weight(.medium))
            .foregroundColor(bodyMuted)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 8)
        remainingText(context: context)
          .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
          .foregroundColor(ink)
          .minimumScaleFactor(0.7)
          .lineLimit(1)
      }

      // Controls sit on the bottom of the Live Activity card.
      controlButtons(context: context, compact: false)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
  }

  @ViewBuilder
  private func controlButtons(
    context: ActivityViewContext<LiveActivitiesAppAttributes>,
    compact: Bool
  ) -> some View {
    HStack(spacing: 10) {
      if isPaused(context: context) {
        Link(destination: URL(string: "pulse://focus/resume")!) {
          controlChip(
            title: "Resume",
            systemImage: "play.fill",
            filled: true,
            compact: compact
          )
        }
        .buttonStyle(.plain)
      } else {
        Link(destination: URL(string: "pulse://focus/pause")!) {
          controlChip(
            title: "Pause",
            systemImage: "pause.fill",
            filled: false,
            compact: compact
          )
        }
        .buttonStyle(.plain)
      }

      Link(destination: URL(string: "pulse://focus/finish")!) {
        controlChip(
          title: "Finish",
          systemImage: "checkmark",
          filled: true,
          compact: compact
        )
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private func controlChip(
    title: String,
    systemImage: String,
    filled: Bool,
    compact: Bool
  ) -> some View {
    HStack(spacing: 6) {
      Image(systemName: systemImage)
        .font(.system(size: compact ? 12 : 13, weight: .semibold))
      Text(title)
        .font(.system(size: compact ? 13 : 14, weight: .semibold))
    }
    .foregroundColor(filled ? Color(red: 0.05, green: 0.06, blue: 0.05) : ink)
    .frame(maxWidth: .infinity)
    .padding(.vertical, compact ? 8 : 10)
    .background(
      Capsule()
        .fill(filled ? Color(red: 0.62, green: 0.91, blue: 0.44) : Color.white.opacity(0.72))
    )
  }

  @ViewBuilder
  private func remainingText(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
    if isPaused(context: context) {
      Text(fallbackRemainingLabel(context: context))
    } else if let end = endDate(context: context), end > Date() {
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
    let quote = string(context, "quote")
    if !quote.isEmpty { return quote }
    let value = string(context, "subtitle")
    return value.isEmpty ? "Stay with it" : value
  }

  private func quoteLine(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    let quote = subtitle(context: context)
    if isPaused(context: context) {
      return "\(quote) · Paused"
    }
    if isWarning(context: context) {
      return "\(quote) · Wrapping up"
    }
    return quote
  }

  private func isPaused(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Bool {
    string(context, "status") == "paused"
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
    return Color(red: 0.12, green: 0.48, blue: 0.22)
  }

  private func tintColor(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Color {
    if isWarning(context: context) {
      return Color(red: 1.0, green: 0.93, blue: 0.84)
    }
    return Color(red: 0.89, green: 0.96, blue: 0.84)
  }
}
