import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'storage_service.dart';

/// Writes today's progress into SharedPreferences so the Android AppWidget
/// can read it and render interactive habit rows.
class WidgetService {
  static Future<void> init() async {}

  static Future<void> update(List<Habit> habits, Set<String> completions) async {
    final today = DateTime.now();
    final scheduled = habits.where((h) => h.isScheduledOn(today)).toList();
    final doneCount = scheduled
        .where((h) => completions.contains(StorageService.completionKey(h.id, today)))
        .length;
    final total = scheduled.length;

    // Build per-habit JSON list that the Kotlin widget renders as interactive rows
    final habitJson = scheduled.map((h) => {
      'id':   h.id,
      'icon': h.icon,
      'name': h.name,
      'done': completions.contains(StorageService.completionKey(h.id, today)),
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hf_done',       doneCount.toString());
    await prefs.setString('hf_total',      total.toString());
    await prefs.setString('hf_date',       _dayLabel(today));
    await prefs.setString('hf_habits_json', jsonEncode(habitJson));
    // Store today's date key so Kotlin can build the right completion key
    await prefs.setString('hf_today_date', _dateKey(today));
  }

  static String _dayLabel(DateTime d) {
    const days   = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[d.weekday % 7]} ${months[d.month - 1]} ${d.day}';
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
