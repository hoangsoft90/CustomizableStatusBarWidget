package com.example.date_time_widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Listens for [android.intent.action.BOOT_COMPLETED] and re-enables
 * services the user had active before reboot.
 *
 * Services restarted:
 *  1. NotificationIconService (if user had it enabled)
 *  2. FloatingBarService (if user had it enabled) — wrapped in try-catch
 *  3. DateTimeWidgetProvider (always — widget needs fresh time)
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        // 1. Restart notification icon if user had it enabled
        try {
            if (NotificationIconService.isEnabled(context)) {
                NotificationIconService.start(context)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart NotificationIconService", e)
        }

        // 2. Restart floating bar if user had it enabled
        // Wrapped in try-catch because foreground services from
        // BOOT_COMPLETED may be restricted on Android 15+ or OEM skins
        try {
            if (FloatingBarService.isEnabled(context)) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(
                        Intent(context, FloatingBarService::class.java)
                    )
                } else {
                    context.startService(
                        Intent(context, FloatingBarService::class.java)
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart FloatingBarService", e)
        }

        // 3. Force-update every widget instance
        try {
            DateTimeWidgetProvider.updateAllWidgets(context)
            DateTimeWidgetProvider.scheduleNextAlarm(context)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update widgets", e)
        }
    }
}
