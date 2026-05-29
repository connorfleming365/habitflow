import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime.isEmpty) return;
    final parts = habit.reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final min  = int.parse(parts[1]);

    await cancelHabitReminder(habit.id);

    // Use a stable int ID derived from habit id
    final notifId = habit.id.hashCode.abs() % 100000;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, min);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      notifId,
      '${habit.icon} Time for: ${habit.name}',
      'Tap to open HabitFlow and check in.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'habitflow_reminders',
          'Habit Reminders',
          channelDescription: 'Daily habit reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  static Future<void> cancelHabitReminder(String habitId) async {
    final notifId = habitId.hashCode.abs() % 100000;
    await _plugin.cancel(notifId);
  }

  static Future<void> scheduleAll(List<Habit> habits) async {
    await _plugin.cancelAll();
    for (final h in habits) {
      await scheduleHabitReminder(h);
    }
  }
}
