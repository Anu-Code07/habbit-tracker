# Pulse

A calm habit tracker and focus timer for small daily rituals — built with Flutter.

Pulse keeps habits colorful and finishable, protects attention with Pomodoro / free focus sessions, and shows a quiet weekly view of your rhythm. Everything stays on your device.

## Features

- **Today** — check in habits, streaks, week/month calendar, rotating short greetings
- **Focus** — Pomodoro or free focus, pause/resume, finish early with accurate elapsed time
- **Live Activities** — iOS Dynamic Island / lock screen + Android ongoing focus notification
- **Home screen widget** — today’s habits done/total and focus minutes (iOS + Android)
- **Insights** — weekly completion rate, check-in bars, focus minutes
- **Onboarding** — optional name, starter habits (no duplicates on re-run)
- **Settings** — haptics, Pomodoro length, export/restore backup, reset data
- **Local-first** — Drift/SQLite + SharedPreferences; no account required

## Screens

| Tab | What you get |
|-----|----------------|
| Today | Habit grid, calendar, check-ins |
| Focus | Timer room, session summary |
| Insights | Weekly rhythm |
| Settings | Preferences & backup |

## Stack

- Flutter (Dart 3.9+)
- flutter_bloc + get_it + go_router
- Drift (SQLite)
- google_fonts, home_widget, live_activities

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # if Drift models change
flutter run
```

### Platforms

- **Android** — API 24+ (home widget + focus live notification)
- **iOS** — 16.1+ for Live Activities / home widget extension (App Group: `group.com.pulse.pulse`)

### Add the home widget

- **Android:** long-press home → Widgets → **Pulse Today**
- **iOS:** Edit Home Screen → Add Widget → **Pulse** → **Pulse Today**

Open the app once after install so the widget can sync today’s stats.

## Project layout

```
lib/
  core/           # theme, DI, router, database, widgets
  features/
    habits/       # today + habit CRUD
    focus/        # timer + live activity
    insights/
    onboarding/
    settings/
    splash/
ios/PulseLiveActivity/   # Live Activity + home widget
android/.../PulseHomeWidgetProvider.kt
```

## Backup & reset

In **Settings**:

- **Export backup** — JSON file of habits, check-ins, focus history, settings
- **Restore backup** — replaces current local data
- **Reset all data** — clears local DB + onboarding flag (shows onboarding again)

## Notes

- Name is optional during onboarding; Today may softly ask once per session
- Starter habits use stable IDs; duplicate names are archived on Today load
- Focus “Finish” records elapsed time (not remaining countdown)

## License

Private / personal project unless otherwise stated.
