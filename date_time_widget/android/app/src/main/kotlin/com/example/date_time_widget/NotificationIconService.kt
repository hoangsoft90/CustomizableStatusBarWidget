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
import android.os.Handler
import android.os.Looper
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
 * Design notes (plan1_final.md §1 "Giới hạn của notification icon"):
 *  - The small status-bar icon is monochrome, ~24dp.  We generate a
 *    bitmap with the day number text rendered on it.  This works on
 *    most OEMs but may be cropped on some (Samsung tends to clip).
 *  - The full text ("Sunday, 30 August 2026  ·  08:35") is in the
 *    notification content — always visible when the shade is pulled.
 *
 * Usage:
 *   NotificationIconService.start(context)
 *   NotificationIconService.stop(context)
 *   NotificationIconService.isEnabled(context)
 */
object NotificationIconService {

    private const val CHANNEL_ID = "date_time_icon"
    private const val CHANNEL_NAME = "Date & Time Icon"
    private const val NOTIFICATION_ID = 7777
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val ENABLED_KEY = "flutter.notification_enabled"
    private const val UPDATE_INTERVAL_MS = 60_000L // 1 minute

    private val handler = Handler(Looper.getMainLooper())
    private var appContext: Context? = null
    private val updateRunnable = object : Runnable {
        override fun run() {
            appContext?.let { ctx ->
                if (isEnabled(ctx)) {
                    val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    nm.notify(NOTIFICATION_ID, buildNotification(ctx))
                }
            }
            handler.postDelayed(this, UPDATE_INTERVAL_MS)
        }
    }

    // ── Public API ──────────────────────────────────────────

    fun start(context: Context) {
        appContext = context.applicationContext
        createChannel(context)
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(context))
        saveEnabled(context, true)
        // Start periodic auto-update
        handler.removeCallbacks(updateRunnable)
        handler.postDelayed(updateRunnable, UPDATE_INTERVAL_MS)
    }

    fun stop(context: Context) {
        handler.removeCallbacks(updateRunnable)
        appContext = null
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

    fun isEnabled(context: Context): Boolean {
        return getPrefs(context).getBoolean(ENABLED_KEY, false)
    }

    // ── Notification builder ────────────────────────────────

    private fun buildNotification(context: Context): Notification {
        val cal = Calendar.getInstance()
        val now = cal.time

        val dayOfMonth = cal.get(Calendar.DAY_OF_MONTH)
        val dayNumber = dayOfMonth.toString()

        // Full text for expanded view
        val dayNames = arrayOf(
            "Monday", "Tuesday", "Wednesday", "Thursday",
            "Friday", "Saturday", "Sunday"
        )
        val monthNames = arrayOf(
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        )
        val dayOfWeek = cal.get(Calendar.DAY_OF_WEEK)
        val dayName = dayNames[dayOfWeek - Calendar.MONDAY]
        val monthName = monthNames[cal.get(Calendar.MONTH)]
        val year = cal.get(Calendar.YEAR)

        val fullDate = "$dayName, $dayOfMonth $monthName $year"
        val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(now)

        // Read config for custom color
        val config = readConfig(context)
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
            .setLargeIcon(createDayBitmap(dayNumber)) // same for large icon
            .setContentTitle(fullDate)
            .setContentText(time)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("$fullDate\n$time")
                    .setBigContentTitle("Date & Time Widget")
            )
            .setContentIntent(contentIntent)
            .setOngoing(true) // persistent, can't swipe away
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
                NotificationManager.IMPORTANCE_LOW, // no sound, no badge
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

    // ── Config reader (same as DateTimeWidgetProvider) ──────

    private fun readConfig(context: Context): ClockData {
        return try {
            val prefs = getPrefs(context)
            val json = prefs.getString("flutter.clock_config", null)
            if (json != null) parseClockData(json) else ClockData()
        } catch (_: Exception) {
            ClockData()
        }
    }

    private fun parseClockData(json: String): ClockData {
        fun extract(key: String): String? {
            val pattern = "\"$key\"\\s*:\\s*\"([^\"]*?)\""
            Regex(pattern).find(json)?.let { return it.groupValues[1] }
            val numPattern = "\"$key\"\\s*:\\s*([\\d.]+)"
            Regex(numPattern).find(json)?.let { return it.groupValues[1] }
            return null
        }
        return ClockData(
            color = extract("color") ?: "#FFFFFF",
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

    data class ClockData(val color: String = "#FFFFFF")
}
