package com.pulse.pulse

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.media.AudioAttributes
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.widget.RemoteViews
import com.example.live_activities.LiveActivityManager

class CustomLiveActivityManager(context: Context) : LiveActivityManager(context) {
    private val appContext: Context = context.applicationContext

    companion object {
        // Quiet ongoing timer updates.
        private const val CHANNEL_PROGRESS = "Pulse Focus"
        // Warning / completion cues — must be a different channel because Android
        // ignores per-notification sound once a channel is created silent.
        private const val CHANNEL_ALERT = "Pulse Focus Alerts"
    }

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

    init {
        ensureChannels()
    }

    private fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (manager.getNotificationChannel(CHANNEL_PROGRESS) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_PROGRESS,
                    CHANNEL_PROGRESS,
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                },
            )
        }

        if (manager.getNotificationChannel(CHANNEL_ALERT) == null) {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_EVENT)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ALERT,
                    CHANNEL_ALERT,
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Focus warning and completion sounds"
                    setSound(Settings.System.DEFAULT_NOTIFICATION_URI, attrs)
                    enableVibration(true)
                    setShowBadge(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                },
            )
        }
    }

    private fun isSystemDark(): Boolean {
        val mode = appContext.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return mode == Configuration.UI_MODE_NIGHT_YES
    }

    private fun updateRemoteViews(data: Map<String, Any>) {
        val title = data["title"] as? String ?: "Pulse Focus"
        val subtitle = data["subtitle"] as? String ?: ""
        val remainingLabel = data["remainingLabel"] as? String ?: "--:--"
        val status = data["status"] as? String ?: "running"
        val remainingSeconds = when (val value = data["remainingSeconds"]) {
            is Number -> value.toLong().coerceAtLeast(0L)
            is String -> value.toLongOrNull()?.coerceAtLeast(0L) ?: 0L
            else -> 0L
        }
        val paused = status == "paused"
        val dark = isSystemDark()

        // Flutter keeps the Activity in light theme; notification shade follows
        // system dark mode — set colors explicitly so dark shade stays readable.
        val titleColor = if (dark) Color.parseColor("#F2F4F0") else Color.parseColor("#0E0F0C")
        val subtitleColor = if (dark) Color.parseColor("#B4B8B0") else Color.parseColor("#5C605A")
        val timerColor = titleColor
        val statusColor = if (dark) Color.parseColor("#7ED957") else Color.parseColor("#1B8F3A")

        remoteViews.setTextViewText(R.id.live_title, title)
        remoteViews.setTextViewText(R.id.live_subtitle, subtitle)
        remoteViews.setTextViewText(
            R.id.live_status,
            if (paused) "Paused" else "Focusing",
        )
        remoteViews.setTextColor(R.id.live_title, titleColor)
        remoteViews.setTextColor(R.id.live_subtitle, subtitleColor)
        remoteViews.setTextColor(R.id.live_status, statusColor)
        remoteViews.setTextColor(R.id.live_remaining, timerColor)

        // iOS Live Activities count down via timerInterval; Android notifications
        // are static unless we drive Chronometer from remainingSeconds.
        if (paused || remainingSeconds <= 0L) {
            remoteViews.setChronometer(
                R.id.live_remaining,
                SystemClock.elapsedRealtime(),
                null,
                false,
            )
            remoteViews.setTextViewText(R.id.live_remaining, remainingLabel)
            remoteViews.setTextColor(R.id.live_remaining, timerColor)
        } else {
            val base = SystemClock.elapsedRealtime() + remainingSeconds * 1000L
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                remoteViews.setChronometerCountDown(R.id.live_remaining, true)
            }
            remoteViews.setChronometer(R.id.live_remaining, base, null, true)
            remoteViews.setTextColor(R.id.live_remaining, timerColor)
        }
    }

    private fun wantsAlertSound(data: Map<String, Any>): Boolean {
        val flag = data["alertSound"]
        return when (flag) {
            is Boolean -> flag
            is Number -> flag.toInt() != 0
            is String -> flag.equals("true", ignoreCase = true)
            else -> false
        }
    }

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>,
    ): Notification {
        ensureChannels()
        updateRemoteViews(data)

        val title = data["title"] as? String ?: "Pulse Focus"
        val remaining = data["remainingLabel"] as? String ?: ""
        val alert = wantsAlertSound(data)
        val alertTitle = data["alertTitle"] as? String
        val alertBody = data["alertBody"] as? String

        // Rebuild on the correct channel — the incoming builder is wired to the
        // silent default channel from LiveActivityManager.
        val builder = Notification.Builder(
            appContext,
            if (alert) CHANNEL_ALERT else CHANNEL_PROGRESS,
        )
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(!alert)
            .setOnlyAlertOnce(!alert)
            .setContentTitle(if (alert && alertTitle != null) alertTitle else title)
            .setContentText(if (alert && alertBody != null) alertBody else remaining)
            .setContentIntent(pendingIntent)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setCategory(
                if (alert) Notification.CATEGORY_ALARM else Notification.CATEGORY_PROGRESS,
            )
            .setVisibility(Notification.VISIBILITY_PUBLIC)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setPriority(
                if (alert) Notification.PRIORITY_HIGH else Notification.PRIORITY_LOW,
            )
        }

        if (alert) {
            builder.setDefaults(Notification.DEFAULT_SOUND or Notification.DEFAULT_VIBRATE)
            builder.setAutoCancel(true)
        }

        return builder.build()
    }
}
