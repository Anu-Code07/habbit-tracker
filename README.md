# Pulse

A calm habit tracker and focus timer for small daily rituals.

Pulse keeps habits colorful and finishable, protects attention with Pomodoro or free focus, and shows a quiet weekly view of your rhythm. Everything stays on your device — no account required.

<p align="center">
  <img src="docs/screenshots/today.png" alt="Today — habit check-ins" width="220" />
  &nbsp;
  <img src="docs/screenshots/focus.png" alt="Focus — timer session" width="220" />
  &nbsp;
  <img src="docs/screenshots/insights.png" alt="Insights — weekly rhythm" width="220" />
</p>

<p align="center">
  <em>Today · Focus · Insights</em>
</p>

---

## Features

- **Today** — colorful habit grid, week/month calendar, streaks, rotating short greetings
- **Focus** — Pomodoro or free session, Cupertino length picker, pause / resume / finish with accurate elapsed time
- **Live Activities** — iOS Dynamic Island / lock screen + Android ongoing focus notification
- **Home screen widget** — today’s habits done/total and focus minutes (iOS + Android)
- **Insights** — weekly completion rate, daily check-in bars, focus minutes
- **Onboarding** — optional name, starter habits (stable IDs — no duplicates on re-run)
- **Settings** — haptics, export / restore backup, reset data
- **Local-first** — Drift / SQLite + SharedPreferences

## Screens

| | |
|:--:|:--:|
| **Today** | Habit grid, calendar strip, soft greetings |
| **Focus** | Timer room with tips, pause & finish |
| **Insights** | Completion %, focus minutes, daily bars |
| **Settings** | Preferences & on-device backup |

## Stack

- Flutter (Dart 3.9+)
- `flutter_bloc` · `get_it` · `go_router`
- Drift (SQLite)
- `google_fonts` · `home_widget` · Live Activities

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # when Drift models change
flutter run
```

### Platforms

| Platform | Notes |
|----------|--------|
| **Android** | API 24+ (home widget + focus live notification) |
| **iOS** | 16.1+ for Live Activities / home widget (App Group: `group.com.pulse.pulse`) |

### Add the home widget

1. Open Pulse once so today’s stats can sync.
2. **Android:** long-press home → Widgets → **Pulse Today**
3. **iOS:** Edit Home Screen → Add Widget → **Pulse** → **Pulse Today**

## Project layout

```
lib/
  core/           # theme, DI, router, database, shared widgets
  features/
    habits/       # today + habit CRUD
    focus/        # timer + live activity
    insights/
    onboarding/
    settings/
    splash/
ios/PulseLiveActivity/              # Live Activity + home widget
android/.../PulseHomeWidgetProvider.kt
docs/screenshots/                   # README previews
```

## Backup & reset

In **Settings**:

- **Export backup** — JSON of habits, check-ins, focus history, and settings
- **Restore backup** — replaces current local data
- **Reset all data** — clears local DB + onboarding flag

## Notes

- Name is optional in onboarding; Today may softly ask once per session
- Starter habits use stable IDs; duplicate active names are archived on Today load
- Focus **Finish** records elapsed time (not the remaining countdown)
- Pomodoro length is set on the Focus setup screen (15–60 min)

## License

Private / personal project unless otherwise stated.
