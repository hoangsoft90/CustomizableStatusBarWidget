package com.example.date_time_widget

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import androidx.core.graphics.drawable.IconCompat
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Manages a persistent status-bar notification that shows the current
 * day number (e.g. "30") as a small monochrome icon and the full
 * day / date / time in the expanded notification body.
 *
 * Config is read from "status_bar_config" SharedPreferences — written
 * by Flutter via MethodChannel JSON (see widget_bridge.dart).
 *
 * Usage:
 *   NotificationIconService.start(context)
 *   NotificationIconService.stop(context)
 *   NotificationIconService.isEnabled(context)
 *   NotificationIconService.saveConfig(context, json)
 */
object NotificationIconService {

    private const val CHANNEL_ID = "date_time_icon"
    private const val CHANNEL_NAME = "Date & Time Icon"
    private const val NOTIFICATION_ID = 7777
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val ENABLED_KEY = "flutter.notification_enabled"
    private const val TAG = "NotifIconService"

    // Config stored in our own SharedPreferences
    private const val CONFIG_PREFS = "status_bar_config"
    private const val CONFIG_KEY = "clock_config"

    // ── Public API ──────────────────────────────────────────

    fun start(context: Context) {
        createChannel(context)
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(context))
        saveEnabled(context, true)
    }

    fun stop(context: Context) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(NOTIFICATION_ID)
        saveEnabled(context, false)
    }

    fun update(context: Context) {
        if (!isEnabled(context)) return
        createChannel(context)
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(context))
    }

    /** Called by MainActivity when Flutter sends config JSON via MethodChannel. */
    fun saveConfig(context: Context, json: String) {
        context.getSharedPreferences(CONFIG_PREFS, Context.MODE_PRIVATE)
            .edit().putString(CONFIG_KEY, json).apply()
        update(context)
    }

    fun isEnabled(context: Context): Boolean {
        return getPrefs(context).getBoolean(ENABLED_KEY, false)
    }

    // ── Notification builder ────────────────────────────────

    private fun buildNotification(context: Context): Notification {
        val config = readConfig(context)
        val cal = Calendar.getInstance()
        val now = cal.time

        val dayOfMonth = cal.get(Calendar.DAY_OF_MONTH)
        val dayNumber = dayOfMonth.toString()

        // #7: Locale-aware day/month names using SimpleDateFormat
        val fullDatePattern = "EEEE, d MMMM yyyy"
        val fullDate = try {
            SimpleDateFormat(fullDatePattern, Locale.getDefault()).format(now)
        } catch (_: Exception) {
            // Fallback: manual build with locale display names
            val dayName = cal.getDisplayName(Calendar.DAY_OF_WEEK, Calendar.LONG, Locale.getDefault()) ?: ""
            val monthName = cal.getDisplayName(Calendar.MONTH, Calendar.LONG, Locale.getDefault()) ?: ""
            "$dayName, $dayOfMonth $monthName ${cal.get(Calendar.YEAR)}"
        }

        // #2: Use config.timeFormat + showSeconds
        val timePattern = if (config.showSeconds) {
            config.timeFormat.replace("mm", "mm:ss")
        } else {
            config.timeFormat
        }
        val time = try {
            SimpleDateFormat(timePattern, Locale.getDefault()).format(now)
        } catch (_: Exception) {
            SimpleDateFormat("HH:mm", Locale.getDefault()).format(now)
        }

        val iconColor = parseColor(config.color)

        // Small icon: bitmap with day number
        val smallIcon = createDayBitmap(dayNumber)

        // Tap to open app
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val contentIntent = PendingIntent.getActivity(
            context, NOTIFICATION_ID, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconCompat = IconCompat.createWithBitmap(smallIcon)

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(iconCompat)
            .setLargeIcon(createDayBitmap(dayNumber))
            .setContentTitle(fullDate)
            .setContentText(time)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("$fullDate\n$time")
                    .setBigContentTitle("Date & Time Widget")
            )
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setColor(iconColor)
            .build()
    }

    // ── Day-number bitmap icon ──────────────────────────────

    /**
     * Creates a monochrome bitmap with the day number text.
     * Size: 64×64 px (will be scaled by the system to ~24dp).
     */
    private fun createDayBitmap(text: String): Bitmap {
        val size = 64
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Padding: 6px each side to avoid Samsung/Xiaomi circular crop clipping
        val padding = 6

        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFFFFFFF.toInt()
            textAlign = Paint.Align.CENTER
            typeface = Typeface.DEFAULT_BOLD
            textSize = if (text.length <= 2) 38f else 30f
        }

        val x = size / 2f
        val y = size / 2f - (paint.descent() + paint.ascent()) / 2f
        canvas.drawText(text, x, y, paint)

        return bitmap
    }

    // ── Channel ─────────────────────────────────────────────

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Persistent date & time icon in status bar"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    // ── Config reader (#3: reads from status_bar_config) ────

    /** Convenience: read from our own SharedPreferences. */
    private fun readConfig(context: Context): ClockData {
        return try {
            val json = context.getSharedPreferences(CONFIG_PREFS, Context.MODE_PRIVATE)
                .getString(CONFIG_KEY, null)
            if (json != null) parseClockData(json) else ClockData()
        } catch (_: Exception) {
            ClockData()
        }
    }

    // #2: Full ClockData parse — matches DateTimeWidgetProvider.parseClockData()
    private fun parseClockData(json: String): ClockData {
        fun extract(key: String): String? {
            val pattern = "\"$key\"\\s*:\\s*\"([^\"]*?)\""
            val boolPattern = "\"$key\"\\s*:\\s*(true|false)"
            val numPattern = "\"$key\"\\s*:\\s*([\\d.]+)"

            Regex(pattern).find(json)?.let { return it.groupValues[1] }
            Regex(boolPattern).find(json)?.let { return it.groupValues[1] }
            Regex(numPattern).find(json)?.let { return it.groupValues[1] }
            return null
        }

        return ClockData(
            format = extract("format") ?: "EEE dd MMM",
            timeFormat = extract("timeFormat") ?: "HH:mm",
            showSeconds = extract("showSeconds") == "true",
            showDate = extract("showDate") != "false",
            showDay = extract("showDay") != "false",
            fontSize = (extract("fontSize")?.toDoubleOrNull() ?: 32.0),
            color = extract("color") ?: "#FFFFFF",
            alignment = extract("alignment") ?: "center",
        )
    }

    private fun parseColor(hex: String): Int {
        return try {
            val clean = hex.removePrefix("#")
            val argb = when (clean.length) {
                6 -> "FF$clean"
                8 -> clean
                else -> "FFFFFFFF"
            }
            argb.toLong(16).toInt()
        } catch (_: Exception) {
            0xFFFFFFFF.toInt()
        }
    }

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private fun saveEnabled(context: Context, value: Boolean) {
        getPrefs(context).edit().putBoolean(ENABLED_KEY, value).apply()
    }

    // #2: Full ClockData with all fields
    data class ClockData(
        val format: String = "EEE dd MMM",
        val timeFormat: String = "HH:mm",
        val showSeconds: Boolean = false,
        val showDate: Boolean = true,
        val showDay: Boolean = true,
        val fontSize: Double = 32.0,
        val color: String = "#FFFFFF",
        val alignment: String = "center",
    )
}
