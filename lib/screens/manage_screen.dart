import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import 'add_habit_screen.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});
  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  List<Habit> _habits = [];
  String? _installDate;
  Set<String> _completions = {};
  bool _gridView = true; // default: 3-column grid

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _load();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _gridView = prefs.getBool('habit_grid_view') ?? true);
  }

  Future<void> _setGridView(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('habit_grid_view', v);
    if (mounted) setState(() => _gridView = v);
  }

  Future<void> _load() async {
    final habits = await StorageService.loadHabits();
    final completions = await StorageService.loadCompletions();
    final installDate = await StorageService.getInstallDate();
    if (mounted) setState(() { _habits = habits; _completions = completions; _installDate = installDate; });
  }

  int _streakFor(Habit h) {
    int streak = 0;
    var d = DateTime.now();
    while (true) {
      final key = '${h.id}_${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      if (_completions.contains(key)) {
        streak++;
        d = d.subtract(const Duration(days: 1));
      } else { break; }
    }
    return streak;
  }

  Future<void> _delete(Habit habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Delete "${habit.name}"? All history will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: kDanger))),
        ],
      ),
    );
    if (confirm != true) return;
    final habits = await StorageService.loadHabits();
    habits.removeWhere((h) => h.id == habit.id);
    await StorageService.saveHabits(habits);
    final completions = await StorageService.loadCompletions();
    completions.removeWhere((k) => k.startsWith('${habit.id}_'));
    await StorageService.saveCompletions(completions);
    await NotificationService.cancelHabitReminder(habit.id);
    await WidgetService.update(habits, completions);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('My Habits'),
            Text('Manage your Habits. Edit or add new ones.',
              style: TextStyle(fontSize: 11, color: Colors.white70,
                  fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          // Grid / list toggle
          IconButton(
            icon: Icon(_gridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _gridView ? 'Switch to list' : 'Switch to grid',
            onPressed: () => _setGridView(!_gridView),
          ),
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
      body: _habits.isEmpty
          ? _buildEmpty()
          : _gridView
              ? _buildGrid()
              : _buildList(),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('💧', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 16),
      const Text('No habits yet',
        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('Tap + to add your first habit',
        style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 14)),
      const SizedBox(height: 28),
      ElevatedButton.icon(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddHabitScreen()));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ]),
  );

  // ── 3-column grid ─────────────────────────────────────
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: _habits.length + 1, // +1 for the add tile
      itemBuilder: (_, i) {
        if (i == _habits.length) return _AddTile(onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddHabitScreen()));
          _load();
        });
        final h = _habits[i];
        final streak = _streakFor(h);
        return _GridTile(
          habit: h,
          streak: streak,
          onTap: () => _showHabitOptions(h),
        );
      },
    );
  }

  // ── Reorderable list ──────────────────────────────────
  Widget _buildList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _habits.length,
      onReorder: (oldIdx, newIdx) async {
        if (newIdx > oldIdx) newIdx--;
        setState(() {
          final h = _habits.removeAt(oldIdx);
          _habits.insert(newIdx, h);
        });
        await StorageService.saveHabits(_habits);
      },
      itemBuilder: (ctx, i) {
        final h = _habits[i];
        return _ListTile(
          key: ValueKey(h.id),
          index: i,
          habit: h,
          streak: _streakFor(h),
          onEdit: () async {
            await Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => AddHabitScreen(existing: h)));
            _load();
          },
          onDelete: () => _delete(h),
        );
      },
    );
  }

  void _showHabitOptions(Habit h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Handle
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            // Habit name header
            Row(children: [
              Text(h.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Text(h.name,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 20),
            // 30-day history strip
            _HabitHistoryStrip(habit: h, completions: _completions, installDate: _installDate),
            const SizedBox(height: 20),
            _sheetBtn(Icons.edit_outlined, 'Edit habit', Theme.of(context).colorScheme.primary, () async {
              Navigator.pop(context);
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddHabitScreen(existing: h)));
              _load();
            }),
            const SizedBox(height: 10),
            _sheetBtn(Icons.delete_outline, 'Delete habit', kDanger, () {
              Navigator.pop(context);
              _delete(h);
            }),
          ],
        ),
      ),
    );
  }

  Widget _sheetBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color,
              fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
}

// ── Grid tile — circular, matching Today screen ───────────
class _GridTile extends StatelessWidget {
  final Habit habit;
  final int streak;
  final VoidCallback onTap;
  const _GridTile({required this.habit, required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = hexColor(habit.color);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: LayoutBuilder(builder: (ctx, constraints) {
          final d = constraints.maxWidth * 0.76;
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Circle with emoji
              Container(
                width: d, height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.15),
                  border: Border.all(color: accent.withOpacity(0.6), width: 2.0),
                ),
                child: Center(
                  child: Text(habit.icon, style: TextStyle(fontSize: d * 0.38)),
                ),
              ),
              const SizedBox(height: 6),
              // Name
              Text(
                habit.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600, height: 1.25),
              ),
              const SizedBox(height: 2),
              Text(
                habit.freqLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
              if (streak > 0) ...[
                const SizedBox(height: 2),
                Text('${streak}d 🔥',
                  style: const TextStyle(
                      color: kWarning, fontSize: 9, fontWeight: FontWeight.w700)),
              ],
            ],
          );
        }),
      ),
    );
  }
}

// ── Add tile — circular ────────────────────────────────────
class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: LayoutBuilder(builder: (ctx, constraints) {
          final d = constraints.maxWidth * 0.76;
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: d, height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4), width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.add_rounded,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      size: d * 0.38),
                ),
              ),
              const SizedBox(height: 6),
              Text('New habit',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    fontSize: 10.5, fontWeight: FontWeight.w600)),
            ],
          );
        }),
      ),
    );
  }
}

// ── List tile ─────────────────────────────────────────────
class _ListTile extends StatelessWidget {
  final Habit habit;
  final int index, streak;
  final VoidCallback onEdit, onDelete;
  const _ListTile({
    super.key, required this.habit, required this.index,
    required this.streak, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: cardDecoration(context),
    child: Row(children: [
      ReorderableDragStartListener(
        index: index,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Icon(Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)),
        ),
      ),
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(habit.icon, style: const TextStyle(fontSize: 20)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(habit.name,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(
          habit.freqLabel + (streak > 0 ? ' · ${streak}d 🔥' : ''),
          style: TextStyle(fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
        ),
      ])),
      IconButton(
        icon: Icon(Icons.edit_outlined, size: 18,
            color: Theme.of(context).colorScheme.primary),
        onPressed: onEdit,
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, size: 18, color: kDanger),
        onPressed: onDelete,
      ),
    ]),
  );

  String _fmtTime(String t) {
    final p = t.split(':');
    final h = int.parse(p[0]); final m = int.parse(p[1]);
    return '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2,'0')}${h < 12 ? 'am' : 'pm'}';
  }
}


// ── Habit 30-day history strip (used in detail bottom sheet) ─
class _HabitHistoryStrip extends StatelessWidget {
  final Habit habit;
  final Set<String> completions;
  final String? installDate;
  const _HabitHistoryStrip({required this.habit, required this.completions, this.installDate});

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const days = 30;
    final dates =
        List.generate(days, (i) => today.subtract(Duration(days: days - 1 - i)));
    final todayStr = _fmt(today);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LAST 30 DAYS',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.secondary)),
      const SizedBox(height: 8),
      Row(
        children: dates.map((date) {
          final ds = _fmt(date);
          final isToday = ds == todayStr;
          final scheduled = habit.isScheduledOn(date);
          final done = completions
              .contains(StorageService.completionKey(habit.id, date));
          final isPreInstall = installDate != null &&
              ds.compareTo(installDate!) < 0;

          Color color;
          if (!scheduled || isPreInstall) {
            color = Theme.of(context).colorScheme.surfaceContainerHighest;
          } else if (done) {
            color = kSuccess;
          } else {
            color = Colors.grey.withOpacity(0.25);
          }

          return Expanded(
            child: Container(
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: isToday
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          '${dates.first.day} ${_monthAbbr(dates.first.month)}',
          style: TextStyle(
              color: Theme.of(context).colorScheme.secondary, fontSize: 9),
        ),
        Text(
          'Today',
          style: TextStyle(
              color: Theme.of(context).colorScheme.secondary, fontSize: 9),
        ),
      ]),
    ]);
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static String _monthAbbr(int m) => _months[m];
}
