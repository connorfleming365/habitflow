import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Habit> _habits = [];
  Set<String> _completions = {};
  int _calYear = DateTime.now().year;
  int _calMonth = DateTime.now().month - 1; // 0-indexed

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final habits = await StorageService.loadHabits();
    final comp = await StorageService.loadCompletions();
    if (mounted) setState(() { _habits = habits; _completions = comp; });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayHabits = _habits.where((h) => h.isScheduledOn(now)).toList();
    final todayDone = todayHabits.where((h) =>
        _completions.contains(StorageService.completionKey(h.id, now))).length;
    final week = StorageService.weekStats(_habits, _completions);
    final streaks = _habits.map((h) => StorageService.getStreak(h, _completions));
    final maxStreak = streaks.isEmpty ? 0 : streaks.reduce((a,b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            // ── Stats row ────────────────────────────
            Row(children: [
              _StatCard(val: '$todayDone/${todayHabits.length}', label: 'Today'),
              const SizedBox(width: 10),
              _StatCard(val: '${week.done}', label: 'This Week'),
              const SizedBox(width: 10),
              _StatCard(val: '$maxStreak 🔥', label: 'Best Streak'),
            ]),
            const SizedBox(height: 20),

            // ── Calendar ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(context),
              child: Column(children: [
                Row(children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {
                    setState(() { _calMonth--; if(_calMonth<0){_calMonth=11;_calYear--;} });
                  }),
                  Expanded(child: Text(_monthLabel, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {
                    setState(() { _calMonth++; if(_calMonth>11){_calMonth=0;_calYear++;} });
                  }),
                ]),
                const SizedBox(height: 8),
                _CalendarGrid(
                  year: _calYear, month: _calMonth,
                  habits: _habits, completions: _completions,
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Streaks ───────────────────────────────
            if (_habits.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('🔥 STREAKS', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ),
              Container(
                decoration: cardDecoration(context),
                child: Column(
                  children: _habits
                      .map((h) => StorageService.getStreak(h, _completions))
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => _StreakRow(
                        habit: _habits[e.key],
                        streak: e.value,
                        best: StorageService.getLongestStreak(_habits[e.key], _completions),
                        maxStreak: maxStreak == 0 ? 1 : maxStreak,
                      ))
                      .toList()
                      ..sort((a, b) => b.streak.compareTo(a.streak)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _monthLabel {
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    return '${months[_calMonth]} $_calYear';
  }
}

// ── Stat card ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String val, label;
  const _StatCard({required this.val, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(context),
      child: Column(children: [
        Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ]),
    ),
  );
}

// ── Calendar grid ─────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final int year, month;
  final List<Habit> habits;
  final Set<String> completions;
  const _CalendarGrid({required this.year, required this.month,
    required this.habits, required this.completions});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month + 1, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 2, 0).day;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';

    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1,
      ),
      itemCount: firstDay + daysInMonth,
      itemBuilder: (_, idx) {
        if (idx < firstDay) return const SizedBox();
        final day = idx - firstDay + 1;
        final ds = '$year-${(month+1).toString().padLeft(2,'0')}-${day.toString().padLeft(2,'0')}';
        final date = DateTime(year, month + 1, day);
        final isFuture = ds > todayStr;
        final isToday = ds == todayStr;
        final scheduled = habits.where((h) => h.isScheduledOn(date)).toList();
        final done = scheduled.where((h) =>
            completions.contains(StorageService.completionKey(h.id, date))).length;
        final isPerfect = scheduled.isNotEmpty && done == scheduled.length && !isFuture;
        final hasData = done > 0 && !isFuture;

        return Container(
          decoration: BoxDecoration(
            color: isPerfect ? kPrimary
                : hasData ? kPrimary.withOpacity(0.15)
                : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(color: kPrimary, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text('$day',
            style: TextStyle(
              fontSize: 12, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isPerfect ? Colors.white
                  : isToday ? kPrimary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            )),
        );
      },
    );
  }
}

// ── Streak row ────────────────────────────────────────────
class _StreakRow extends StatelessWidget {
  final Habit habit;
  final int streak, best, maxStreak;
  const _StreakRow({required this.habit, required this.streak,
    required this.best, required this.maxStreak});
  @override
  Widget build(BuildContext context) {
    final color = hexColor(habit.color);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(habit.icon, style: const TextStyle(fontSize: 18))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(habit.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: streak / maxStreak,
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation(kPrimary),
            ),
          ),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$streak 🔥',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimary)),
          Text('best $best',
            style: TextStyle(fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
        ]),
      ]),
    );
  }
}

extension on _StatsScreenState {
  List<_StreakRow> get _sortedStreakRows => [];
}
