import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'storage_service.dart';

/// Writes today's progress into Flutter's standard SharedPreferences so the
/// native Android AppWidget can read it without needing the home_widget package.
class WidgetService {
  static Future<void> init() async {
    // Nothing to initialise – we piggyback on shared_preferences.
  }

  static Future<void> update(List<Habit> habits, Set<String> completions) async {
    final today = DateTime.now();
    final scheduled = habits.where((h) => h.isScheduledOn(today)).toList();
    final done = scheduled
        .where((h) => completions.contains(StorageService.completionKey(h.id, today)))
        .length;
    final total = scheduled.length;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hf_done',  done.toString());
    await prefs.setString('hf_total', total.toString());
    await prefs.setString('hf_date',  _dayLabel(today));
  }

  static String _dayLabel(DateTime d) {
    const days   = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[d.weekday % 7]} ${months[d.month - 1]} ${d.day}';
  }
}
