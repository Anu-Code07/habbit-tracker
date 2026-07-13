package com.pulse.pulse

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PulseHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val habitsLabel = widgetData.getString("habits_label", null) ?: "— / —"
            val focusMinutes = widgetData.getInt("focus_minutes", 0)
            val status = widgetData.getString("status_label", null) ?: "Open Pulse to sync"

            val views = RemoteViews(context.packageName, R.layout.pulse_home_widget).apply {
                setTextViewText(R.id.widget_habits, habitsLabel)
                setTextViewText(R.id.widget_focus, "$focusMinutes min")
                setTextViewText(R.id.widget_status, status)

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, launchIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
