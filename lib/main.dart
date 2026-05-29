import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models/habit.dart';
import 'screens/today_screen.dart';
import 'screens/manage_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotificationService.init();
  await WidgetService.init();
  await _seedIfEmpty();
  runApp(const HabitFlowApp());
}

Habit _preset(String name, String icon, String color, String freq, String time) =>
    Habit(
      id: const Uuid().v4(), name: name, icon: icon, color: color,
      freq: freq, days: [1,2,3,4,5], reminderTime: time,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

Future<void> _seedIfEmpty() async {
  final habits = await StorageService.loadHabits();
  if (habits.isNotEmpty) return;
  final demos = [
    _preset('Drink Water', '💧', '#4FC3F7', 'daily', '08:00'),
    _preset('Exercise',    '🏋️', '#EF5350', 'daily', '07:00'),
    _preset('Read',        '📖', '#FF8A65', 'daily', '21:00'),
  ];
  await StorageService.saveHabits(demos);
}

// ── App root ──────────────────────────────────────────────
class HabitFlowApp extends StatefulWidget {
  const HabitFlowApp({super.key});
  @override
  State<HabitFlowApp> createState() => _HabitFlowAppState();
}

class _HabitFlowAppState extends State<HabitFlowApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _themeMode = prefs.getBool('dark_mode') == true
            ? ThemeMode.dark
            : ThemeMode.light;
      });
    }
  }

  void _toggleTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', dark);
    if (mounted) setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitFlow',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: MainShell(
        onThemeChange: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

// ── Shell with bottom nav ─────────────────────────────────
class MainShell extends StatefulWidget {
  final void Function(bool) onThemeChange;
  final bool isDark;
  const MainShell({super.key, required this.onThemeChange, required this.isDark});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const TodayScreen(),
          const ManageScreen(),
          const StatsScreen(),
          SettingsScreen(
            onThemeChange: widget.onThemeChange,
            isDark: widget.isDark,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
