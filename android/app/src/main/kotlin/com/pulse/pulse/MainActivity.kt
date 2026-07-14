package com.pulse.pulse

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.live_activities.LiveActivityManagerHolder

class MainActivity : FlutterActivity() {
    private var actionSink: EventChannel.EventSink? = null
    private var pendingAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val manager = CustomLiveActivityManager(this)
        LiveActivityManagerHolder.instance = manager

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pulse/focus_actions",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                actionSink = events
                pendingAction?.let {
                    events?.success(it)
                    pendingAction = null
                }
            }

            override fun onCancel(arguments: Any?) {
                actionSink = null
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pulse/focus_alerts",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    val remaining = (call.argument<Number>("remainingSeconds"))?.toLong() ?: 0L
                    val endAtMs = (call.argument<Number>("endAtMs"))?.toLong()
                    val quote = call.argument<String>("quote") ?: ""
                    val paused = call.argument<Boolean>("paused") ?: false
                    val warningEnabled = call.argument<Boolean>("warningEnabled") ?: true
                    val ticksEnabled = call.argument<Boolean>("ticksEnabled") ?: true
                    val completionEnabled = call.argument<Boolean>("completionEnabled") ?: true
                    manager.scheduleAlerts(
                        remaining,
                        paused,
                        quote,
                        endAtMs,
                        warningEnabled,
                        ticksEnabled,
                        completionEnabled,
                        soundPack = call.argument<String>("soundPack") ?: "soft",
                    )
                    result.success(null)
                }
                "cancel" -> {
                    manager.cancelAlerts()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        handleFocusIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleFocusIntent(intent)
    }

    private fun handleFocusIntent(intent: Intent?) {
        val action = when (intent?.action) {
            CustomLiveActivityManager.ACTION_PAUSE -> "pause"
            CustomLiveActivityManager.ACTION_RESUME -> "resume"
            CustomLiveActivityManager.ACTION_FINISH -> "finish"
            Intent.ACTION_VIEW -> {
                val path = intent.data?.lastPathSegment?.lowercase().orEmpty()
                when (path) {
                    "pause" -> "pause"
                    "resume" -> "resume"
                    "finish", "stop" -> "finish"
                    else -> null
                }
            }
            else -> null
        } ?: return

        val sink = actionSink
        if (sink != null) {
            sink.success(action)
        } else {
            pendingAction = action
        }
    }
}
