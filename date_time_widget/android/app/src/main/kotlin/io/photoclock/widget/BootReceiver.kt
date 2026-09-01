package io.photoclock.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Listens for [android.intent.action.BOOT_COMPLETED] and re-enables
 * services the user had active before reboot.
 *
 * #5: Starts TimeTickService (ACTION_TIME_TICK) instead of AlarmManager.
 * All services now read config from "status_bar_config" SharedPreferences.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        // 1. Start TimeTickService — handles all tick updates
        try {
            TimeTickService.start(context)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start TimeTickService", e)
        }

        // 2. Restart notification icon if user had it enabled
        try {
            if (NotificationIconService.isEnabled(context)) {
                NotificationIconService.start(context)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart NotificationIconService", e)
        }

        // 3. Restart floating bar if user had it enabled
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

        // 4. Force-update every widget instance
        try {
            DateTimeWidgetProvider.updateAllWidgets(context)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update widgets", e)
        }
    }
}
