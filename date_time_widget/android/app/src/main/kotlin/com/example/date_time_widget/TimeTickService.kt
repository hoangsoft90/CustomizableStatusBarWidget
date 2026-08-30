package com.example.date_time_widget

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground service that registers a dynamic BroadcastReceiver
 * for Intent.ACTION_TIME_TICK.
 *
 * #5: Replaces AlarmManager (DateTimeWidgetProvider) and
 * Handler.postDelayed (NotificationIconService) with a single
 * system-driven tick that updates all three services.
 *
 * Lifecycle:
 *   TimeTickService.start(context)  — from BootReceiver or app
 *   TimeTickService.stop(context)   — rarely needed (runs until killed)
 *
 * Registered dynamically (not in AndroidManifest) because API 26+
 * prohibits implicit broadcast receivers for ACTION_TIME_TICK.
 */
class TimeTickService : Service() {

    companion object {
        private const val TAG = "TimeTickService"
        private const val CHANNEL_ID = "time_tick_service"
        private const val CHANNEL_NAME = "Time Sync Service"
        private const val NOTIFICATION_ID = 9999

        fun start(context: Context) {
            val intent = Intent(context, TimeTickService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, TimeTickService::class.java))
        }
    }

    private var tickReceiver: BroadcastReceiver? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Start foreground with a low-priority notification
        startForeground(NOTIFICATION_ID, buildNotification())

        // Register dynamic broadcast receiver for ACTION_TIME_TICK
        registerTickReceiver()

        // Initial update — sync all services on service start
        DateTimeWidgetProvider.onTick(this)

        return START_STICKY
    }

    override fun onDestroy() {
        unregisterTickReceiver()
        super.onDestroy()
    }

    private fun registerTickReceiver() {
        if (tickReceiver != null) return

        tickReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == Intent.ACTION_TIME_TICK) {
                    Log.d(TAG, "TIME_TICK received — updating all services")
                    DateTimeWidgetProvider.onTick(context)
                }
            }
        }

        val filter = IntentFilter(Intent.ACTION_TIME_TICK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(tickReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(tickReceiver, filter)
        }
    }

    private fun unregisterTickReceiver() {
        tickReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) { }
        }
        tickReceiver = null
    }

    // ── Notification (foreground service requirement) ────────

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_MIN,
            ).apply {
                description = "Keeps time sync active for widgets, notification, and floating bar"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pi = PendingIntent.getActivity(
            this, NOTIFICATION_ID, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setContentTitle("Date & Time Widget")
            .setContentText("Keeping your widgets in sync")
            .setContentIntent(pi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
