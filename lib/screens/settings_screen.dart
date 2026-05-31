import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';

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
  bool _animsEnabled  = true;
  bool _gridView      = true;

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
        _animsEnabled  = prefs.getBool('anims_enabled')  ?? true;
        _gridView      = prefs.getBool('habit_grid_view') ?? true;
      });
    }
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _requestNotifications() async {
    try {
      await NotificationService.requestPermission();
      final habits = await StorageService.loadHabits();
      await NotificationService.scheduleAll(habits);
      await _setPref('notifs_enabled', true);
      if (mounted) {
        setState(() => _notifsEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('💧 Reminders enabled!')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notifsEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not enable reminders. Check app permissions.')));
      }
    }
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
                    child:
                        const Text('Reset', style: TextStyle(color: kDanger))),
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

          // ── Reminders ─────────────────────────────
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
                  NotificationService.scheduleAll([]); // cancel all
                }
              },
            ),
            _DividerLine(isDark: isDark),
            _ActionRow(
              icon: '⏰',
              title: 'Re-sync reminders',
              subtitle: 'Reschedule all habit notifications',
              isDark: isDark,
              onTap: () async {
                final habits = await StorageService.loadHabits();
                await NotificationService.scheduleAll(habits);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('⏰ Reminders rescheduled!')));
                }
              },
            ),
          ]),
          const SizedBox(height: 16),

          // ── Sounds & feel ─────────────────────────
          _Section(label: 'Sounds & feel', isDark: isDark, children: [
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
            _DividerLine(isDark: isDark),
            _ToggleRow(
              icon: '🌊',
              title: 'Wave animations',
              subtitle: 'Animated wave on Today screen',
              value: _animsEnabled,
              isDark: isDark,
              onChanged: (v) {
                _setPref('anims_enabled', v);
                setState(() => _animsEnabled = v);
              },
            ),
          ]),
          const SizedBox(height: 16),

          // ── Appearance ────────────────────────────
          _Section(label: 'Appearance', isDark: isDark, children: [
            // Theme selector
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
            _DividerLine(isDark: isDark),
            _ToggleRow(
              icon: '⊞',
              title: 'Grid view for habits',
              subtitle: 'Show habits as 3-column grid',
              value: _gridView,
              isDark: isDark,
              onChanged: (v) {
                _setPref('habit_grid_view', v);
                setState(() => _gridView = v);
              },
            ),
          ]),
          const SizedBox(height: 16),

          // ── Data ──────────────────────────────────
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

          // ── About ─────────────────────────────────
          _Section(label: 'About', isDark: isDark, children: [
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

// ── Theme option card ─────────────────────────────────────
class _ThemeOption extends StatelessWidget {
  final String name, subtitle, emoji;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.name, required this.subtitle, required this.emoji,
    required this.selected, required this.isDark, required this.onTap,
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
                  color: isDark ? kSeaFoam : kOceanBlue,
                  fontSize: 10)),
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

// ── Section wrapper ───────────────────────────────────────
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

// ── Row types ─────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String icon, title, subtitle;
  final bool value, isDark;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.isDark, required this.onChanged,
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
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ]),
      );
}

class _ActionRow extends StatelessWidget {
  final String icon, title, subtitle;
  final Color? titleColor;
  final bool isDark;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon, required this.title, required this.subtitle,
    this.titleColor, required this.isDark, required this.onTap,
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
                          color: titleColor ??
                              (isDark ? Colors.white : kDeepOcean),
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
  const _InfoRow(
      {required this.icon, required this.title,
       required this.subtitle, required this.isDark});

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
