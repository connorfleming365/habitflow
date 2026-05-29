import 'package:flutter/material.dart';
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

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final h = await StorageService.loadHabits();
    if (mounted) setState(() => _habits = h);
  }

  Future<void> _delete(Habit habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Delete "${habit.name}"? All completion history will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final habits = await StorageService.loadHabits();
    habits.removeWhere((h) => h.id == habit.id);
    await StorageService.saveHabits(habits);
    // Clean completions
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
      appBar: AppBar(title: const Text('My Habits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddHabitScreen()));
          _load();
        },
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _habits.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('✨', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                Text('No habits yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Tap the button below to get started',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              ]),
            )
          : ReorderableListView.builder(
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
                return _HabitManageCard(
                  key: ValueKey(h.id),
                  habit: h,
                  onEdit: () async {
                    await Navigator.push(ctx,
                        MaterialPageRoute(builder: (_) => AddHabitScreen(existing: h)));
                    _load();
                  },
                  onDelete: () => _delete(h),
                );
              },
            ),
    );
  }
}

class _HabitManageCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit, onDelete;
  const _HabitManageCard({super.key, required this.habit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = hexColor(habit.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(context),
      child: Row(children: [
        ReorderableDragStartListener(
          index: 0,
          child: const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.drag_handle, color: Colors.grey),
          ),
        ),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(habit.icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(habit.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(
              habit.freqLabel + (habit.reminderTime.isNotEmpty ? ' · ⏰ ${_fmtTime(habit.reminderTime)}' : ''),
              style: TextStyle(fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        )),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
          color: Theme.of(context).colorScheme.primary,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          onPressed: onDelete,
        ),
      ]),
    );
  }

  String _fmtTime(String t) {
    final p = t.split(':');
    final h = int.parse(p[0]); final m = int.parse(p[1]);
    return '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2,'0')}${h < 12 ? 'am' : 'pm'}';
  }
}
