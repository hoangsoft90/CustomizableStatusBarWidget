package io.photoclock.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.widget.RemoteViews
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Home-screen widget that displays day, date, and time.
 *
 * Config is read from "status_bar_config" SharedPreferences — written
 * by Flutter via MethodChannel JSON (see widget_bridge.dart).
 *
 * Updates via TimeTickService (ACTION_TIME_TICK) — no AlarmManager needed.
 */
class DateTimeWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val CONFIG_PREFS = "status_bar_config"
        private const val CONFIG_KEY = "clock_config"

        /** Force-update every widget instance right now. */
        fun updateAllWidgets(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, DateTimeWidgetProvider::class.java))
            for (id in ids) {
                renderWidget(context, mgr, id)
            }
        }

        /** Called by TimeTickService on ACTION_TIME_TICK — updates all widgets + notification + floating bar. */
        fun onTick(context: Context) {
            updateAllWidgets(context)
            NotificationIconService.update(context)
            FloatingBarService.updateOverlay(context)
        }

        /** Called by MainActivity when Flutter sends config JSON via MethodChannel. */
        fun saveConfig(context: Context, json: String) {
            context.getSharedPreferences(CONFIG_PREFS, Context.MODE_PRIVATE)
                .edit().putString(CONFIG_KEY, json).apply()
            updateAllWidgets(context)
            NotificationIconService.update(context)
            FloatingBarService.updateOverlay(context)
        }

        private const val BG_PREFS = "widget_background"
        private const val BG_PATH_KEY = "bg_bitmap_path"

        /** Save the baked bitmap path (shared across all widget instances). */
        fun saveWidgetBackground(context: Context, widgetId: Int, bitmapPath: String?) {
            val prefs = context.getSharedPreferences(BG_PREFS, Context.MODE_PRIVATE)
            if (bitmapPath != null) {
                prefs.edit().putString(BG_PATH_KEY, bitmapPath).apply()
            } else {
                prefs.edit().remove(BG_PATH_KEY).apply()
            }
            // Re-render this specific widget
            val mgr = AppWidgetManager.getInstance(context)
            renderWidget(context, mgr, widgetId)
        }

        private fun readBackgroundPath(context: Context): String? {
            return context.getSharedPreferences(BG_PREFS, Context.MODE_PRIVATE)
                .getString(BG_PATH_KEY, null)
        }

        private fun renderWidget(
            context: Context,
            mgr: AppWidgetManager,
            widgetId: Int,
        ) {
            // Plan9: outer guard — any failure while building/updating this widget
            // instance must not crash the widget host or abort the onUpdate loop.
            try {
                renderWidgetInner(context, mgr, widgetId)
            } catch (e: Exception) {
                Log.e("DateTimeWidget", "renderWidget failed id=$widgetId", e)
            }
        }

        private fun renderWidgetInner(
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

            // Apply background image if baked bitmap exists
            applyWidgetBackground(context, views, widgetId)

            // #4: Alignment — RemoteViews does not support layout gravity.
            // Alignment is applied on the Floating Bar (native View) and
            // in the Flutter ClockPreview. Widget layout uses CENTER by default.

            // Tap to open app → Editor screen
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.putExtra("open_editor", true)
                launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val pi = android.app.PendingIntent.getActivity(
                    context, widgetId, launchIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_day, pi)
                views.setOnClickPendingIntent(R.id.widget_date, pi)
                views.setOnClickPendingIntent(R.id.widget_time, pi)
            }

            // Plan9: never let a widget-host transaction failure kill the process.
            try {
                mgr.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                Log.e("DateTimeWidget", "updateAppWidget failed id=$widgetId", e)
            }
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

        /** Read ClockConfig from status_bar_config SharedPreferences */
        private fun readConfig(context: Context): ClockData {
            return try {
                val prefs = context.getSharedPreferences(CONFIG_PREFS, Context.MODE_PRIVATE)
                val json = prefs.getString(CONFIG_KEY, null)
                if (json != null) parseClockData(json) else ClockData()
            } catch (_: Exception) {
                ClockData()
            }
        }

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
                val hexStr: String = when (clean.length) {
                    6 -> "FF$clean"
                    8 -> clean
                    else -> "FFFFFFFF"
                }
                hexStr.toLong(16).toInt()
            } catch (_: Exception) {
                0xFFFFFFFF.toInt()
            }
        }

        private fun applyWidgetBackground(
            context: Context,
            views: RemoteViews,
            widgetId: Int,
        ) {
            val bgPath = readBackgroundPath(context)

            if (bgPath != null && File(bgPath).exists()) {
                try {
                    // Decode bitmap with inSampleSize to avoid OOM on large files
                    val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeFile(bgPath, opts)
                    val sampleSize = calculateInSampleSize(opts, 400, 400)
                    val decodeOpts = BitmapFactory.Options().apply { inSampleSize = sampleSize }
                    val bitmap = BitmapFactory.decodeFile(bgPath, decodeOpts)

                    if (bitmap != null) {
                        // Plan9: Binder budget — raw ARGB must stay well under ~1 MB.
                        // Scale down if longest edge > 400px, then enforce a hard
                        // cap of ~400 KB raw (width×height×4) so RemoteViews never
                        // trips TransactionTooLargeException on the widget host.
                        val maxSide = maxOf(bitmap.width, bitmap.height)
                        var bmp = if (maxSide > 400) {
                            val scale = 400f / maxSide
                            // Clamp to >= 1px — a 0-dimension Bitmap throws.
                            val scaled = Bitmap.createScaledBitmap(
                                bitmap,
                                (bitmap.width * scale).toInt().coerceAtLeast(1),
                                (bitmap.height * scale).toInt().coerceAtLeast(1),
                                true
                            )
                            // Always recycle the decoded bitmap if scaled is a new instance
                            if (scaled !== bitmap) bitmap.recycle()
                            scaled
                        } else {
                            bitmap
                        }

                        // Hard cap ~400 KB raw — scale down in 85% steps if needed.
                        while (bmp.width.toLong() * bmp.height * 4 > 400_000L) {
                            val nw = (bmp.width * 0.85f).toInt().coerceAtLeast(1)
                            val nh = (bmp.height * 0.85f).toInt().coerceAtLeast(1)
                            val next = Bitmap.createScaledBitmap(bmp, nw, nh, true)
                            if (next !== bmp) bmp.recycle()
                            bmp = next
                        }

                        views.setImageViewBitmap(R.id.widget_background, bmp)
                        views.setViewVisibility(R.id.widget_background, android.view.View.VISIBLE)
                        return
                    }
                } catch (e: Exception) {
                    Log.e("WidgetBg", "applyWidgetBackground failed", e)
                }
            }

            // No bitmap — hide ImageView, rely on default dark background
            views.setViewVisibility(R.id.widget_background, android.view.View.GONE)
        }

        private fun calculateInSampleSize(
            options: BitmapFactory.Options,
            reqWidth: Int,
            reqHeight: Int,
        ): Int {
            val height = options.outHeight
            val width = options.outWidth
            var inSampleSize = 1
            if (height > reqHeight || width > reqWidth) {
                val halfHeight = height / 2
                val halfWidth = width / 2
                while (halfHeight / inSampleSize >= reqHeight &&
                       halfWidth / inSampleSize >= reqWidth) {
                    inSampleSize *= 2
                }
            }
            return inSampleSize
        }

        private fun formatDisplay(cal: Calendar, config: ClockData): DisplayData {
            val date = cal.time

            val time = try {
                SimpleDateFormat(config.timeFormat, Locale.getDefault()).format(date)
            } catch (_: Exception) {
                SimpleDateFormat("HH:mm", Locale.getDefault()).format(date)
            }

            // #7: Locale-aware day names using SimpleDateFormat
            val dayOfWeek = cal.get(Calendar.DAY_OF_WEEK)
            val dayIdx = dayOfWeek - Calendar.MONDAY
            val dayIdxSafe = if (dayIdx < 0) 6 else dayIdx

            val dayNames = arrayOf("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
            val dayShort = arrayOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

            val day = if (config.showDay) {
                if (config.format.contains("EEE")) dayShort[dayIdxSafe].uppercase(Locale.getDefault())
                else {
                    // Use locale-aware display name
                    val localeDay = cal.getDisplayName(Calendar.DAY_OF_WEEK, Calendar.LONG, Locale.getDefault())
                    localeDay ?: dayNames[dayIdxSafe]
                }
            } else ""

            val dateFormat = config.format
                .replace(Regex("E+"), "")
                .replace(Regex("^\\s*,\\s*"), "")
                .replace(Regex("\\s*,\\s*$"), "")
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
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        // Re-render with current background intact — do NOT remove BG_PATH_KEY
        // because that would delete background for ALL widget instances.
        // Background bitmap is already baked at a size that centerCrop scales.
        renderWidget(context, appWidgetManager, widgetId)
    }

    // ── Data classes ────────────────────────────────────────

    data class ClockData(
        val format: String = "EEE dd MMM",
        val timeFormat: String = "HH:mm",
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
