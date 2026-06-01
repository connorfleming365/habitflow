import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String appTheme;
  final void Function(String) onThemeChange;
  const SettingsScreen(
      {super.key, required this.appTheme, required this.onThemeChange});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifsEnabled = false;
  bool _soundsEnabled = true;
  bool _nudgeEnabled = false;
  String _reminderTime = '08:00';
  String _nudgeTime = '21:00';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifsEnabled = prefs.getBool('notifs_enabled') ?? false;
        _soundsEnabled = prefs.getBool('sounds_enabled') ?? true;
        _nudgeEnabled  = prefs.getBool('nudge_enabled') ?? false;
        _reminderTime  = prefs.getString('global_reminder_time') ?? '08:00';
        _nudgeTime     = prefs.getString('nudge_time') ?? '21:00';
      });
    }
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setStringPref(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _requestNotifications() async {
    final granted = await NotificationService.requestPermission();
    if (!mounted) return;

    if (granted) {
      final habits = await StorageService.loadHabits();
      await NotificationService.scheduleAll(habits, globalTime: _reminderTime);
      await _setPref('notifs_enabled', true);
      if (mounted) {
        setState(() => _notifsEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminders enabled!')));
      }
    } else {
      // Permission denied — guide the user to enable it manually
      if (mounted) {
        setState(() => _notifsEnabled = false);
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    final isDark = widget.appTheme == 'deep_ocean';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? kMidnightTide : Colors.white,
        title: Text('Enable reminders',
            style: TextStyle(color: isDark ? Colors.white : kDeepOcean,
                fontWeight: FontWeight.w700)),
        content: Text(
          'To receive habit reminders, please enable notifications for HabitFlow:\n\n'
          '1. Open your phone\'s Settings\n'
          '2. Go to Apps → HabitFlow\n'
          '3. Tap Notifications\n'
          '4. Turn on "Allow notifications"\n\n'
          'Then come back and enable reminders here.',
          style: TextStyle(color: isDark ? kSeaFoam : kOceanBlue, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it')),
        ],
      ),
    );
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(':');
    final initial = TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => _reminderTime = formatted);
    await _setStringPref('global_reminder_time', formatted);

    // Re-schedule if reminders are on
    if (_notifsEnabled) {
      final habits = await StorageService.loadHabits();
      await NotificationService.scheduleAll(habits, globalTime: formatted);
    }
  }

  String _fmtTime(String t) {
    final p = t.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h % 12 == 0 ? 12 : h % 12;
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickNudgeTime() async {
    final parts = _nudgeTime.split(':');
    final initial = TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => _nudgeTime = formatted);
    await _setStringPref('nudge_time', formatted);

    if (_nudgeEnabled) {
      await NotificationService.scheduleNudge(formatted);
    }
  }

  Future<void> _shareProgress() async {
    final habits = await StorageService.loadHabits();
    final completions = await StorageService.loadCompletions();
    final activeDays = completions
        .map((k) => k.split('_').last)
        .toSet()
        .length;
    final stage = _stageNameFor(activeDays);
    final stageEmoji = _stageEmojiFor(activeDays);

    final text = '$stageEmoji I\'ve been building my flow for $activeDays days on HabitFlow!\n\n'
        'I\'m at the $stage stage — tracking ${habits.length} habits and flowing stronger every day. 🌊\n\n'
        'Drop by drop, you build your ocean.';

    await Share.share(text);
  }

  static String _stageNameFor(int days) {
    if (days >= 180) return 'Ocean';
    if (days >= 90)  return 'Lake';
    if (days >= 45)  return 'Stream';
    if (days >= 21)  return 'Pond';
    if (days >= 7)   return 'Puddle';
    return 'Droplets';
  }

  static String _stageEmojiFor(int days) {
    if (days >= 180) return '🌅';
    if (days >= 90)  return '🏞️';
    if (days >= 45)  return '🌊';
    if (days >= 21)  return '🌿';
    if (days >= 7)   return '💦';
    return '💧';
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
      await showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: const Text('Your data (JSON)'),
                content: SingleChildScrollView(
                    child: SelectableText(data,
                        style: const TextStyle(fontSize: 11))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'))
                ],
              ));
    }
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Reset all habits?'),
              content: const Text(
                  'This will delete all habits and completion history. Cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Reset',
                        style: TextStyle(color: kDanger))),
              ],
            ));
    if (confirm != true) return;
    await StorageService.saveHabits([]);
    await StorageService.saveCompletions({});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appTheme == 'deep_ocean';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [

          // Reminders
          _Section(label: 'Reminders', isDark: isDark, children: [
            _ToggleRow(
              icon: '🔔',
              title: 'Daily reminders',
              subtitle: 'Push notifications per habit',
              value: _notifsEnabled,
              isDark: isDark,
              onChanged: (v) {
                if (v) {
                  _requestNotifications();
                } else {
                  _setPref('notifs_enabled', false);
                  setState(() => _notifsEnabled = false);
                  NotificationService.scheduleAll([]);
                }
              },
            ),
            _DividerLine(isDark: isDark),
            _ActionRow(
              icon: '⏰',
              title: 'Reminder time',
              subtitle: _fmtTime(_reminderTime),
              isDark: isDark,
              onTap: _pickReminderTime,
            ),
            _DividerLine(isDark: isDark),
            _ActionRow(
              icon: '🔄',
              title: 'Re-sync reminders',
              subtitle: 'Reschedule all habit notifications',
              isDark: isDark,
              onTap: () async {
                final habits = await StorageService.loadHabits();
                await NotificationService.scheduleAll(habits, globalTime: _reminderTime);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Reminders rescheduled!')));
                }
              },
            ),
            _DividerLine(isDark: isDark),
            _ToggleRow(
              icon: '🌙',
              title: 'Evening nudge',
              subtitle: 'Gentle reminder if habits not done',
              value: _nudgeEnabled,
              isDark: isDark,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('nudge_enabled', v);
                setState(() => _nudgeEnabled = v);
                if (v) {
                  await NotificationService.scheduleNudge(_nudgeTime);
                } else {
                  await NotificationService.cancelNudgeToday();
                }
              },
            ),
            _DividerLine(isDark: isDark),
            _ActionRow(
              icon: '🕘',
              title: 'Nudge time',
              subtitle: _fmtTime(_nudgeTime),
              isDark: isDark,
              onTap: _pickNudgeTime,
            ),
          ]),
          const SizedBox(height: 16),

          // Sounds
          _Section(label: 'Sounds', isDark: isDark, children: [
            _ToggleRow(
              icon: '💧',
              title: 'Water drop sounds',
              subtitle: 'Plays on each habit check-off',
              value: _soundsEnabled,
              isDark: isDark,
              onChanged: (v) {
                _setPref('sounds_enabled', v);
                setState(() => _soundsEnabled = v);
              },
            ),
          ]),
          const SizedBox(height: 16),

          // Appearance
          _Section(label: 'Appearance', isDark: isDark, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme',
                      style: TextStyle(
                          color: isDark ? Colors.white : kDeepOcean,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _ThemeOption(
                        name: 'Deep Ocean',
                        subtitle: 'Dark & deep',
                        emoji: '🌊',
                        selected: widget.appTheme == 'deep_ocean',
                        isDark: isDark,
                        onTap: () => widget.onThemeChange('deep_ocean'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeOption(
                        name: 'Sea Mist',
                        subtitle: 'Light & airy',
                        emoji: '☀️',
                        selected: widget.appTheme == 'sea_mist',
                        isDark: isDark,
                        onTap: () => widget.onThemeChange('sea_mist'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Data
          _Section(label: 'Data', isDark: isDark, children: [
            _ActionRow(
              icon: '💾',
              title: 'Export my data',
              subtitle: 'View habit history as JSON',
              isDark: isDark,
              onTap: _exportData,
            ),
            _DividerLine(isDark: isDark),
            _ActionRow(
              icon: '🗑️',
              title: 'Reset all habits',
              subtitle: 'Cannot be undone',
              titleColor: kDanger,
              isDark: isDark,
              onTap: _clearData,
            ),
          ]),
          const SizedBox(height: 16),

          // Share
          _Section(label: 'Share', isDark: isDark, children: [
            _ActionRow(
              icon: '🌊',
              title: 'Share my progress',
              subtitle: 'Tell friends about your flow',
              isDark: isDark,
              onTap: _shareProgress,
            ),
          ]),
          const SizedBox(height: 16),

          // About
          _Section(label: 'About', isDark: isDark, children: [
            _ActionRow(
              icon: '📖',
              title: 'View introduction',
              subtitle: 'Revisit the getting started guide',
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OnboardingScreen(
                      onComplete: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
            ),
            _DividerLine(isDark: isDark),
            _InfoRow(
              icon: '🌊',
              title: 'HabitFlow v1.0',
              subtitle: 'Drop by drop, you build your ocean.',
              isDark: isDark,
            ),
          ]),
        ],
      ),
    );
  }
}

// Theme option card
class _ThemeOption extends StatelessWidget {
  final String name, subtitle, emoji;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? kDeepOcean : const Color(0xFFEAF5FB);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? kReefBlue.withOpacity(0.15) : bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kReefBlue : kOceanBlue.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(name,
              style: TextStyle(
                  color: isDark ? Colors.white : kDeepOcean,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: TextStyle(
                  color: isDark ? kSeaFoam : kOceanBlue, fontSize: 10)),
          if (selected)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.check_circle, color: kReefBlue, size: 16),
            ),
        ]),
      ),
    );
  }
}

// Section wrapper
class _Section extends StatelessWidget {
  final String label;
  final bool isDark;
  final List<Widget> children;
  const _Section(
      {required this.label, required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: kSeaFoam)),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? kMidnightTide : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: kOceanBlue.withOpacity(0.3), width: 0.5),
            ),
            child: Column(children: children),
          ),
        ],
      );
}

class _DividerLine extends StatelessWidget {
  final bool isDark;
  const _DividerLine({required this.isDark});
  @override
  Widget build(BuildContext context) => Divider(
        height: 0,
        thickness: 0.5,
        indent: 16,
        endIndent: 16,
        color: kOceanBlue.withOpacity(isDark ? 0.2 : 0.15),
      );
}

// Row types
class _ToggleRow extends StatelessWidget {
  final String icon, title, subtitle;
  final bool value, isDark;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _IconBox(icon, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        color: isDark ? Colors.white : kDeepOcean,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: TextStyle(
                        color: isDark ? kSeaFoam : kOceanBlue,
                        fontSize: 12)),
              ])),
          Switch(value: value, onChanged: onChanged),
        ]),
      );
}

class _ActionRow extends StatelessWidget {
  final String icon, title, subtitle;
  final Color? titleColor;
  final bool isDark;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            _IconBox(icon, isDark: isDark),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          color:
                              titleColor ?? (isDark ? Colors.white : kDeepOcean),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: TextStyle(
                          color: isDark ? kSeaFoam : kOceanBlue,
                          fontSize: 12)),
                ])),
            Icon(Icons.chevron_right,
                color: kOceanBlue.withOpacity(0.6), size: 20),
          ]),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String icon, title, subtitle;
  final bool isDark;
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _IconBox(icon, isDark: isDark),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    color: isDark ? Colors.white : kDeepOcean,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: TextStyle(
                    color: isDark ? kSeaFoam : kOceanBlue, fontSize: 12)),
          ]),
        ]),
      );
}

class _IconBox extends StatelessWidget {
  final String icon;
  final bool isDark;
  const _IconBox(this.icon, {required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kOceanBlue.withOpacity(isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(icon, style: const TextStyle(fontSize: 17)),
      );
}
