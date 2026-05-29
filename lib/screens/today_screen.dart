import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../services/progression_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'add_habit_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with TickerProviderStateMixin {
  List<Habit> _habits = [];
  Set<String> _completions = {};
  bool _loading = true;

  late AnimationController _waveCtrl;
  late AnimationController _pctCtrl;
  late Animation<double> _pctAnim;
  double _lastPct = 0;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _pctCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pctAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _pctCtrl, curve: Curves.easeOut));
    _load();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final habits = await StorageService.loadHabits();
    final completions = await StorageService.loadCompletions();
    if (mounted) {
      final today = habits.where((h) => h.isScheduledOn(DateTime.now())).toList();
      final pct = today.isEmpty ? 0.0 :
          today.where((h) => completions.contains(StorageService.todayKey(h.id))).length / today.length;
      _animatePct(pct);
      setState(() { _habits = habits; _completions = completions; _loading = false; });
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
    if (wasAdding) {
      newSet.add(key);
      HapticFeedback.mediumImpact();
    } else {
      newSet.remove(key);
    }
    await StorageService.saveCompletions(newSet);
    await WidgetService.update(_habits, newSet);
    // Sound effects
    if (wasAdding) {
      final today2 = _habits.where((h) => h.isScheduledOn(DateTime.now())).toList();
      final allNowDone = today2.every((h) => newSet.contains(StorageService.todayKey(h.id)));
      if (allNowDone) {
        SoundService.playWave();
      } else {
        SoundService.playDrop();
      }
    }
    final today = _todayHabits;
    final newPct = today.isEmpty ? 0.0 :
        today.where((h) => newSet.contains(StorageService.todayKey(h.id))).length / today.length;
    _animatePct(newPct);
    if (mounted) setState(() => _completions = newSet);
  }

  List<Habit> get _todayHabits =>
      _habits.where((h) => h.isScheduledOn(DateTime.now())).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: kSeaFoam)));

    final today = _todayHabits;
    final done = today.where((h) => _completions.contains(StorageService.todayKey(h.id))).toList();
    final remaining = today.where((h) => !_completions.contains(StorageService.todayKey(h.id))).toList();
    final activeDays = ProgressionService.countActiveDays(_completions);
    final stage = ProgressionService.stageForDays(activeDays);
    final allDone = today.isNotEmpty && remaining.isEmpty;

    return Scaffold(
      body: RefreshIndicator(
        color: kSeaFoam,
        backgroundColor: kMidnightTide,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Wave header ──────────────────────────────
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: Listenable.merge([_waveCtrl, _pctAnim]),
                builder: (_, __) => _WaveHeader(
                  wavePhase: _waveCtrl.value,
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

            // ── Quote ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kMidnightTide.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kOceanBlue.withOpacity(0.3), width: 0.5),
                  ),
                  child: Row(children: [
                    const Text('💧', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dailyQuote(),
                        style: const TextStyle(
                          color: kSeaFoam, fontSize: 13,
                          fontStyle: FontStyle.italic, height: 1.4),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Habits ───────────────────────────────────
            if (today.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(onAdd: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddHabitScreen()));
                  _load();
                }),
              )
            else ...[
              if (remaining.isNotEmpty) ...[
                _sliverLabel("TODAY'S HABITS"),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _HabitCard(
                        habit: remaining[i], done: false,
                        delay: i * 60,
                        onTap: () => _toggle(remaining[i]),
                      ),
                      childCount: remaining.length,
                    ),
                  ),
                ),
              ],
              if (done.isNotEmpty) ...[
                _sliverLabel('COMPLETED ✓'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _HabitCard(
                        habit: done[i], done: true, delay: 0,
                        onTap: () => _toggle(done[i]),
                      ),
                      childCount: done.length,
                    ),
                  ),
                ),
              ],
              if (allDone)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverToBoxAdapter(child: _AllDoneCard()),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sliverLabel(String text) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    sliver: SliverToBoxAdapter(
      child: Text(text,
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 1.0, color: kSeaFoam)),
    ),
  );
}

// ── Wave header ───────────────────────────────────────────
class _WaveHeader extends StatelessWidget {
  final double wavePhase, pct;
  final int done, total, activeDays;
  final WaterStage stage;
  final bool allDone;
  final VoidCallback onAdd;

  const _WaveHeader({
    required this.wavePhase, required this.pct,
    required this.done, required this.total,
    required this.stage, required this.activeDays,
    required this.allDone, required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning'
        : hour < 17 ? 'Keep going' : 'Good evening';
    final days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}';

    return Container(
      height: 220,
      color: kDeepOcean,
      child: Stack(
        children: [
          // Wave painter fills from bottom based on pct
          Positioned.fill(
            child: CustomPaint(
              painter: _WavePainter(phase: wavePhase, fill: pct),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(dateStr,
                          style: const TextStyle(color: kSeaFoam, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(greeting,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      ]),
                      // Stage badge
                      GestureDetector(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kOceanBlue.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kSeaFoam.withOpacity(0.4)),
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
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Progress row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          total == 0 ? 'Add your first habit →'
                              : allDone ? 'All done! 🎉'
                              : '$done of $total habits done',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 180, height: 6,
                          decoration: BoxDecoration(
                            color: kOceanBlue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: allDone ? kSuccess : kSeaFoam,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ]),
                      // Pct circle
                      SizedBox(
                        width: 56, height: 56,
                        child: Stack(alignment: Alignment.center, children: [
                          CircularProgressIndicator(
                            value: pct, strokeWidth: 4,
                            backgroundColor: kOceanBlue.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation(
                                allDone ? kSuccess : kSeaFoam),
                            strokeCap: StrokeCap.round,
                          ),
                          Text('${(pct * 100).round()}%',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 13, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wave painter ──────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double phase;
  final double fill; // 0–1

  const _WavePainter({required this.phase, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final fillY = size.height * (1 - fill.clamp(0.0, 1.0));

    _drawWave(canvas, size, fillY + 12, phase, kOceanBlue.withOpacity(0.5));
    _drawWave(canvas, size, fillY + 4,  phase + 0.3, kReefBlue.withOpacity(0.45));
    _drawWave(canvas, size, fillY,       phase + 0.6, kReefBlue.withOpacity(0.35));
  }

  void _drawWave(Canvas canvas, Size size, double top,
      double phaseOffset, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, top);
    final waveH = 10.0;
    for (double x = 0; x <= size.width; x++) {
      final y = top +
          sin((x / size.width * 2 * pi) + (phaseOffset * 2 * pi)) * waveH;
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

// ── Habit card ────────────────────────────────────────────
class _HabitCard extends StatefulWidget {
  final Habit habit;
  final bool done;
  final int delay;
  final VoidCallback onTap;
  const _HabitCard({
    required this.habit, required this.done,
    required this.delay, required this.onTap,
  });
  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: widget.done ? 0.6 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.done
                  ? const Color(0xFF083348)
                  : kMidnightTide,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.done
                    ? kSuccess.withOpacity(0.3)
                    : kOceanBlue.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: kOceanBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(widget.habit.icon,
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.habit.name,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: widget.done ? kSeaFoam.withOpacity(0.7) : Colors.white,
                      decoration: widget.done ? TextDecoration.lineThrough : null,
                      decorationColor: kSeaFoam.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(widget.habit.freqLabel,
                    style: const TextStyle(fontSize: 12, color: kSeaFoam, fontWeight: FontWeight.w500)),
                ],
              )),
              const SizedBox(width: 10),
              _CheckCircle(checked: widget.done),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final bool checked;
  const _CheckCircle({required this.checked});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.elasticOut,
    width: 34, height: 34,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: checked ? kSuccess : Colors.transparent,
      border: Border.all(
        color: checked ? kSuccess : kOceanBlue,
        width: 2,
      ),
    ),
    child: checked
        ? const Icon(Icons.check, color: Colors.white, size: 18)
        : null,
  );
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
        const Text('Start your flow',
          style: TextStyle(color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Add your first habit and drop by drop\nyou\'ll build your ocean.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kSeaFoam, fontSize: 14, height: 1.5)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add First Habit',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kReefBlue, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
      Text('All done!',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: kSuccess)),
      SizedBox(height: 4),
      Text('Another drop in your ocean.\nSee you tomorrow.',
        textAlign: TextAlign.center,
        style: TextStyle(color: kSuccess, fontSize: 13, height: 1.5)),
    ]),
  );
}
