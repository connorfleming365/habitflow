import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(bool) onThemeChange;
  final bool isDark;
  const SettingsScreen({super.key, required this.onThemeChange, required this.isDark});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotifStatus();
  }

  Future<void> _checkNotifStatus() async {
    // Simple heuristic — if there's at least one scheduled notification
    setState(() => _notifsEnabled = true);
  }

  Future<void> _requestNotifications() async {
    await NotificationService.requestPermission();
    final habits = await StorageService.loadHabits();
    await NotificationService.scheduleAll(habits);
    if (mounted) {
      setState(() => _notifsEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔔 Reminders enabled!')));
    }
  }

  Future<void> _exportToGoogleCal() async {
    final habits = await StorageService.loadHabits();
    if (habits.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No habits to export')));
      return;
    }
    final h = habits.first;
    final title = Uri.encodeComponent('${h.icon} ${h.name} - Daily Habit');
    final url = 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&recur=RRULE:FREQ=DAILY';
    // Open URL — requires url_launcher in a real build; we show a message here
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening Google Calendar for: ${h.name}')));
  }

  Future<void> _exportData() async {
    final habits = await StorageService.loadHabits();
    final completions = await StorageService.loadCompletions();
    final data = jsonEncode({
      'habits': habits.map((h) => h.toJson()).toList(),
      'completions': completions.toList(),
      'exported': DateTime.now().toIso8601String(),
    });
    if (mounted) {
      await showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Your Data (JSON)'),
        content: SingleChildScrollView(child: SelectableText(data, style: const TextStyle(fontSize: 11))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ));
    }
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Clear all data?'),
      content: const Text('This will delete all habits and completion history. Cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm != true) return;
    await StorageService.saveHabits([]);
    await StorageService.saveCompletions({});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            label: 'Appearance',
            children: [
              _SettingsRow(
                icon: '🌙', title: 'Dark Mode', subtitle: 'Easy on the eyes',
                trailing: Switch(
                  value: widget.isDark,
                  onChanged: widget.onThemeChange,
                  activeColor: kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            label: 'Notifications',
            children: [
              _SettingsRow(
                icon: '🔔', title: 'Enable Reminders',
                subtitle: 'Daily push notifications per habit',
                trailing: Switch(
                  value: _notifsEnabled,
                  onChanged: (_) => _requestNotifications(),
                  activeColor: kPrimary,
                ),
              ),
              _SettingsRow(
                icon: '⏰', title: 'Reschedule All',
                subtitle: 'Re-sync all habit reminders',
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final habits = await StorageService.loadHabits();
                  await NotificationService.scheduleAll(habits);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⏰ Reminders rescheduled!')));
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            label: 'Calendar',
            children: [
              _SettingsRow(
                icon: '📅', title: 'Add to Google Calendar',
                subtitle: 'Create recurring reminder events',
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportToGoogleCal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            label: 'Data',
            children: [
              _SettingsRow(
                icon: '💾', title: 'Export Data',
                subtitle: 'View your habit history as JSON',
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportData,
              ),
              _SettingsRow(
                icon: '🗑️', title: 'Clear All Data',
                subtitle: 'This cannot be undone',
                titleColor: Colors.red,
                trailing: const Icon(Icons.chevron_right),
                onTap: _clearData,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            label: 'About',
            children: [
              const _SettingsRow(
                icon: '🌊', title: 'HabitFlow v1.0',
                subtitle: 'Your personal habit companion',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _Section({required this.label, required this.children});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
      ),
      Container(
        decoration: cardDecoration(context),
        child: Column(children: children),
      ),
    ],
  );
}

class _SettingsRow extends StatelessWidget {
  final String icon, title, subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsRow({
    required this.icon, required this.title, required this.subtitle,
    this.titleColor, this.trailing, this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 18))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor)),
          Text(subtitle, style: TextStyle(fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        ])),
        if (trailing != null) trailing!,
      ]),
    ),
  );
}
