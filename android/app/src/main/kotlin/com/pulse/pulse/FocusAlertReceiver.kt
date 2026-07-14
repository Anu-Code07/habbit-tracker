package com.pulse.pulse

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper

/**
 * Fires when Flutter may be suspended (app backgrounded / Doze).
 * Plays pack WAVs via MediaPlayer (ALARM usage) and posts a high-importance alert.
 *
 * Skips tick/warn MediaPlayer when the app is already foreground — Flutter owns those.
 */
class FocusAlertReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        val pending = goAsync()
        try {
            val manager = LiveActivityManagerHolderSafe.get(context)
            val pack = intent.getStringExtra(CustomLiveActivityManager.EXTRA_SOUND_PACK)
            if (!pack.isNullOrBlank()) {
                manager.applySoundPack(pack)
            } else {
                manager.restoreSoundPack()
            }

            val foreground = isAppForeground(context)

            when (action) {
                CustomLiveActivityManager.ACTION_TICK -> {
                    if (!foreground) manager.playTickSound()
                }
                CustomLiveActivityManager.ACTION_WARN -> {
                    if (!foreground) manager.playWarnSound()
                    manager.showBackgroundAlert(action, intent.getStringExtra(CustomLiveActivityManager.EXTRA_QUOTE))
                }
                CustomLiveActivityManager.ACTION_COMPLETE -> {
                    // Always play — process may be suspended with no Flutter sound.
                    manager.playCompleteSound()
                    manager.showBackgroundAlert(action, intent.getStringExtra(CustomLiveActivityManager.EXTRA_QUOTE))
                    manager.endAllActivities(emptyMap())
                }
                else -> Unit
            }
        } finally {
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    pending.finish()
                } catch (_: Exception) {
                }
            }, 2500L)
        }
    }

    private fun isAppForeground(context: Context): Boolean {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return false
        val pkg = context.packageName
        val procs = am.runningAppProcesses ?: return false
        return procs.any {
            it.processName == pkg &&
                it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        }
    }
}

/** Resolves the live-activity manager even if Flutter engine isn't warm yet. */
private object LiveActivityManagerHolderSafe {
    fun get(context: Context): CustomLiveActivityManager {
        val held = com.example.live_activities.LiveActivityManagerHolder.instance
        if (held is CustomLiveActivityManager) return held
        val created = CustomLiveActivityManager(context.applicationContext)
        com.example.live_activities.LiveActivityManagerHolder.instance = created
        return created
    }
}
