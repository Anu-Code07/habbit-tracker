package com.pulse.pulse

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import com.example.live_activities.LiveActivityManager

/**
 * Android focus "Live Activity" = ongoing notification.
 *
 * When the app is backgrounded, Flutter may sleep — so warning + ticks +
 * completion sounds are scheduled with AlarmManager and fired by
 * [FocusAlertReceiver] (notification channels for warn/complete; MediaPlayer
 * for per-second ticks so we don't spam the shade).
 */
class CustomLiveActivityManager(context: Context) : LiveActivityManager(context) {
    private val appContext: Context = context.applicationContext

    companion object {
        const val CHANNEL_PROGRESS = "Pulse Focus"
        // v2 — prior builds used a broken resource URI and stayed silent.
        const val CHANNEL_WARN = "pulse_focus_warn_v2"
        const val CHANNEL_COMPLETE = "pulse_focus_complete_v2"
        const val CHANNEL_WARN_WOOD = "pulse_focus_warn_wood_v2"
        const val CHANNEL_COMPLETE_WOOD = "pulse_focus_complete_wood_v2"
        // Visual-only banners — audio is MediaPlayer ALARM (avoids double chime).
        const val CHANNEL_ALERT_BANNER = "pulse_focus_alert_banner_v2"

        const val ACTION_PAUSE = "com.pulse.pulse.FOCUS_PAUSE"
        const val ACTION_RESUME = "com.pulse.pulse.FOCUS_RESUME"
        const val ACTION_FINISH = "com.pulse.pulse.FOCUS_FINISH"
        const val ACTION_WARN = "com.pulse.pulse.FOCUS_WARN"
        const val ACTION_COMPLETE = "com.pulse.pulse.FOCUS_COMPLETE"
        const val ACTION_TICK = "com.pulse.pulse.FOCUS_TICK"

        const val EXTRA_QUOTE = "quote"
        const val EXTRA_SOUND_PACK = "soundPack"

        private const val PREFS = "pulse_focus_alerts"
        private const val PREF_SOUND_PACK = "sound_pack"

        private const val REQ_PAUSE = 301
        private const val REQ_RESUME = 302
        private const val REQ_FINISH = 303
        private const val REQ_WARN = 304
        private const val REQ_COMPLETE = 305
        private const val REQ_TICK_BASE = 400
        private const val ALERT_BASE_ID = 4242
    }

    private val openAppIntent: PendingIntent = PendingIntent.getActivity(
        appContext,
        200,
        Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private val remoteViews = RemoteViews(
        appContext.packageName,
        R.layout.live_activity,
    )

    /** Avoid re-arming AlarmManager on every notification refresh. */
    private var lastScheduledEndAtMs: Long = -1L
    private var lastScheduledPaused: Boolean = true
    private var activeSoundPack: String = "soft"

    init {
        restoreSoundPack()
        ensureChannels()
    }

    private fun rawSoundUri(name: String): Uri =
        Uri.parse("android.resource://${appContext.packageName}/raw/$name")

    private fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Drop legacy broken channels (wrong sound URI / silent).
        listOf(
            "Pulse Focus Warning",
            "Pulse Focus Complete",
            "Pulse Focus Warning · Wood",
            "Pulse Focus Complete · Wood",
        ).forEach { legacy ->
            runCatching { manager.deleteNotificationChannel(legacy) }
        }

        if (manager.getNotificationChannel(CHANNEL_PROGRESS) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_PROGRESS,
                    "Pulse Focus",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                },
            )
        }

        ensureSoundingChannel(manager, CHANNEL_WARN, "Focus warning (10s)", "focus_warning")
        ensureSoundingChannel(manager, CHANNEL_COMPLETE, "Focus complete", "focus_complete")
        ensureSoundingChannel(
            manager,
            CHANNEL_WARN_WOOD,
            "Focus warning (wood)",
            "focus_warning_wood",
        )
        ensureSoundingChannel(
            manager,
            CHANNEL_COMPLETE_WOOD,
            "Focus complete (wood)",
            "focus_complete_wood",
        )
        if (manager.getNotificationChannel(CHANNEL_ALERT_BANNER) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ALERT_BANNER,
                    "Focus alerts",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Focus warning/complete banners (sound via MediaPlayer)"
                    setSound(null, null)
                    enableVibration(true)
                    setShowBadge(true)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                },
            )
        }
    }

    private fun warnChannel(): String =
        if (activeSoundPack == "wood") CHANNEL_WARN_WOOD else CHANNEL_WARN

    private fun completeChannel(): String =
        if (activeSoundPack == "wood") CHANNEL_COMPLETE_WOOD else CHANNEL_COMPLETE

    private fun tickRaw(): Int =
        if (activeSoundPack == "wood") R.raw.focus_tick_wood else R.raw.focus_tick

    private fun completeRaw(): Int =
        if (activeSoundPack == "wood") R.raw.focus_complete_wood else R.raw.focus_complete

    private fun warnRaw(): Int =
        if (activeSoundPack == "wood") R.raw.focus_warning_wood else R.raw.focus_warning

    private fun completeRawName(): String =
        if (activeSoundPack == "wood") "focus_complete_wood" else "focus_complete"

    private fun warnRawName(): String =
        if (activeSoundPack == "wood") "focus_warning_wood" else "focus_warning"

    private fun ensureSoundingChannel(
        manager: NotificationManager,
        id: String,
        description: String,
        rawName: String,
    ) {
        if (manager.getNotificationChannel(id) != null) return
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        manager.createNotificationChannel(
            NotificationChannel(
                id,
                description,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                this.description = description
                setSound(rawSoundUri(rawName), attrs)
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            },
        )
    }

    fun applySoundPack(pack: String) {
        activeSoundPack = pack
        appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(PREF_SOUND_PACK, pack)
            .apply()
    }

    fun restoreSoundPack(fallback: String = "soft") {
        activeSoundPack = appContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(PREF_SOUND_PACK, fallback)
            ?: fallback
    }

    private fun isSystemDark(): Boolean {
        val mode = appContext.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return mode == Configuration.UI_MODE_NIGHT_YES
    }

    private fun actionPendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(appContext, MainActivity::class.java).apply {
            this.action = action
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_NEW_TASK
        }
        return PendingIntent.getActivity(
            appContext,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun alarmPendingIntent(action: String, requestCode: Int, quote: String): PendingIntent {
        val intent = Intent(appContext, FocusAlertReceiver::class.java).apply {
            this.action = action
            putExtra(EXTRA_QUOTE, quote)
            putExtra(EXTRA_SOUND_PACK, activeSoundPack)
        }
        return PendingIntent.getBroadcast(
            appContext,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun cancelAlerts() {
        val alarm = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.cancel(alarmPendingIntent(ACTION_WARN, REQ_WARN, ""))
        alarm.cancel(alarmPendingIntent(ACTION_COMPLETE, REQ_COMPLETE, ""))
        for (sec in 1..9) {
            alarm.cancel(alarmPendingIntent(ACTION_TICK, REQ_TICK_BASE + sec, ""))
        }
        lastScheduledEndAtMs = -1L
        lastScheduledPaused = true
    }

    /**
     * Prefer wall-clock [endAtMs] so Doze/background doesn't drift elapsed timers.
     * Idempotent for the same deadline — safe to call from Flutter and notification builds.
     */
    fun scheduleAlerts(
        remainingSeconds: Long,
        paused: Boolean,
        quote: String,
        endAtMs: Long?,
        warningEnabled: Boolean = true,
        ticksEnabled: Boolean = true,
        completionEnabled: Boolean = true,
        soundPack: String = "soft",
        force: Boolean = false,
    ) {
        activeSoundPack = soundPack
        applySoundPack(soundPack)
        if (paused || remainingSeconds <= 0L || soundPack == "silent") {
            cancelAlerts()
            return
        }

        val nowWall = System.currentTimeMillis()
        val endWall = when {
            endAtMs != null && endAtMs > nowWall -> endAtMs
            else -> nowWall + remainingSeconds * 1000L
        }
        if (!force &&
            !lastScheduledPaused &&
            lastScheduledEndAtMs == endWall
        ) {
            return
        }

        cancelAlerts()
        lastScheduledEndAtMs = endWall
        lastScheduledPaused = false
        applySoundPack(soundPack)

        val alarm = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        fun setExact(triggerAtMs: Long, action: String, requestCode: Int) {
            if (triggerAtMs <= nowWall + 250L) return
            val pi = alarmPendingIntent(action, requestCode, quote)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarm.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMs,
                        pi,
                    )
                } else {
                    alarm.setExact(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
                }
            } catch (_: SecurityException) {
                alarm.set(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            }
        }

        val warnAt = endWall - 10_000L
        if (warningEnabled && remainingSeconds > 10L && warnAt > nowWall) {
            setExact(warnAt, ACTION_WARN, REQ_WARN)
        }
        // Native ticks cover lock/Doze; Flutter skips ticks when not resumed.
        if (ticksEnabled) {
            for (secLeft in 1..9) {
                if (remainingSeconds <= secLeft) continue
                val tickAt = endWall - secLeft * 1000L
                setExact(tickAt, ACTION_TICK, REQ_TICK_BASE + secLeft)
            }
        }
        if (completionEnabled) {
            setExact(endWall, ACTION_COMPLETE, REQ_COMPLETE)
        }
    }

    /** Short tick — no notification shade spam. */
    fun playTickSound() {
        playRaw(tickRaw())
    }

    fun playWarnSound() {
        playRaw(warnRaw())
    }

    fun playCompleteSound() {
        playRaw(completeRaw())
    }

    /**
     * Plays via ALARM usage so completion/ticks still cut through focus-mode
     * and are louder than media stream defaults.
     */
    private fun playRaw(resId: Int) {
        try {
            val afd = appContext.resources.openRawResourceFd(resId) ?: return
            val player = MediaPlayer()
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            player.setOnCompletionListener { p ->
                try {
                    p.release()
                } catch (_: Exception) {
                }
            }
            player.setOnErrorListener { p, _, _ ->
                try {
                    p.release()
                } catch (_: Exception) {
                }
                true
            }
            player.prepare()
            player.start()
        } catch (_: Exception) {
            // Fall back to create() if openRawResourceFd path fails.
            try {
                MediaPlayer.create(appContext, resId)?.apply {
                    setOnCompletionListener { it.release() }
                    start()
                }
            } catch (_: Exception) {
            }
        }
    }

    private fun formatRemaining(seconds: Long): String {
        val safe = seconds.coerceAtLeast(0L)
        val m = safe / 60
        val s = safe % 60
        return "%02d:%02d".format(m, s)
    }

    private fun longOf(data: Map<String, Any>, key: String): Long? {
        return when (val value = data[key]) {
            is Number -> value.toLong()
            is String -> value.toLongOrNull()
            else -> null
        }
    }

    private fun updateRemoteViews(data: Map<String, Any>) {
        val title = data["title"] as? String ?: "Pulse Focus"
        val subtitle = data["subtitle"] as? String ?: ""
        val status = data["status"] as? String ?: "running"
        val remainingSeconds = longOf(data, "remainingSeconds")?.coerceAtLeast(0L) ?: 0L
        val endAtMs = longOf(data, "endAtMs")
        val paused = status == "paused"
        val nowWall = System.currentTimeMillis()
        val dark = isSystemDark()
        val remainingLabel = when {
            endAtMs != null && endAtMs > nowWall && !paused ->
                formatRemaining((endAtMs - nowWall) / 1000L)
            else -> formatRemaining(remainingSeconds)
        }

        val titleColor = if (dark) Color.parseColor("#F2F4F0") else Color.parseColor("#0E0F0C")
        val subtitleColor = if (dark) Color.parseColor("#B4B8B0") else Color.parseColor("#5C605A")
        val statusColor = if (dark) Color.parseColor("#7ED957") else Color.parseColor("#1B8F3A")

        remoteViews.setTextViewText(R.id.live_title, title)
        remoteViews.setTextViewText(R.id.live_subtitle, subtitle)
        remoteViews.setTextViewText(
            R.id.live_status,
            when {
                remainingSeconds <= 0L || (endAtMs != null && endAtMs <= nowWall && !paused) ->
                    "Complete"
                paused -> "Paused"
                else -> "Focusing"
            },
        )
        remoteViews.setTextColor(R.id.live_title, titleColor)
        remoteViews.setTextColor(R.id.live_subtitle, subtitleColor)
        remoteViews.setTextColor(R.id.live_status, statusColor)
        remoteViews.setTextColor(R.id.live_remaining, titleColor)

        // OS Chronometer from wall-clock deadline — stays aligned without Flutter ticks.
        val runningCountdown = !paused &&
            endAtMs != null &&
            endAtMs > nowWall &&
            remainingSeconds > 0L
        if (runningCountdown) {
            val remainingMs = (endAtMs!! - nowWall).coerceAtLeast(0L)
            val base = SystemClock.elapsedRealtime() + remainingMs
            remoteViews.setChronometerCountDown(R.id.live_remaining, true)
            remoteViews.setChronometer(R.id.live_remaining, base, null, true)
        } else {
            remoteViews.setChronometerCountDown(R.id.live_remaining, true)
            remoteViews.setChronometer(
                R.id.live_remaining,
                SystemClock.elapsedRealtime(),
                null,
                false,
            )
            remoteViews.setTextViewText(R.id.live_remaining, remainingLabel)
        }

        remoteViews.setTextViewText(
            R.id.live_btn_primary,
            if (paused) "Resume" else "Pause",
        )
        remoteViews.setOnClickPendingIntent(
            R.id.live_btn_primary,
            actionPendingIntent(
                if (paused) ACTION_RESUME else ACTION_PAUSE,
                if (paused) REQ_RESUME else REQ_PAUSE,
            ),
        )
        remoteViews.setOnClickPendingIntent(
            R.id.live_btn_finish,
            actionPendingIntent(ACTION_FINISH, REQ_FINISH),
        )
        // Alerts are scheduled only from Flutter MethodChannel (with sound settings).
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
        val remaining = formatRemaining(longOf(data, "remainingSeconds") ?: 0L)
        val alert = wantsAlertSound(data)
        val alertTitle = data["alertTitle"] as? String
        val alertBody = data["alertBody"] as? String
        val channel = when {
            alert && (alertTitle?.contains("complete", ignoreCase = true) == true) ->
                completeChannel()
            alert -> warnChannel()
            else -> CHANNEL_PROGRESS
        }

        val builder = Notification.Builder(appContext, channel)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(!alert)
            .setOnlyAlertOnce(!alert)
            .setContentTitle(if (alert && alertTitle != null) alertTitle else title)
            .setContentText(if (alert && alertBody != null) alertBody else remaining)
            .setContentIntent(openAppIntent)
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
            // Keep the ongoing timer notification — don't turn it into a
            // swipe-awayable alarm banner (completion/warn use a separate id).
            builder.setOnlyAlertOnce(true)
        }

        if (event == "end") {
            cancelAlerts()
        }

        return builder.build()
    }

    fun showBackgroundAlert(kind: String, quote: String?) {
        ensureChannels()
        val manager =
            appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val isWarn = kind == ACTION_WARN
        val title = if (isWarn) "Almost done" else "Focus complete"
        val body = quote?.takeIf { it.isNotBlank() }
            ?: if (isWarn) "10 seconds left" else "Nice work — session finished"

        // Sound comes from MediaPlayer (ALARM) — silent banner channel only.
        val builder = Notification.Builder(appContext, CHANNEL_ALERT_BANNER)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(openAppIntent)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setPriority(Notification.PRIORITY_HIGH)
            .setDefaults(Notification.DEFAULT_VIBRATE)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            builder.setSound(null)
        }

        manager.notify(ALERT_BASE_ID + if (isWarn) 1 else 2, builder.build())

        if (!isWarn) {
            cancelAlerts()
        }
    }
}
