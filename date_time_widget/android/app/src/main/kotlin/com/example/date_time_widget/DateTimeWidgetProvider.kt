package com.example.date_time_widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Home-screen widget that displays day, date, and time.
 *
 * Config is read from FlutterSharedPreferences.xml — the same file
 * the Flutter shared_preferences plugin writes to.  Keys are prefixed
 * with "flutter." (e.g. "flutter.clock_config").
 *
 * Updates every 60 s via AlarmManager AND on-demand when Flutter
 * sends a MethodChannel call (see widget_bridge.dart).
 */
class DateTimeWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val CONFIG_KEY = "flutter.clock_config"
        private const val ACTION_TICK = "com.example.date_time_widget.TICK"

        /** Force-update every widget instance right now. */
        fun updateAllWidgets(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, DateTimeWidgetProvider::class.java))
            for (id in ids) {
                renderWidget(context, mgr, id)
            }
        }

        /** Schedule the next alarm (60 s from now). */
        fun scheduleNextAlarm(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, DateTimeWidgetProvider::class.java).apply {
                action = ACTION_TICK
            }
            val pi = PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val next = SystemClock.elapsedRealtime() + 60_000
            am.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, next, pi)
        }

        private fun renderWidget(
            context: Context,
            mgr: AppWidgetManager,
            widgetId: Int,
        ) {
            val config = readConfig(context)
            val layoutId = chooseLayout(context, widgetId, mgr)
            val views = RemoteViews(context.packageName, layoutId)

            val now = Calendar.getInstance()
            val display = formatDisplay(now, config)

            views.setTextViewText(R.id.widget_day, display.day)
            views.setTextViewText(R.id.widget_date, display.date)
            views.setTextViewText(R.id.widget_time, display.time)

            // Apply user color
            val color = parseColor(config.color)
            views.setTextColor(R.id.widget_day, color)
            views.setTextColor(R.id.widget_date, color and 0xDDFFFFFF.toInt())
            views.setTextColor(R.id.widget_time, color)

            // Apply font sizes (scaled proportionally per layout)
            val baseSize = config.fontSize.toFloat()
            views.setTextViewTextSize(R.id.widget_day, android.util.TypedValue.COMPLEX_UNIT_SP, baseSize * 0.45f)
            views.setTextViewTextSize(R.id.widget_date, android.util.TypedValue.COMPLEX_UNIT_SP, baseSize * 0.4f)
            views.setTextViewTextSize(R.id.widget_time, android.util.TypedValue.COMPLEX_UNIT_SP, baseSize)

            // Tap to open app → Editor screen
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.putExtra("open_editor", true)
                launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val pi = PendingIntent.getActivity(
                    context, widgetId, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_day, pi)
                views.setOnClickPendingIntent(R.id.widget_date, pi)
                views.setOnClickPendingIntent(R.id.widget_time, pi)
            }

            mgr.updateAppWidget(widgetId, views)
        }

        /** Pick layout based on widget cell size. */
        private fun chooseLayout(
            context: Context,
            widgetId: Int,
            mgr: AppWidgetManager,
        ): Int {
            val options = mgr.getAppWidgetOptions(widgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)

            return when {
                minWidth >= 300 && minHeight >= 170 -> R.layout.widget_4x2
                minWidth >= 300                    -> R.layout.widget_4x1
                minWidth >= 240                    -> R.layout.widget_3x1
                else                               -> R.layout.widget_2x1
            }
        }

        /** Read ClockConfig from FlutterSharedPreferences.xml */
        private fun readConfig(context: Context): ClockData {
            return try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val json = prefs.getString(CONFIG_KEY, null)
                if (json != null) parseClockData(json) else ClockData()
            } catch (_: Exception) {
                ClockData()
            }
        }

        /**
         * Minimal JSON parser for ClockConfig — avoids pulling in a JSON library
         * since the structure is small and predictable.
         */
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
                    .toLong(16).toInt()
            } catch (_: Exception) {
                0xFFFFFFFF.toInt()
            }
        }

        private fun formatDisplay(cal: Calendar, config: ClockData): DisplayData {
            val date = cal.time

            val timePattern = if (config.showSeconds) {
                config.timeFormat.replace("mm", "mm:ss")
            } else {
                config.timeFormat
            }
            val time = try {
                SimpleDateFormat(timePattern, Locale.getDefault()).format(date)
            } catch (_: Exception) {
                SimpleDateFormat("HH:mm", Locale.getDefault()).format(date)
            }

            val dayNames = arrayOf("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
            val dayShort = arrayOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
            val dayOfWeek = cal.get(Calendar.DAY_OF_WEEK) - 2 // 0=Monday
            val dayIdx = if (dayOfWeek < 0) 6 else dayOfWeek

            val day = if (config.showDay) {
                if (config.format.contains("EEE")) dayShort[dayIdx].uppercase(Locale.getDefault())
                else dayNames[dayIdx]
            } else ""

            val dateFormat = config.format
                .replace(Regex("E+"), "") // remove day-of-week tokens
                .replace(Regex("^\\s*,\\s*"), "") // remove leading comma
                .replace(Regex("\\s*,\\s*$"), "") // remove trailing comma
                .trim()

            val dateStr = if (config.showDate && dateFormat.isNotEmpty()) {
                try {
                    SimpleDateFormat(dateFormat, Locale.getDefault()).format(date)
                } catch (_: Exception) {
                    ""
                }
            } else ""

            return DisplayData(day = day, date = dateStr, time = time)
        }
    }

    // ── AppWidgetProvider overrides ─────────────────────────

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            renderWidget(context, appWidgetManager, id)
        }
        scheduleNextAlarm(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TICK) {
            updateAllWidgets(context)
            scheduleNextAlarm(context)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleNextAlarm(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, DateTimeWidgetProvider::class.java).apply {
            action = ACTION_TICK
        }
        val pi = PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        am.cancel(pi)
    }

    // ── Data classes ────────────────────────────────────────

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

    data class DisplayData(
        val day: String = "",
        val date: String = "",
        val time: String = "",
    )
}
