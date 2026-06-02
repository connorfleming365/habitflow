package com.habitflow.habitflow

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.app.PendingIntent
import org.json.JSONArray

class HabitWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE  = "com.habitflow.habitflow.TOGGLE_HABIT"
        const val EXTRA_HABIT_ID = "habit_id"

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            val prefs      = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val total      = prefs.getString("flutter.hf_total", "0") ?: "0"
            val date       = prefs.getString("flutter.hf_date", "Today") ?: "Today"
            val habitsJson = prefs.getString("flutter.hf_habits_json", "[]") ?: "[]"

            val views = RemoteViews(context.packageName, R.layout.habit_widget)

            // Header tap → open app
            val launchPending = PendingIntent.getActivity(
                context, 0,
                context.packageManager.getLaunchIntentForPackage(context.packageName),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_header, launchPending)
            views.setTextViewText(R.id.widget_date, date)

            // Count done for header
            var doneCount = 0
            var totalCount = 0
            try {
                val habits = JSONArray(habitsJson)
                totalCount = habits.length()
                for (i in 0 until habits.length()) {
                    if (habits.getJSONObject(i).getBoolean("done")) doneCount++
                }
            } catch (_: Exception) {}

            views.setTextViewText(R.id.widget_count, "$doneCount / $totalCount")
            val pct = if (totalCount > 0) (doneCount.toFloat() / totalCount * 100).toInt() else 0
            views.setProgressBar(R.id.widget_progress, 100, pct, false)

            // Set up the RemoteViewsService for the GridView
            val serviceIntent = Intent(context, HabitWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                // Unique URI so each widget instance gets its own adapter
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.habit_grid, serviceIntent)
            views.setEmptyView(R.id.habit_grid, R.id.widget_date)

            // Pending intent template — each item fill-in provides EXTRA_HABIT_ID
            val toggleFlags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S)
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            else
                PendingIntent.FLAG_UPDATE_CURRENT

            val toggleTemplate = PendingIntent.getBroadcast(
                context, widgetId,
                Intent(context, HabitWidget::class.java).apply { action = ACTION_TOGGLE },
                toggleFlags
            )
            views.setPendingIntentTemplate(R.id.habit_grid, toggleTemplate)

            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.habit_grid)
        }

        fun toggleHabit(context: Context, habitId: String) {
            val prefs      = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val habitsJson = prefs.getString("flutter.hf_habits_json", "[]") ?: "[]"

            try {
                val habits = JSONArray(habitsJson)
                for (i in 0 until habits.length()) {
                    val h = habits.getJSONObject(i)
                    if (h.getString("id") == habitId) {
                        h.put("done", !h.getBoolean("done"))
                        break
                    }
                }
                prefs.edit().putString("flutter.hf_habits_json", habits.toString()).apply()
            } catch (_: Exception) {}

            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, HabitWidget::class.java))
            for (id in ids) updateWidget(context, mgr, id)
        }
    }

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
