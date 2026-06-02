package com.habitflow.habitflow

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

class HabitWidgetFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    data class HabitItem(val id: String, val icon: String, val name: String, val done: Boolean)

    private var habits: List<HabitItem> = emptyList()

    private fun loadHabits() {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val json  = prefs.getString("flutter.hf_habits_json", "[]") ?: "[]"
        val list  = mutableListOf<HabitItem>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val h = arr.getJSONObject(i)
                list += HabitItem(
                    id   = h.getString("id"),
                    icon = h.getString("icon"),
                    name = h.getString("name"),
                    done = h.getBoolean("done")
                )
            }
        } catch (_: Exception) {}
        habits = list
    }

    override fun onCreate()          { loadHabits() }
    override fun onDataSetChanged()  { loadHabits() }
    override fun onDestroy()         {}
    override fun getCount()          = habits.size
    override fun getViewTypeCount()  = 1
    override fun hasStableIds()      = true
    override fun getItemId(pos: Int) = pos.toLong()
    override fun getLoadingView()    = null

    override fun getViewAt(pos: Int): RemoteViews {
        val habit = habits.getOrNull(pos) ?: return RemoteViews(context.packageName, R.layout.habit_widget_item)
        val rv = RemoteViews(context.packageName, R.layout.habit_widget_item)

        if (habit.done) {
            rv.setTextViewText(R.id.item_emoji, "✓")
            rv.setTextColor(R.id.item_emoji, 0xFFFFFFFF.toInt())
            rv.setInt(R.id.item_circle, "setBackgroundResource", R.drawable.widget_circle_done)
        } else {
            rv.setTextViewText(R.id.item_emoji, habit.icon)
            rv.setTextColor(R.id.item_emoji, 0xDDFFFFFF.toInt())
            rv.setInt(R.id.item_circle, "setBackgroundResource", R.drawable.widget_circle_normal)
        }

        rv.setTextViewText(R.id.item_name, habit.name)

        // Fill-in intent for tap → ACTION_TOGGLE with the habit id
        val fillIn = Intent().putExtra(HabitWidget.EXTRA_HABIT_ID, habit.id)
        rv.setOnClickFillInIntent(R.id.item_circle, fillIn)

        return rv
    }
}
