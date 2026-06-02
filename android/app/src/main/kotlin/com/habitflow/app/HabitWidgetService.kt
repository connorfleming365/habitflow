package com.habitflow.habitflow

import android.content.Intent
import android.widget.RemoteViewsService

class HabitWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        HabitWidgetFactory(applicationContext, intent)
}
