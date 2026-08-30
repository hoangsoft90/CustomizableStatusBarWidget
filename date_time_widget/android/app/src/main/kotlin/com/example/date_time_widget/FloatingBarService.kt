package com.example.date_time_widget

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.Calendar
import java.util.Locale

/**
 * Foreground service that draws a transparent floating bar immediately
 * below the real status bar.
 *
 * Config is read from "status_bar_config" SharedPreferences — written
 * by Flutter via MethodChannel JSON (see floating_bar_bridge.dart).
 *
 * Key constraints (plan1_final.md §0, §5):
 *  - Uses TYPE_APPLICATION_OVERLAY — does NOT draw on top of System UI.
 *  - The bar sits RIGHT BELOW the status bar (offset = statusBarHeight).
 *  - Transparent background, no input focus, does not block swipe-down.
 *
 * #8: update() calls updateOverlay() in-place — no stop/start cycle.
 */
class FloatingBarService : Service() {

    companion object {
        private const val CHANNEL_ID = "floating_bar"
        private const val CHANNEL_NAME = "Floating Bar"
        private const val NOTIFICATION_ID = 8888
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val ENABLED_KEY = "flutter.floatingBarEnabled"

        // #3: Config stored in our own SharedPreferences
        private const val CONFIG_PREFS = "status_bar_config"
        private const val CONFIG_KEY = "clock_config"

        fun start(context: Context) {
            saveEnabled(context, true)
            val intent = Intent(context, FloatingBarService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            saveEnabled(context, false)
            context.stopService(Intent(context, FloatingBarService::class.java))
        }

        /** #8: Update in-place — no stop/start cycle. */
        fun update(context: Context) {
            if (!isEnabled(context)) return
            sendUpdateIntent(context)
        }

        /** Called by TimeTickService — update overlay in-place. */
        fun updateOverlay(context: Context) {
            if (!isEnabled(context)) return
            try {
                sendUpdateIntent(context)
            } catch (_: Exception) { }
        }

        private fun sendUpdateIntent(context: Context) {
            val intent = Intent(context, FloatingBarService::class.java).apply {
                action = "UPDATE_OVERLAY"
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
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

        private fun getPrefs(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }

        private fun saveEnabled(context: Context, value: Boolean) {
            getPrefs(context).edit().putBoolean(ENABLED_KEY, value).apply()
        }
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    // ── Service lifecycle ────────────────────────────────────

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // #8: Handle UPDATE_OVERLAY action — update in-place, don't recreate
        if (intent?.action == "UPDATE_OVERLAY") {
            updateOverlay()
            return START_STICKY
        }

        // Start foreground FIRST (required for Android 14+)
        startForeground(NOTIFICATION_ID, buildNotification())

        // Add overlay if not already present
        if (overlayView == null) {
            addOverlay()
        }

        return START_STICKY
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }

    // ── Overlay management ──────────────────────────────────

    private fun addOverlay() {
        if (overlayView != null) return

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val params = createLayoutParams()

        overlayView = createBarView()

        try {
            windowManager?.addView(overlayView, params)
        } catch (e: Exception) {
            stopSelf()
        }
    }

    private fun removeOverlay() {
        overlayView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (_: Exception) { }
        }
        overlayView = null
    }

    private fun createLayoutParams(): WindowManager.LayoutParams {
        val resourceId = resources.getIdentifier("status_bar_height", "dimen", "android")
        val statusBarHeight = if (resourceId > 0) {
            resources.getDimensionPixelSize(resourceId)
        } else {
            24
        }

        val barHeight = (32 * resources.displayMetrics.density).toInt()

        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            barHeight,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = statusBarHeight
        }
    }

    private fun createBarView(): View {
        val config = readConfig()

        val textColor = parseColor(config.color)
        val bgAlpha = 0xCC

        val r = (textColor shr 16) and 0xFF
        val g = (textColor shr 8) and 0xFF
        val b = textColor and 0xFF
        val luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        val bgColor = if (luminance > 0.5) {
            Color.argb(bgAlpha, 0, 0, 0)
        } else {
            Color.argb(bgAlpha, 20, 20, 20)
        }

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(4), dp(12), dp(4))
            setBackgroundColor(bgColor)
        }

        val dayText = TextView(this).apply {
            setTextColor(textColor)
            textSize = config.fontSize.toFloat() * 0.35f
            setSingleLine(true)
            id = View.generateViewId()
        }

        val dateText = TextView(this).apply {
            setTextColor(textColor and 0xDDFFFFFF.toInt())
            textSize = config.fontSize.toFloat() * 0.3f
            setSingleLine(true)
            setPadding(dp(8), 0, 0, 0)
            id = View.generateViewId()
        }

        val spacer = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, 1, 1f)
        }

        val timeText = TextView(this).apply {
            setTextColor(textColor)
            textSize = config.fontSize.toFloat() * 0.4f
            setSingleLine(true)
            setPadding(dp(8), 0, 0, 0)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            id = View.generateViewId()
        }

        layout.addView(dayText)
        layout.addView(dateText)
        layout.addView(spacer)
        layout.addView(timeText)

        // #4: Apply alignment to the layout
        val layoutGravity = when (config.alignment) {
            "left" -> Gravity.START or Gravity.CENTER_VERTICAL
            "right" -> Gravity.END or Gravity.CENTER_VERTICAL
            else -> Gravity.CENTER or Gravity.CENTER_VERTICAL
        }
        layout.gravity = layoutGravity

        layout.tag = Triple(dayText, dateText, timeText)

        updateBarContent(layout)

        return layout
    }

    @Suppress("UNCHECKED_CAST")
    private fun updateOverlay() {
        val view = overlayView as? LinearLayout ?: return
        updateBarContent(view)
    }

    @Suppress("UNCHECKED_CAST")
    private fun updateBarContent(layout: LinearLayout) {
        val (dayText, dateText, timeText) = layout.tag as? Triple<TextView, TextView, TextView>
            ?: return

        val cal = Calendar.getInstance()
        val now = cal.time
        val config = readConfig()

        // #1: Safe day-of-week index (same guard as DateTimeWidgetProvider)
        val dayOfWeek = cal.get(Calendar.DAY_OF_WEEK)
        val dayIdx = dayOfWeek - Calendar.MONDAY
        val dayIdxSafe = if (dayIdx < 0) 6 else dayIdx

        // #7: Locale-aware day names
        val dayNames = arrayOf("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
        val dayShort = arrayOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

        val day = if (config.showDay) {
            if (config.format.contains("EEE")) dayShort[dayIdxSafe].uppercase(Locale.getDefault())
            else {
                val localeDay = cal.getDisplayName(Calendar.DAY_OF_WEEK, Calendar.LONG, Locale.getDefault())
                localeDay ?: dayNames[dayIdxSafe]
            }
        } else ""

        // Date
        val monthNames = arrayOf(
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        )
        val monthShort = arrayOf(
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        )
        val month = cal.get(Calendar.MONTH)
        val dayOfMonth = cal.get(Calendar.DAY_OF_MONTH)
        val year = cal.get(Calendar.YEAR)

        val date = if (config.showDate) {
            when {
                config.format.contains("dd/MM") -> "${pad(dayOfMonth)}/${pad(month + 1)}/$year"
                config.format.contains("MM/dd") -> "${pad(month + 1)}/${pad(dayOfMonth)}/$year"
                config.format.contains("yyyy-MM") -> "$year-${pad(month + 1)}-${pad(dayOfMonth)}"
                config.format.contains("MMMM") -> {
                    val localeMonth = cal.getDisplayName(Calendar.MONTH, Calendar.LONG, Locale.getDefault())
                    "${localeMonth ?: monthNames[month]} $dayOfMonth"
                }
                config.format.contains("MMM") -> {
                    val localeMonth = cal.getDisplayName(Calendar.MONTH, java.text.DateFormat.SHORT, Locale.getDefault())
                    "${localeMonth ?: monthShort[month]} $dayOfMonth"
                }
                else -> {
                    val localeMonth = cal.getDisplayName(Calendar.MONTH, java.text.DateFormat.SHORT, Locale.getDefault())
                    "${pad(dayOfMonth)} ${localeMonth ?: monthShort[month]}"
                }
            }
        } else ""

        // Time — use config.timeFormat + showSeconds
        val timePattern = if (config.showSeconds) {
            config.timeFormat.replace("mm", "mm:ss")
        } else {
            config.timeFormat
        }
        val time = try {
            java.text.SimpleDateFormat(timePattern, Locale.getDefault()).format(now)
        } catch (_: Exception) {
            // Fallback: manual build
            val h24 = cal.get(Calendar.HOUR_OF_DAY)
            val h12 = if (h24 == 0) 12 else if (h24 > 12) h24 - 12 else h24
            val mm = pad(cal.get(Calendar.MINUTE))
            if (config.timeFormat.contains("hh")) {
                val period = if (h24 >= 12) "PM" else "AM"
                if (config.showSeconds) "${pad(h12)}:$mm:${pad(cal.get(Calendar.SECOND))} $period"
                else "${pad(h12)}:$mm $period"
            } else {
                if (config.showSeconds) "${pad(h24)}:$mm:${pad(cal.get(Calendar.SECOND))}"
                else "${pad(h24)}:$mm"
            }
        }

        dayText.text = day
        dateText.text = date
        timeText.text = time

        // #4: Update alignment from config (reads config once, applies here)
        val layoutGravity = when (config.alignment) {
            "left" -> Gravity.START or Gravity.CENTER_VERTICAL
            "right" -> Gravity.END or Gravity.CENTER_VERTICAL
            else -> Gravity.CENTER or Gravity.CENTER_VERTICAL
        }
        layout.gravity = layoutGravity
    }

    private fun pad(n: Int) = n.toString().padStart(2, '0')
    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    // ── Config reader (#3: reads from status_bar_config) ────

    private fun readConfig(): ClockData {
        return try {
            val json = getPrefs(this).getString(CONFIG_KEY, null)
            if (json != null) parseClockData(json) else ClockData()
        } catch (_: Exception) {
            ClockData()
        }
    }

    // #4: parseClockData now includes alignment
    private fun parseClockData(json: String): ClockData {
        fun extract(key: String): String? {
            val pattern = "\"$key\"\\s*:\\s*\"([^\"]*?)\""
            Regex(pattern).find(json)?.let { return it.groupValues[1] }
            val boolPattern = "\"$key\"\\s*:\\s*(true|false)"
            Regex(boolPattern).find(json)?.let { return it.groupValues[1] }
            val numPattern = "\"$key\"\\s*:\\s*([\\d.]+)"
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

    // ── Notification (foreground service requirement) ────────

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Keeps the floating date/time bar alive"
                setShowBadge(false)
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
            .setContentTitle("Date & Time Floating Bar")
            .setContentText("Active — displaying below status bar")
            .setContentIntent(pi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    // ── Data ────────────────────────────────────────────────

    data class ClockData(
        val format: String = "EEE dd MMM",
        val timeFormat: String = "HH:mm",
        val showSeconds: Boolean = false,
        val showDate: Boolean = true,
        val showDay: Boolean = true,
        val fontSize: Double = 32.0,
        val color: String = "#FFFFFF",
        val alignment: String = "center",  // #4: alignment field added
    )
}
