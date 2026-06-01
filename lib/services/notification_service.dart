import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _nudgeId = 99999;

  static Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;
    tz.initializeTimeZones();
    // Set the local timezone so zonedSchedule fires at the correct local time.
    // Without this, tz.local defaults to UTC and reminders fire at the wrong hour.
    try {
      final String tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // Fallback: stay on UTC — better than crashing
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Returns true if permission was granted.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }

  static Future<bool> areEnabled() async {
    if (kIsWeb) return false;
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return result ?? false;
  }

  static Future<tz.TZDateTime> _nextOccurrence(int hour, int min) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, min);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> _scheduleAt(Habit habit, String time) async {
    if (kIsWeb) return;
    if (time.isEmpty) return;
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final min  = int.parse(parts[1]);

    await cancelHabitReminder(habit.id);
    final notifId = habit.id.hashCode.abs() % 100000;

    await _plugin.zonedSchedule(
      notifId,
      '${habit.icon} Time for: ${habit.name}',
      'Tap to open HabitFlow and check in.',
      await _nextOccurrence(hour, min),
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
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleHabitReminder(Habit habit) async {
    if (kIsWeb) return;
    await _scheduleAt(habit, habit.reminderTime);
  }

  static Future<void> cancelHabitReminder(String habitId) async {
    if (kIsWeb) return;
    final notifId = habitId.hashCode.abs() % 100000;
    await _plugin.cancel(notifId);
  }

  /// Schedule all habits. [globalTime] is used for habits with no specific time.
  static Future<void> scheduleAll(List<Habit> habits, {String globalTime = ''}) async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
    for (final h in habits) {
      final time = h.reminderTime.isNotEmpty ? h.reminderTime : globalTime;
      await _scheduleAt(h, time);
    }
    // Re-schedule nudge if it was enabled
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('nudge_enabled') ?? false) {
      final nudgeTime = prefs.getString('nudge_time') ?? '21:00';
      await scheduleNudge(nudgeTime);
    }
  }

  // ── Smart nudge ───────────────────────────────────────────

  /// Schedule a daily evening nudge at [time] (HH:MM).
  static Future<void> scheduleNudge(String time) async {
    if (kIsWeb) return;
    if (time.isEmpty) return;
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final min  = int.parse(parts[1]);

    await _plugin.cancel(_nudgeId);

    await _plugin.zonedSchedule(
      _nudgeId,
      "🌊 Don't break your flow",
      "Your habits are waiting. Keep your streak alive!",
      await _nextOccurrence(hour, min),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habitflow_nudge',
          'Evening Nudge',
          channelDescription: 'Gentle reminder if habits not completed',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Call when all habits are done — cancel today's nudge and reschedule for tomorrow.
  static Future<void> cancelNudgeToday() async {
    if (kIsWeb) return;
    await _plugin.cancel(_nudgeId);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('nudge_enabled') ?? false) {
      final nudgeTime = prefs.getString('nudge_time') ?? '21:00';
      await scheduleNudge(nudgeTime);
    }
  }
}
