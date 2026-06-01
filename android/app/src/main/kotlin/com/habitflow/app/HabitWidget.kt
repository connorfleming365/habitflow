package com.habitflow.habitflow

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.app.PendingIntent
import org.json.JSONArray

class HabitWidget : AppWidgetProvider() {

    // ── Broadcast action & extras ─────────────────────────────
    companion object {
        const val ACTION_TOGGLE  = "com.habitflow.habitflow.TOGGLE_HABIT"
        const val EXTRA_HABIT_ID = "habit_id"
        const val MAX_ROWS       = 5

        // Parallel arrays indexed 0..4 matching the XML view IDs
        val ROW_IDS   = intArrayOf(R.id.habit_row_0,   R.id.habit_row_1,   R.id.habit_row_2,   R.id.habit_row_3,   R.id.habit_row_4)
        val ICON_IDS  = intArrayOf(R.id.habit_icon_0,  R.id.habit_icon_1,  R.id.habit_icon_2,  R.id.habit_icon_3,  R.id.habit_icon_4)
        val NAME_IDS  = intArrayOf(R.id.habit_name_0,  R.id.habit_name_1,  R.id.habit_name_2,  R.id.habit_name_3,  R.id.habit_name_4)
        val CHECK_IDS = intArrayOf(R.id.habit_check_0, R.id.habit_check_1, R.id.habit_check_2, R.id.habit_check_3, R.id.habit_check_4)

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val total      = prefs.getString("flutter.hf_total",      "0") ?: "0"
            val date       = prefs.getString("flutter.hf_date",       "Today") ?: "Today"
            val habitsJson = prefs.getString("flutter.hf_habits_json", "[]") ?: "[]"

            val views = RemoteViews(context.packageName, R.layout.habit_widget)

            // Tap header → open app
            val launchPending = PendingIntent.getActivity(
                context, 0,
                context.packageManager.getLaunchIntentForPackage(context.packageName),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_header, launchPending)

            views.setTextViewText(R.id.widget_date, date)

            // Parse habits
            try {
                val habits    = JSONArray(habitsJson)
                val count     = minOf(habits.length(), MAX_ROWS)
                var doneCount = 0

                for (i in 0 until MAX_ROWS) {
                    if (i < count) {
                        val habit   = habits.getJSONObject(i)
                        val habitId = habit.getString("id")
                        val icon    = habit.getString("icon")
                        val name    = habit.getString("name")
                        val done    = habit.getBoolean("done")
                        if (done) doneCount++

                        views.setViewVisibility(ROW_IDS[i], View.VISIBLE)
                        views.setTextViewText(ICON_IDS[i], icon)
                        views.setTextViewText(NAME_IDS[i], name)
                        views.setTextViewText(CHECK_IDS[i], if (done) "✓" else "○")
                        // Green tick when done, dim circle when not
                        views.setTextColor(
                            CHECK_IDS[i],
                            if (done) 0xFF4CAF50.toInt() else 0x55FFFFFF.toInt()
                        )
                        // Strike-through name when done
                        views.setTextColor(
                            NAME_IDS[i],
                            if (done) 0x88FFFFFF.toInt() else 0xDDFFFFFF.toInt()
                        )

                        // Each row tap → toggle that habit
                        val toggleIntent = Intent(context, HabitWidget::class.java).apply {
                            action = ACTION_TOGGLE
                            putExtra(EXTRA_HABIT_ID, habitId)
                        }
                        val togglePending = PendingIntent.getBroadcast(
                            context,
                            habitId.hashCode(),
                            toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(ROW_IDS[i], togglePending)

                    } else {
                        views.setViewVisibility(ROW_IDS[i], View.GONE)
                    }
                }

                // Header count
                val totalInt = count  // habits shown = scheduled today
                views.setTextViewText(R.id.widget_count, "$doneCount / $totalInt")

                // Progress bar
                val pct = if (totalInt > 0) (doneCount.toFloat() / totalInt * 100).toInt() else 0
                views.setProgressBar(R.id.widget_progress, 100, pct, false)

            } catch (e: Exception) {
                // Fallback: just show summary from flat keys
                val done = prefs.getString("flutter.hf_done", "0") ?: "0"
                views.setTextViewText(R.id.widget_count, "$done / $total")
                views.setProgressBar(R.id.widget_progress, 100, 0, false)
                for (i in 0 until MAX_ROWS) views.setViewVisibility(ROW_IDS[i], View.GONE)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }

        // ── Toggle a habit and refresh all widgets ────────────
        fun toggleHabit(context: Context, habitId: String) {
            val prefs      = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val habitsJson = prefs.getString("flutter.hf_habits_json", "[]") ?: "[]"
            val todayDate  = prefs.getString("flutter.hf_today_date", "") ?: ""

            try {
                val habits = JSONArray(habitsJson)

                // Toggle the done flag in the JSON
                for (i in 0 until habits.length()) {
                    val h = habits.getJSONObject(i)
                    if (h.getString("id") == habitId) {
                        h.put("done", !h.getBoolean("done"))
                        break
                    }
                }

                // Write updated JSON back
                prefs.edit().putString("flutter.hf_habits_json", habits.toString()).apply()

                // Also write to Flutter's completions StringSet so the app sees the change
                if (todayDate.isNotEmpty()) {
                    val completionKey = "${habitId}_${todayDate}"
                    val existing = prefs.getStringSet("flutter.hf_completions", mutableSetOf())
                        ?.toMutableSet() ?: mutableSetOf()
                    if (existing.contains(completionKey)) {
                        existing.remove(completionKey)
                    } else {
                        existing.add(completionKey)
                    }
                    prefs.edit().putStringSet("flutter.hf_completions", existing).apply()
                }

            } catch (e: Exception) { /* ignore parse errors */ }

            // Refresh all widgets
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, HabitWidget::class.java))
            for (id in ids) updateWidget(context, mgr, id)
        }
    }

    // ── AppWidgetProvider callbacks ───────────────────────────
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) updateWidget(context, appWidgetManager, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TOGGLE) {
            val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
            toggleHabit(context, habitId)
            return
        }
        super.onReceive(context, intent)
    }
}
