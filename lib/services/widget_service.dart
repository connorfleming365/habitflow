import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../models/habit.dart';
import 'storage_service.dart';

class WidgetService {
  static const _appGroupId = 'com.habitflow.app';
  static const _widgetName = 'HabitWidget';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Call this after any habit completion toggle or data change
  static Future<void> update(List<Habit> habits, Set<String> completions) async {
    final today = DateTime.now();
    final scheduled = habits.where((h) => h.isScheduledOn(today)).toList();
    final done = scheduled
        .where((h) => completions.contains(StorageService.completionKey(h.id, today)))
        .length;
    final total = scheduled.length;

    // Build a compact summary for the widget
    final items = scheduled.take(5).map((h) {
      final isDone =
          completions.contains(StorageService.completionKey(h.id, today));
      return {'icon': h.icon, 'name': h.name, 'done': isDone};
    }).toList();

    await HomeWidget.saveWidgetData('hf_done', done.toString());
    await HomeWidget.saveWidgetData('hf_total', total.toString());
    await HomeWidget.saveWidgetData('hf_items', jsonEncode(items));
    await HomeWidget.saveWidgetData(
        'hf_date', _dayLabel(today));
    await HomeWidget.updateWidget(
      name: _widgetName,
      androidName: _widgetName,
    );
  }

  static String _dayLabel(DateTime d) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[d.weekday % 7]} ${months[d.month - 1]} ${d.day}';
  }
}
