import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'storage_service.dart';

/// Writes today's progress into SharedPreferences so the Android AppWidget
/// can read it, then forces an immediate widget redraw via MethodChannel.
class WidgetService {
  static const _channel = MethodChannel('com.habitflow.habitflow/widget');

  static Future<void> init() async {}

  static Future<void> update(List<Habit> habits, Set<String> completions) async {
    final today = DateTime.now();
    final scheduled = habits.where((h) => h.isScheduledOn(today)).toList();
    final doneCount = scheduled
        .where((h) => completions.contains(StorageService.completionKey(h.id, today)))
        .length;
    final total = scheduled.length;

    final countMap = await StorageService.loadCounts();
    final habitJson = scheduled.map((h) {
      final key = StorageService.completionKey(h.id, today);
      return {
        'id':          h.id,
        'icon':        h.icon,
        'name':        h.name,
        'done':        completions.contains(key),
        'targetCount': h.targetCount,
        'count':       countMap[key] ?? 0,
      };
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hf_done',        doneCount.toString());
    await prefs.setString('hf_total',       total.toString());
    await prefs.setString('hf_date',        _dayLabel(today));
    await prefs.setString('hf_habits_json', jsonEncode(habitJson));
    await prefs.setString('hf_today_date',  _dateKey(today));

    // Force the Android widget to redraw immediately
    if (!kIsWeb) {
      try {
        await _channel.invokeMethod('forceWidgetUpdate');
      } catch (_) {
        // Silently ignore – widget refreshes on its own update cycle otherwise
      }
    }
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
