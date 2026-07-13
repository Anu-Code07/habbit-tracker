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
  let sharedDefault = UserDefaults(suiteName: "group.com.pulse.pulse")

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      lockScreenView(context: context)
        .activityBackgroundTint(Color(red: 0.89, green: 0.96, blue: 0.84))
        .activitySystemActionForegroundColor(Color(red: 0.05, green: 0.06, blue: 0.05))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text("Pulse")
            .font(.headline)
            .foregroundColor(Color(red: 0.05, green: 0.06, blue: 0.05))
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(remainingLabel(context: context))
            .font(.title2.bold().monospacedDigit())
            .foregroundColor(Color(red: 0.05, green: 0.06, blue: 0.05))
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack {
            Text(subtitle(context: context))
            Spacer()
            Text(status(context: context))
              .foregroundColor(Color(red: 0.18, green: 0.68, blue: 0.29))
          }
          .font(.subheadline)
        }
      } compactLeading: {
        Image(systemName: "timer")
          .foregroundColor(Color(red: 0.62, green: 0.91, blue: 0.44))
      } compactTrailing: {
        Text(remainingLabel(context: context))
          .font(.caption.bold().monospacedDigit())
          .foregroundColor(Color(red: 0.05, green: 0.06, blue: 0.05))
      } minimal: {
        Image(systemName: "timer")
          .foregroundColor(Color(red: 0.62, green: 0.91, blue: 0.44))
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
          .foregroundColor(Color(red: 0.18, green: 0.68, blue: 0.29))
      }
      Spacer()
      Text(remainingLabel(context: context))
        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
    }
    .padding(20)
  }

  private func string(_ context: ActivityViewContext<LiveActivitiesAppAttributes>, _ key: String) -> String {
    sharedDefault?.string(forKey: context.attributes.prefixedKey(key)) ?? ""
  }

  private func title(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    let value = string(context, "title")
    return value.isEmpty ? "Pulse Focus" : value
  }

  private func subtitle(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    let value = string(context, "subtitle")
    return value.isEmpty ? "Focus session" : value
  }

  private func status(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    string(context, "status") == "paused" ? "Paused" : "Focusing"
  }

  private func remainingLabel(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
    let value = string(context, "remainingLabel")
    return value.isEmpty ? "--:--" : value
  }
}
