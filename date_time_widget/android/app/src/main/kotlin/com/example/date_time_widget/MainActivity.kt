package com.example.date_time_widget

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val WIDGET_CHANNEL = "com.example.date_time_widget/widgets"
    private val NOTIF_CHANNEL = "com.example.date_time_widget/notification"
    private val FLOATING_CHANNEL = "com.example.date_time_widget/floating_bar"
    private var deepLinkChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Deep link channel (widget tap → editor) ─────────
        deepLinkChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.date_time_widget/deep_link",
        )
        // Check if launched from widget tap
        handleDeepLink(intent)

        // ── Widget channel ──────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgets" -> {
                    DateTimeWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                "requestWidgetPick" -> {
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }

        // ── Notification channel ────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIF_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startNotification" -> {
                    NotificationIconService.start(this)
                    result.success(true)
                }
                "stopNotification" -> {
                    NotificationIconService.stop(this)
                    result.success(true)
                }
                "updateNotification" -> {
                    NotificationIconService.update(this)
                    result.success(true)
                }
                "isNotificationEnabled" -> {
                    result.success(NotificationIconService.isEnabled(this))
                }
                else -> result.notImplemented()
            }
        }

        // ── Floating bar channel ────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FLOATING_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startFloatingBar" -> {
                    FloatingBarService.start(this)
                    result.success(true)
                }
                "stopFloatingBar" -> {
                    FloatingBarService.stop(this)
                    result.success(true)
                }
                "updateFloatingBar" -> {
                    FloatingBarService.update(this)
                    result.success(true)
                }
                "isFloatingBarEnabled" -> {
                    result.success(FloatingBarService.isEnabled(this))
                }
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true // pre-M, permission granted at install
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName"),
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    // ── Deep link handling (widget tap → open editor) ───────

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent) {
        if (intent.getBooleanExtra("open_editor", false)) {
            deepLinkChannel?.invokeMethod("openEditor", null)
        }
    }
}
