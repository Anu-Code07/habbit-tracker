package com.pulse.pulse

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Fires when Flutter may be suspended (app backgrounded / Doze).
 * Plays the system notification sound via [CustomLiveActivityManager.CHANNEL_ALERT].
 */
class FocusAlertReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        val manager = LiveActivityManagerHolderSafe.get(context)
        when (action) {
            CustomLiveActivityManager.ACTION_TICK -> {
                manager.playTickSound()
            }
            CustomLiveActivityManager.ACTION_WARN,
            CustomLiveActivityManager.ACTION_COMPLETE -> {
                val quote = intent.getStringExtra(CustomLiveActivityManager.EXTRA_QUOTE)
                manager.showBackgroundAlert(action, quote)
            }
            else -> return
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
