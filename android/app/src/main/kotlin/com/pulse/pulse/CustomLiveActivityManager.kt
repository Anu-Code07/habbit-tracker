package com.pulse.pulse

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.live_activities.LiveActivityManager

class CustomLiveActivityManager(context: Context) : LiveActivityManager(context) {
    private val appContext: Context = context.applicationContext

    private val pendingIntent: PendingIntent = PendingIntent.getActivity(
        appContext,
        200,
        Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private val remoteViews = RemoteViews(
        appContext.packageName,
        R.layout.live_activity,
    )

    private fun updateRemoteViews(data: Map<String, Any>) {
        val title = data["title"] as? String ?: "Pulse Focus"
        val subtitle = data["subtitle"] as? String ?: ""
        val remaining = data["remainingLabel"] as? String ?: "--:--"
        val status = data["status"] as? String ?: "running"

        remoteViews.setTextViewText(R.id.live_title, title)
        remoteViews.setTextViewText(R.id.live_subtitle, subtitle)
        remoteViews.setTextViewText(R.id.live_remaining, remaining)
        remoteViews.setTextViewText(
            R.id.live_status,
            if (status == "paused") "Paused" else "Focusing",
        )
    }

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>,
    ): Notification {
        updateRemoteViews(data)

        val title = data["title"] as? String ?: "Pulse Focus"
        val remaining = data["remainingLabel"] as? String ?: ""

        return notification
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentTitle(title)
            .setContentText(remaining)
            .setContentIntent(pendingIntent)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setPriority(Notification.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }
}
