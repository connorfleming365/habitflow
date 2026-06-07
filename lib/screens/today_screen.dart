import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../services/progression_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'add_habit_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => TodayScreenState();
}

class TodayScreenState extends State<TodayScreen>
    with TickerProviderStateMixin {
  List<Habit> _habits = [];
  Set<String> _completions = {};
  bool _loading = true;
  bool _gridMode = false; // false = circles (default), true = full-width tiles

  late AnimationController _waveCtrl;
  late AnimationController _stageCtrl;
  late AnimationController _pctCtrl;
  late Animation<double> _pctAnim;
  double _lastPct = 0;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _stageCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _pctCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pctAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _pctCtrl, curve: Curves.easeOut));
    _loadViewMode();
    _load();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _gridMode = prefs.getBool('today_view_grid') ?? false);
  }

  Future<void> _toggleViewMode() async {
    final next = !_gridMode;
    setState(() => _gridMode = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('today_view_grid', next);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _stageCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  void reload() => _load();

  void _showConfetti() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiBurst(onDone: () {
        if (entry.mounted) entry.remove();
      }),
    );
    Overlay.of(context).insert(entry);
  }

  Future<void> _load() async {
    final habits = await StorageService.loadHabits();
    var completions = await StorageService.loadCompletions();
    // Merge any widget-side toggles. Kotlin writes done-state back into
    // hf_habits_json, which is a plain JSON string we can safely parse here.
    completions = await _mergeWidgetToggles(habits, completions);
    await WidgetService.update(habits, completions);
    if (mounted) {
      final today = habits.where((h) => h.isScheduledOn(DateTime.now())).toList();
      final pct = today.isEmpty ? 0.0 :
          today.where((h) => completions.contains(StorageService.todayKey(h.id))).length / today.length;
      _animatePct(pct);
      setState(() { _habits = habits; _completions = completions; _loading = false; });;

      // Cancel nudge if all done
      if (today.isNotEmpty && today.every((h) => completions.contains(StorageService.todayKey(h.id)))) {
        NotificationService.cancelNudgeToday();
      }
    }
  }

  /// Reads the `hf_habits_json` that Kotlin writes when the widget is tapped,
  /// and applies any done-state differences back into Flutter's completions set.
  /// This is format-safe because hf_habits_json is a plain JSON string, unlike
  /// hf_completions which has an internal encoding that Kotlin can't reliably write.
  Future<Set<String>> _mergeWidgetToggles(
      List<Habit> habits, Set<String> completions) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guard: hf_today_date tells us when hf_habits_json was last written.
      // If it's from a previous day, the done-flags are stale — applying them
      // would incorrectly mark today's habits as completed on the new day.
      final widgetDate = prefs.getString('hf_today_date') ?? '';
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (widgetDate != todayStr) return completions;

      final raw = prefs.getString('hf_habits_json');
      if (raw == null || raw == '[]') return completions;
      final List<dynamic> widgetList = jsonDecode(raw);
      final today = DateTime.now();
      final result = Set<String>.from(completions);
      bool changed = false;
      for (final item in widgetList) {
        final String id = item['id'] as String;
        final bool widgetDone = item['done'] as bool;
        final key = StorageService.completionKey(id, today);
        if (widgetDone && !result.contains(key)) {
          result.add(key);
          changed = true;
        } else if (!widgetDone && result.contains(key)) {
          result.remove(key);
          changed = true;
        }
      }
      if (changed) await StorageService.saveCompletions(result);
      return result;
    } catch (_) {
      return completions;
    }
  }

  void _animatePct(double newPct) {
    _pctAnim = Tween<double>(begin: _lastPct, end: newPct).animate(
      CurvedAnimation(parent: _pctCtrl, curve: Curves.easeOut));
    _pctCtrl.forward(from: 0);
    _lastPct = newPct;
  }

  Future<void> _toggle(Habit habit) async {
    HapticFeedback.lightImpact();
    final key = StorageService.todayKey(habit.id);
    final newSet = Set<String>.from(_completions);
    final wasAdding = !newSet.contains(key);
    if (wasAdding) { newSet.add(key); HapticFeedback.mediumImpact(); }
    else           { newSet.remove(key); }

    await StorageService.saveCompletions(newSet);
    await WidgetService.update(_habits, newSet);

    final today = _habits.where((h) => h.isScheduledOn(DateTime.now())).toList();
    final allNowDone = today.isNotEmpty && today.every((h) => newSet.contains(StorageService.todayKey(h.id)));

    if (wasAdding) {
      allNowDone ? SoundService.playWave() : SoundService.playDrop();
      if (allNowDone && mounted) _showConfetti();
    }

    if (wasAdding) {
      final activeDays = ProgressionService.countActiveDays(newSet);
      await _checkMilestone(activeDays);
    }

    if (allNowDone) NotificationService.cancelNudgeToday();

    final newPct = today.isEmpty ? 0.0 :
        today.where((h) => newSet.contains(StorageService.todayKey(h.id))).length / today.length;
    _animatePct(newPct);
    if (mounted) setState(() => _completions = newSet);
  }

  Future<void> _checkMilestone(int activeDays) async {
    if (!ProgressionService.milestones.contains(activeDays)) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'milestone_${activeDays}_shown';
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    if (mounted) _showMilestone(activeDays);
  }

  void _showMilestone(int days) {
    final stage = ProgressionService.stageForDays(days);
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 500),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (_, __, ___) => _MilestoneDialog(days: days, stage: stage),
    );
  }

  List<Habit> get _todayHabits =>
      _habits.where((h) => h.isScheduledOn(DateTime.now())).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary)));

    final today = _todayHabits;
    final done = today.where((h) => _completions.contains(StorageService.todayKey(h.id))).toList();
    final remaining = today.where((h) => !_completions.contains(StorageService.todayKey(h.id))).toList();
    final activeDays = ProgressionService.countActiveDays(_completions);
    final stage = ProgressionService.stageForDays(activeDays);
    final allDone = today.isNotEmpty && remaining.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).cardColor,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: Listenable.merge([_waveCtrl, _stageCtrl, _pctAnim]),
                builder: (_, __) => _WaveHeader(
                  wavePhase: _waveCtrl.value,
                  stagePhase: _stageCtrl.value,
                  pct: _pctAnim.value,
                  done: done.length,
                  total: today.length,
                  stage: stage,
                  activeDays: activeDays,
                  allDone: allDone,
                  onAdd: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddHabitScreen()));
                    _load();
                  },
                ),
              ),
            ),

            // Quote
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
                  ),
                  child: Row(children: [
                    const Text('💧', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(dailyQuote(),
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12,
                          fontStyle: FontStyle.italic, height: 1.4))),
                  ]),
                ),
              ),
            ),

            if (today.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(onAdd: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddHabitScreen()));
                  _load();
                }),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (remaining.isNotEmpty) ...[
                          _bannerLabel("TODAY'S HABITS", showToggle: true),
                          _gridMode
                            ? Column(children: remaining.map((h) => _HabitListTile(
                                habit: h, done: false,
                                onTap: () => _toggle(h),
                              )).toList())
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.78,
                                  ),
                                  itemCount: remaining.length,
                                  itemBuilder: (_, i) => _HabitCircleTile(
                                    habit: remaining[i], done: false,
                                    onTap: () => _toggle(remaining[i]),
                                  ),
                                ),
                              ),
                        ],
                        if (done.isNotEmpty) ...[
                          _bannerLabel('COMPLETED ✓', showToggle: remaining.isEmpty),
                          _gridMode
                            ? Column(children: done.map((h) => _HabitListTile(
                                habit: h, done: true,
                                onTap: () => _toggle(h),
                              )).toList())
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.78,
                                  ),
                                  itemCount: done.length,
                                  itemBuilder: (_, i) => _HabitCircleTile(
                                    habit: done[i], done: true,
                                    onTap: () => _toggle(done[i]),
                                  ),
                                ),
                              ),
                        ],
                        if (allDone)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: SizedBox(width: double.infinity, child: _AllDoneCard()),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bannerLabel(String text, {bool showToggle = false}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.0, color: Theme.of(context).colorScheme.secondary)),
        if (showToggle)
          GestureDetector(
            onTap: _toggleViewMode,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _gridMode ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
                    key: ValueKey(_gridMode),
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// ── Wave header ───────────────────────────────────────────
class _WaveHeader extends StatelessWidget {
  final double wavePhase, stagePhase, pct;
  final int done, total, activeDays;
  final WaterStage stage;
  final bool allDone;
  final VoidCallback onAdd;

  const _WaveHeader({
    required this.wavePhase, required this.stagePhase, required this.pct,
    required this.done, required this.total,
    required this.stage, required this.activeDays,
    required this.allDone, required this.onAdd,
  });

  String get _flowGreeting {
    if (total == 0) return 'Start your flow';
    if (allDone)    return 'Flow complete! 🌊';
    if (done == 0)  return 'Make your first drop 💧';
    if (pct < 0.5)  return 'Your tide is rising 🌊';
    return 'Almost there, keep flowing';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}';
    final fillY = 220 * (1 - pct.clamp(0.0, 1.0));

    return Container(
      height: 220,
      color: Colors.black.withOpacity(0.25),
      child: Stack(children: [
        // Wave fill
        Positioned.fill(
          child: CustomPaint(
            painter: _WavePainter(phase: wavePhase, fill: pct),
          ),
        ),
        // Stage-specific animation layer
        Positioned.fill(
          child: CustomPaint(
            painter: _StageAnimPainter(
                stage: stage, phase: stagePhase, fillY: fillY),
          ),
        ),
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(dateStr, style: const TextStyle(
                        color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_flowGreeting, style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('STAGE',
                        style: TextStyle(color: Colors.white70, fontSize: 9,
                            fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(ProgressionService.stageEmoji(stage),
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(ProgressionService.stageName(stage),
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ],
                  ),
                ]),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        total == 0 ? 'Add your first habit →'
                            : allDone ? 'All done! 🎉'
                            : '$done of $total habits done today',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 170, height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: allDone ? kSuccess : Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    SizedBox(
                      width: 52, height: 52,
                      child: Stack(alignment: Alignment.center, children: [
                        CircularProgressIndicator(
                          value: pct, strokeWidth: 4,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(
                              allDone ? kSuccess : Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                        Text('${(pct * 100).round()}%',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 12, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Wave painter ──────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double phase, fill;
  const _WavePainter({required this.phase, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final fillY = size.height * (1 - fill.clamp(0.0, 1.0));
    _drawWave(canvas, size, fillY + 12, phase,       kWaveDeep.withOpacity(0.5));
    _drawWave(canvas, size, fillY + 4,  phase + 0.3, kWaveMid.withOpacity(0.45));
    _drawWave(canvas, size, fillY,       phase + 0.6, kWaveMid.withOpacity(0.35));
  }

  void _drawWave(Canvas canvas, Size size, double top,
      double phaseOffset, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, top);
    for (double x = 0; x <= size.width; x++) {
      final y = top + sin((x / size.width * 2 * pi) + (phaseOffset * 2 * pi)) * 10;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.phase != phase || old.fill != fill;
}

// ── Stage animation painter ───────────────────────────────
class _StageAnimPainter extends CustomPainter {
  final WaterStage stage;
  final double phase;  // 0-1 looping
  final double fillY;  // y of water surface in pixels

  const _StageAnimPainter({
    required this.stage, required this.phase, required this.fillY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (stage) {
      case WaterStage.drop:   _paintDrops(canvas, size);  break;
      case WaterStage.puddle: _paintPuddle(canvas, size); break;
      case WaterStage.spring: _paintPuddle(canvas, size); break;
      case WaterStage.stream: _paintStream(canvas, size); break;
      case WaterStage.tide:   _paintLake(canvas, size);   break;
      case WaterStage.ocean:  _paintOcean(canvas, size);  break;
    }
  }

  // Falling teardrops that splash into ripples
  void _paintDrops(Canvas canvas, Size size) {
    const xFracs = [0.15, 0.32, 0.52, 0.68, 0.84];
    const offsets = [0.0, 0.22, 0.44, 0.66, 0.11];
    final surfaceY = fillY.clamp(20.0, size.height - 10);

    for (int i = 0; i < 5; i++) {
      final p = (phase + offsets[i]) % 1.0;
      final x = size.width * xFracs[i];

      if (p < 0.78) {
        // Falling drop
        final t = p / 0.78;
        final y = t * t * surfaceY; // accelerate downward
        final opacity = (0.85 - t * 0.25).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = const Color(0xFF64B5F6).withOpacity(opacity)
          ..style = PaintingStyle.fill;
        _teardrop(canvas, Offset(x, y), 5.5, paint);
      } else {
        // Ripple splash
        final t = (p - 0.78) / 0.22;
        final r = t * 18.0;
        final opacity = (1.0 - t) * 0.5;
        if (opacity > 0.02) {
          final paint = Paint()
            ..color = const Color(0xFF90CAF9).withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawCircle(Offset(x, surfaceY), r, paint);
        }
      }
    }
  }

  void _teardrop(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r * 1.1)
      ..cubicTo(c.dx + r * 0.8, c.dy - r * 0.3, c.dx + r * 0.8, c.dy + r * 0.3, c.dx, c.dy + r * 0.7)
      ..cubicTo(c.dx - r * 0.8, c.dy + r * 0.3, c.dx - r * 0.8, c.dy - r * 0.3, c.dx, c.dy - r * 1.1);
    canvas.drawPath(path, paint);
  }

  // Expanding concentric ripples
  void _paintPuddle(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = fillY.clamp(20.0, size.height - 5) + 4;
    final maxR = size.width * 0.38;

    for (int i = 0; i < 3; i++) {
      final p = (phase + i / 3.0) % 1.0;
      final r = p * maxR;
      final opacity = (1.0 - p) * 0.6;
      if (opacity < 0.02) continue;
      final paint = Paint()
        ..color = const Color(0xFF80DEEA).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 - p * 0.8;
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  // Flowing particles left to right
  void _paintStream(Canvas canvas, Size size) {
    const xStarts = [0.0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.0, 0.15, 0.35, 0.6];
    const yOffsets = [-6.0, 5.0, -3.0, 8.0, -7.0, 3.0, 10.0, -5.0, 6.0, -2.0];
    const speeds   = [1.0, 0.85, 1.15, 0.95, 1.2, 0.75, 1.05, 0.9, 1.1, 0.8];
    final baseY = fillY.clamp(10.0, size.height - 5);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      final p = (phase * speeds[i] + xStarts[i]) % 1.0;
      final x = p * (size.width + 16) - 8;
      final y = baseY + yOffsets[i];
      final brightness = sin(p * pi).clamp(0.0, 1.0);
      final r = 2.5 + brightness * 2.0;
      paint.color = const Color(0xFFB3E5FC).withOpacity(brightness * 0.65);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  // Sparkling shimmer on the water
  void _paintLake(Canvas canvas, Size size) {
    const xFracs = [0.07,0.17,0.27,0.37,0.47,0.57,0.67,0.77,0.87,0.12,0.32,0.52,0.72,0.22,0.62];
    const offs    = [0.0,0.13,0.27,0.4,0.53,0.67,0.8,0.07,0.2,0.33,0.47,0.6,0.73,0.87,0.1];
    const ySpread = [-6.0,7.0,-3.0,10.0,4.0,-8.0,2.0,9.0,-5.0,6.0,-4.0,8.0,1.0,-7.0,5.0];
    final baseY = fillY.clamp(10.0, size.height - 5);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < xFracs.length; i++) {
      final p = (phase + offs[i]) % 1.0;
      final bright = (sin(p * 2 * pi) * 0.5 + 0.5);
      final opacity = bright * 0.7;
      if (opacity < 0.05) continue;
      final x = size.width * xFracs[i];
      final y = baseY + ySpread[i];
      final r = 1.5 + bright * 2.5;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  // Foam spray at wave peaks
  void _paintOcean(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (double x = 4; x < size.width; x += 7) {
      final waveY = fillY - 6 + sin((x / size.width * 2 * pi) + phase * 2 * pi) * 9;
      final spray = (sin((x / size.width * 5 * pi) + phase * 3 * pi) + 1) / 2;
      if (spray > 0.75) {
        final h = (spray - 0.75) / 0.25 * 10;
        paint.color = Colors.white.withOpacity(0.25 + spray * 0.25);
        canvas.drawCircle(Offset(x, waveY - h), 1.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StageAnimPainter old) =>
      old.phase != phase || old.fillY != fillY || old.stage != stage;
}

// ── Compact 3-column habit drop card ─────────────────────
// ── Circular habit tile ───────────────────────────────────
class _HabitCircleTile extends StatelessWidget {
  final Habit habit;
  final bool done;
  final VoidCallback onTap;
  const _HabitCircleTile({required this.habit, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = done ? kSuccess : hexColor(habit.color);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: LayoutBuilder(builder: (ctx, constraints) {
          final d = constraints.maxWidth * 0.76; // circle diameter
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: d, height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? kSuccess : accent.withOpacity(0.12),
                  border: Border.all(
                    color: done ? kSuccess : accent.withOpacity(0.55),
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: done
                    ? Icon(Icons.check_rounded, color: Colors.white, size: d * 0.40)
                    : Text(habit.icon, style: TextStyle(fontSize: d * 0.38)),
                ),
              ),
              const SizedBox(height: 7),
              // Name below
              Text(
                habit.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: done
                      ? kSuccess
                      : Theme.of(context).colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Full-width habit list tile ────────────────────────────
class _HabitListTile extends StatelessWidget {
  final Habit habit;
  final bool done;
  final VoidCallback onTap;
  const _HabitListTile({required this.habit, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = done ? kSuccess : hexColor(habit.color);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: done
              ? kSuccess.withOpacity(0.08)
              : Theme.of(context).colorScheme.surface.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done ? kSuccess.withOpacity(0.4) : accent.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(children: [
          // Icon in coloured circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? kSuccess : accent.withOpacity(0.15),
              border: Border.all(
                color: done ? kSuccess : accent.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : Text(habit.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          // Habit name
          Expanded(
            child: Text(
              habit.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: done ? kSuccess : Theme.of(context).colorScheme.onSurface,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Completion indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? kSuccess : Colors.transparent,
              border: Border.all(
                color: done
                    ? kSuccess
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
                width: 2,
              ),
            ),
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ── Milestone celebration dialog ──────────────────────────
class _MilestoneDialog extends StatefulWidget {
  final int days;
  final WaterStage stage;
  const _MilestoneDialog({required this.days, required this.stage});

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: primary.withOpacity(0.92),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _bounce,
                child: Text(ProgressionService.stageEmoji(widget.stage),
                    style: const TextStyle(fontSize: 80)),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(ProgressionService.milestoneTitle(widget.days),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 28, fontWeight: FontWeight.w800, height: 1.2)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Day ${widget.days}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(ProgressionService.milestoneMessage(widget.days),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 15, height: 1.65)),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Keep flowing 🌊',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confetti burst overlay ────────────────────────────────
class _ConfettiBurst extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiBurst({required this.onDone});
  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(70, (_) => _Particle(rng));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _ConfettiPainter(_particles, _ctrl.value),
      ),
    ),
  );
}

class _Particle {
  final double x;
  final double startY;
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final bool isSquare;

  static const _colors = [
    Color(0xFF26C6A0), // kSuccess green
    Color(0xFFFF6B6B), // coral
    Color(0xFFFFB830), // amber
    Colors.white,
    Color(0xFFC4B5FD), // violet
    Color(0xFF26D0CE), // cyan
  ];

  _Particle(Random rng)
      : x = 0.1 + rng.nextDouble() * 0.8,
        startY = 0.2 + rng.nextDouble() * 0.3,
        angle = -pi / 2 + (rng.nextDouble() - 0.5) * pi * 1.4,
        speed = 0.1 + rng.nextDouble() * 0.35,
        size = 5 + rng.nextDouble() * 6,
        color = _colors[rng.nextInt(_colors.length)],
        isSquare = rng.nextBool();
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOut.transform(t);
    for (final p in particles) {
      final opacity = (1 - eased).clamp(0.0, 1.0);
      final dx = p.x * size.width + cos(p.angle) * p.speed * size.width * eased;
      final dy = p.startY * size.height
          + sin(p.angle) * p.speed * size.height * eased
          + 0.12 * size.height * eased * eased; // gravity
      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(eased * pi * 5 * (p.isSquare ? 1 : -1));
      if (p.isSquare) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ── Empty state ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('💧', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        Text('Start your flow', style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Add your first habit and drop by drop\nyou\'ll build your ocean.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 14, height: 1.5)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add First Habit',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ]),
    ),
  );
}

// ── All done card ─────────────────────────────────────────
class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: kSuccess.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kSuccess.withOpacity(0.4), width: 0.5),
    ),
    child: const Column(children: [
      Text('🌊', style: TextStyle(fontSize: 40)),
      SizedBox(height: 10),
      Text('Flow complete!', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: kSuccess)),
      SizedBox(height: 4),
      Text('Your ocean is rising.\nSee you tomorrow.',
        textAlign: TextAlign.center,
        style: TextStyle(color: kSuccess, fontSize: 13, height: 1.5)),
    ]),
  );
}
