import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import 'add_habit_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<Habit> _habits = [];
  Set<String> _completions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await StorageService.loadHabits();
    final completions = await StorageService.loadCompletions();
    if (mounted) setState(() { _habits = habits; _completions = completions; _loading = false; });
  }

  Future<void> _toggle(Habit habit) async {
    HapticFeedback.lightImpact();
    final key = StorageService.todayKey(habit.id);
    final newSet = Set<String>.from(_completions);
    if (newSet.contains(key)) { newSet.remove(key); }
    else { newSet.add(key); HapticFeedback.mediumImpact(); }
    await StorageService.saveCompletions(newSet);
    await WidgetService.update(_habits, newSet);
    if (mounted) setState(() => _completions = newSet);
  }

  List<Habit> get _todayHabits =>
      _habits.where((h) => h.isScheduledOn(DateTime.now())).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final today = _todayHabits;
    final remaining = today.where((h) => !_completions.contains(StorageService.todayKey(h.id))).toList();
    final done = today.where((h) => _completions.contains(StorageService.todayKey(h.id))).toList();
    final pct = today.isEmpty ? 0.0 : done.length / today.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitFlow 🌊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddHabitScreen()));
              _load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // ── Hero progress card ──────────────────────
            _HeroCard(pct: pct, done: done.length, total: today.length),
            const SizedBox(height: 20),

            if (today.isEmpty) ...[
              _EmptyState(
                onAdd: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddHabitScreen()));
                  _load();
                },
              ),
            ] else ...[
              // Remaining
              if (remaining.isNotEmpty) ...[
                _sectionLabel("TODAY'S HABITS"),
                ...remaining.asMap().entries.map((e) => _HabitCard(
                  habit: e.value,
                  done: false,
                  delay: e.key * 50,
                  onTap: () => _toggle(e.value),
                )),
              ],

              // Done section
              if (done.isNotEmpty) ...[
                _sectionLabel('COMPLETED ✓'),
                ...done.map((h) => _HabitCard(
                  habit: h,
                  done: true,
                  delay: 0,
                  onTap: () => _toggle(h),
                )),
              ],

              if (remaining.isEmpty)
                _AllDoneCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
    child: Text(text,
      style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    ),
  );
}

// ── Hero card ─────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double pct;
  final int done, total;
  const _HeroCard({required this.pct, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning! 🌅'
        : hour < 17 ? 'Keep going! ☀️' : 'Evening check-in 🌙';
    final days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C6AF7), Color(0xFFA78BFA)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: const Color(0xFF7C6AF7).withOpacity(0.35),
          blurRadius: 20, offset: const Offset(0, 8),
        )],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(greeting, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  total == 0 ? 'Add your first habit below'
                      : done == total ? 'All done! Amazing! 🎉'
                      : '${total - done} habit${total - done != 1 ? 's' : ''} left today',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 72, height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct, strokeWidth: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(pct * 100).round()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const Text('DONE',
                      style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Habit card ────────────────────────────────────────────
class _HabitCard extends StatefulWidget {
  final Habit habit;
  final bool done;
  final int delay;
  final VoidCallback onTap;
  const _HabitCard({required this.habit, required this.done, required this.delay, required this.onTap});
  @override
  State<_HabitCard> createState() => _HabitCardState();
}
class _HabitCardState extends State<_HabitCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = hexColor(widget.habit.color);
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: widget.done ? 0.55 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(context),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.habit.icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.habit.name,
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          decoration: widget.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        Text(widget.habit.freqLabel,
                          style: TextStyle(fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CheckCircle(checked: widget.done, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final bool checked;
  final Color color;
  const _CheckCircle({required this.checked, required this.color});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.elasticOut,
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? kSuccess : Colors.transparent,
        border: Border.all(
          color: checked ? kSuccess : Theme.of(context).dividerColor,
          width: 2.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(children: [
        const Text('✨', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text('No habits yet',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Tap the button below to add your first habit',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add First Habit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ]),
    ),
  );
}

class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: kSuccess.withOpacity(0.1),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kSuccess.withOpacity(0.3)),
    ),
    child: const Column(children: [
      Text('🎉', style: TextStyle(fontSize: 40)),
      SizedBox(height: 10),
      Text('All habits done!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kSuccess)),
      SizedBox(height: 4),
      Text('You crushed it today. See you tomorrow!',
        textAlign: TextAlign.center,
        style: TextStyle(color: kSuccess, fontSize: 14)),
    ]),
  );
}
