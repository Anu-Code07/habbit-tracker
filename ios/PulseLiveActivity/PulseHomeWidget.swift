import WidgetKit
import SwiftUI

private let widgetGroupId = "group.com.anurag.pulse"

struct PulseHomeEntry: TimelineEntry {
  let date: Date
  let habitsLabel: String
  let focusMinutes: Int
  let statusLabel: String
}

struct PulseHomeProvider: TimelineProvider {
  func placeholder(in context: Context) -> PulseHomeEntry {
    PulseHomeEntry(
      date: Date(),
      habitsLabel: "3 / 5",
      focusMinutes: 25,
      statusLabel: "2 left today"
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (PulseHomeEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PulseHomeEntry>) -> Void) {
    let entry = loadEntry()
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func loadEntry() -> PulseHomeEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let done = data?.integer(forKey: "habits_done") ?? 0
    let total = data?.integer(forKey: "habits_total") ?? 0
    let focus = data?.integer(forKey: "focus_minutes") ?? 0
    let habitsLabel = data?.string(forKey: "habits_label")
      ?? (total == 0 ? "— / —" : "\(done) / \(total)")
    let status = data?.string(forKey: "status_label") ?? "Open Pulse to sync"
    return PulseHomeEntry(
      date: Date(),
      habitsLabel: habitsLabel,
      focusMinutes: focus,
      statusLabel: status
    )
  }
}

struct PulseHomeWidgetView: View {
  var entry: PulseHomeEntry
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let canvas = colorScheme == .dark
      ? Color(red: 0.10, green: 0.14, blue: 0.10)
      : Color(red: 0.89, green: 0.96, blue: 0.84)
    let ink = colorScheme == .dark
      ? Color(red: 0.95, green: 0.96, blue: 0.94)
      : Color(red: 0.05, green: 0.06, blue: 0.05)
    let inkDeep = colorScheme == .dark
      ? Color(red: 0.72, green: 0.90, blue: 0.55)
      : Color(red: 0.09, green: 0.20, blue: 0.0)
    let mute = colorScheme == .dark
      ? Color(red: 0.65, green: 0.68, blue: 0.64)
      : Color(red: 0.53, green: 0.53, blue: 0.52)

    VStack(alignment: .leading, spacing: 10) {
      Text("PULSE")
        .font(.system(size: 11, weight: .heavy, design: .rounded))
        .tracking(2.4)
        .foregroundStyle(ink)

      Text(entry.statusLabel)
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(inkDeep)
        .lineLimit(2)

      Spacer(minLength: 0)

      HStack(alignment: .bottom, spacing: 16) {
        metric(title: "Habits", value: entry.habitsLabel, mute: mute, ink: ink)
        metric(title: "Focus", value: "\(entry.focusMinutes) min", mute: mute, ink: ink)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .modifier(PulseWidgetBackground(color: canvas))
  }

  private func metric(title: String, value: String, mute: Color, ink: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(mute)
      Text(value)
        .font(.system(size: 22, weight: .bold, design: .rounded))
        .foregroundStyle(ink)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct PulseWidgetBackground: ViewModifier {
  let color: Color

  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      content.containerBackground(for: .widget) { color }
    } else {
      content.background(color)
    }
  }
}

struct PulseHomeWidget: Widget {
  let kind: String = "PulseHomeWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PulseHomeProvider()) { entry in
      PulseHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Pulse Today")
    .description("Today's habits and focus minutes.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
