import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class StorageService {
  static const _habitsKey = 'hf_habits';
  static const _completionsKey = 'hf_completions';

  // ── Habits ──────────────────────────────────────────
  static Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_habitsKey) ?? '[]';
    return Habit.decode(raw);
  }

  static Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_habitsKey, Habit.encode(habits));
  }

  // ── Completions ─────────────────────────────────────
  // stored as Set<String> of 'habitId_YYYY-MM-DD'
  static Future<Set<String>> loadCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    // reload() flushes the in-memory cache so we always see writes made by the
    // Kotlin widget process (which shares the same SharedPreferences file).
    await prefs.reload();
    return Set<String>.from(prefs.getStringList(_completionsKey) ?? []);
  }

  static Future<void> saveCompletions(Set<String> completions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completionsKey, completions.toList());
  }

  static String completionKey(String habitId, DateTime date) =>
      '${habitId}_${_fmt(date)}';

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  static String todayKey(String habitId) => completionKey(habitId, DateTime.now());

  // ── Helpers ─────────────────────────────────────────
  static int getStreak(Habit habit, Set<String> completions) {
    int streak = 0;
    var d = DateTime.now();
    // Don't penalise if today not yet completed
    if (!completions.contains(completionKey(habit.id, d))) {
      d = d.subtract(const Duration(days: 1));
    }
    for (int i = 0; i < 365; i++) {
      if (habit.isScheduledOn(d)) {
        if (completions.contains(completionKey(habit.id, d))) {
          streak++;
        } else {
          break;
        }
      }
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int getLongestStreak(Habit habit, Set<String> completions) {
    int best = 0, cur = 0;
    var d = DateTime.now().subtract(const Duration(days: 1));
    for (int i = 0; i < 365; i++) {
      if (habit.isScheduledOn(d)) {
        if (completions.contains(completionKey(habit.id, d))) {
          cur++;
          if (cur > best) best = cur;
        } else {
          cur = 0;
        }
      }
      d = d.subtract(const Duration(days: 1));
    }
    return best;
  }

  // ── Install date ────────────────────────────────────
  static Future<String?> getInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('install_date');
  }

  static Future<void> setInstallDateIfNew() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('install_date') != null) return;
    final d = DateTime.now();
    await prefs.setString('install_date',
        '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
  }

  static ({int done, int total}) weekStats(
      List<Habit> habits, Set<String> completions) {
    int done = 0, total = 0;
    for (int i = 0; i < 7; i++) {
      final d = DateTime.now().subtract(Duration(days: i));
      for (final h in habits) {
        if (h.isScheduledOn(d)) {
          total++;
          if (completions.contains(completionKey(h.id, d))) done++;
        }
      }
    }
    return (done: done, total: total);
  }
}
