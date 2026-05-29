package com.habitflow.habitflow

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent

class HabitWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            // Flutter's shared_preferences stores values in "FlutterSharedPreferences"
            // with every key prefixed by "flutter."
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )

            val done  = prefs.getString("flutter.hf_done",  "0") ?: "0"
            val total = prefs.getString("flutter.hf_total", "0") ?: "0"
            val date  = prefs.getString("flutter.hf_date",  "Today") ?: "Today"

            val views = RemoteViews(context.packageName, R.layout.habit_widget)

            // Counts
            views.setTextViewText(R.id.widget_count, "$done / $total")
            views.setTextViewText(R.id.widget_date, date)

            // Progress bar (0–100)
            val pct = if ((total.toIntOrNull() ?: 0) > 0)
                ((done.toFloat() / total.toFloat()) * 100).toInt() else 0
            views.setProgressBar(R.id.widget_progress, 100, pct, false)

            // Sub-label
            val sub = when {
                total == "0" -> "No habits today"
                done == total -> "All done! 🎉"
                else -> "${(total.toInt() - done.toInt())} left"
            }
            views.setTextViewText(R.id.widget_sub, sub)

            // Tap opens the app
            val intent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            val pending = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
