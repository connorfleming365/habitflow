package com.habitflow.habitflow

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.habitflow.habitflow/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "forceWidgetUpdate") {
                    try {
                        val manager = AppWidgetManager.getInstance(this)
                        val ids = manager.getAppWidgetIds(
                            ComponentName(this, HabitWidget::class.java))
                        for (id in ids) HabitWidget.updateWidget(this, manager, id)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("WIDGET_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
