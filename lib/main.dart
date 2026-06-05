import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models/habit.dart';
import 'screens/today_screen.dart';
import 'screens/manage_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotificationService.init();
  await WidgetService.init();
  await SoundService.init();
  await StorageService.setInstallDateIfNew();
  await _seedIfEmpty();
  await _rescheduleNotifsIfEnabled();
  runApp(const HabitFlowApp());
}

/// Re-schedule all habit reminders on every cold start (Android kills exact
/// alarms on reboot/reinstall, so we need to restore them when the app opens).
Future<void> _rescheduleNotifsIfEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool('notifs_enabled') ?? false)) return;
  final habits = await StorageService.loadHabits();
  final globalTime = prefs.getString('global_reminder_time') ?? '08:00';
  await NotificationService.scheduleAll(habits, globalTime: globalTime);
}

Habit _preset(String name, String icon, String color, String freq, String time) =>
    Habit(
      id: const Uuid().v4(), name: name, icon: icon, color: color,
      freq: freq, days: [1, 2, 3, 4, 5], reminderTime: time,
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
  String _appTheme = 'coral_tide';
  bool _onboardingDone = false;
  bool _prefsLoaded = false;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _appTheme      = prefs.getString('app_theme') ?? 'coral_tide';
        _onboardingDone = prefs.getBool('onboarding_done') ?? false;
        _prefsLoaded   = true;
      });
    }
  }

  /// Called by SplashScreen when its exit animation finishes.
  void _onSplashComplete() {
    if (mounted) setState(() => _splashDone = true);
  }

  Future<void> _setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme);
    if (mounted) setState(() => _appTheme = theme);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) setState(() => _onboardingDone = true);
  }

  ThemeData get _themeData =>
      _appTheme == 'deep_abyss' ? AppTheme.deepAbyss : AppTheme.coralTide;

  @override
  Widget build(BuildContext context) {
    // Always show splash on cold start; prefs load in parallel behind it.
    if (!_splashDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.coralTide,
        home: SplashScreen(onComplete: _onSplashComplete),
      );
    }

    // Splash done — prefs will be loaded by now (splash is ~2.5 s).
    return MaterialApp(
      title: 'habitflow',
      debugShowCheckedModeBanner: false,
      theme: _themeData,
      home: _onboardingDone
          ? MainShell(appTheme: _appTheme, onThemeChange: _setTheme)
          : OnboardingScreen(onComplete: _completeOnboarding),
    );
  }
}

// ── Shell with bottom nav ─────────────────────────────────
class MainShell extends StatefulWidget {
  final String appTheme;
  final void Function(String) onThemeChange;
  const MainShell(
      {super.key, required this.appTheme, required this.onThemeChange});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  final _todayKey = GlobalKey<TodayScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Reload Today when the app returns to the foreground – this picks up
  /// any completions the user toggled directly from the Android widget.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _todayKey.currentState?.reload();
    }
  }

  void _onTabSelected(int i) {
    // Reload Today data when switching back to it from another tab
    if (i == 0 && _index != 0) {
      _todayKey.currentState?.reload();
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ocean background image sits behind every screen.
      // A semi-transparent scrim keeps text readable.
      body: Stack(
        children: [
          // ── Solid theme background (no image) ────────────
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),

          // ── App screens ───────────────────────────────
          Offstage(
            offstage: _index != 0,
            child: TodayScreen(key: _todayKey),
          ),
          if (_index == 1) const ManageScreen(),
          if (_index == 2) const StatsScreen(),
          if (_index == 3)
            SettingsScreen(
              appTheme: widget.appTheme,
              onThemeChange: widget.onThemeChange,
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
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
