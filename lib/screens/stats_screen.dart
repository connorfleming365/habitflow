import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/progression_service.dart';
import '../theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Habit> _habits = [];
  Set<String> _completions = {};
  String? _installDate;
  int _calYear = DateTime.now().year;
  int _calMonth = DateTime.now().month - 1; // 0-indexed
  /// Incremented on every retro-edit save. Used as a ValueKey on _CalendarSection
  /// so Flutter completely recreates the widget — guaranteed fresh color render.
  int _refreshKey = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final habits      = await StorageService.loadHabits();
    final comp        = await StorageService.loadCompletions();
    final installDate = await StorageService.getInstallDate();
    if (mounted) {
      setState(() {
        _habits = habits;
        _completions = comp;
        _installDate = installDate;
      });
    }
  }

  int _streakFor(Habit h) => StorageService.getStreak(h, _completions);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _showRetroEdit(DateTime date) async {
    final todayStr = _fmt(DateTime.now());
    final dateStr  = _fmt(date);
    if (dateStr.compareTo(todayStr) > 0) return; // no future editing

    // Limit retro editing to the last 7 days to keep flow stage meaningful
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final cutoffStr = _fmt(DateTime(cutoff.year, cutoff.month, cutoff.day));
    if (dateStr.compareTo(cutoffStr) < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Editing is limited to the last 7 days')));
      }
      return;
    }

    final scheduled = _habits.where((h) => h.isScheduledOn(date)).toList();
    if (scheduled.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No habits scheduled on this day')));
      }
      return;
    }

    var tempComp = Set<String>.from(_completions);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kMidnightTide,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          const dayNames  = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
          const monNames  = ['Jan','Feb','Mar','Apr','May','Jun',
                             'Jul','Aug','Sep','Oct','Nov','Dec'];
          final label = '${dayNames[date.weekday-1]}, ${monNames[date.month-1]} ${date.day}';

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20,
                MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4,
                decoration: BoxDecoration(color: kOceanBlue,
                    borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(label,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              const Text('Tap habits to toggle completion',
                  style: TextStyle(color: kSeaFoam, fontSize: 12)),
              const SizedBox(height: 12),
              ...scheduled.map((h) {
                final key  = StorageService.completionKey(h.id, date);
                final done = tempComp.contains(key);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(h.icon, style: const TextStyle(fontSize: 22)),
                  title: Text(h.name,
                    style: TextStyle(
                      color: done ? kSuccess : Colors.white,
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                    )),
                  trailing: Icon(
                    done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: done ? kSuccess : kSeaFoam.withOpacity(0.4),
                  ),
                  onTap: () => setModal(() {
                    if (done) tempComp.remove(key);
                    else      tempComp.add(key);
                  }),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kReefBlue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await StorageService.saveCompletions(tempComp);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      // Use tempComp directly — do NOT call _load() here.
                      // Android's SharedPreferences.apply() is async; _load()
                      // would read stale data and overwrite the visual update.
                      setState(() {
                        _completions = Set<String>.from(tempComp);
                        _refreshKey++;
                      });
                    }
                  },
                  child: const Text('Save changes',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now         = DateTime.now();
    final activeDays  = ProgressionService.countActiveDays(_completions);
    final stage       = ProgressionService.stageForDays(activeDays);
    final toNext      = ProgressionService.daysToNext(activeDays);
    final stageProgress = ProgressionService.progressToNext(activeDays);
    final weekStats   = StorageService.weekStats(_habits, _completions);
    final weekPct     = weekStats.total == 0 ? 0.0
        : weekStats.done / weekStats.total;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(
        color: kSeaFoam,
        backgroundColor: kMidnightTide,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [

            // ── Stage card ────────────────────────────
            _StageCard(
              stage: stage,
              activeDays: activeDays,
              toNext: toNext,
              stageProgress: stageProgress,
            ),
            const SizedBox(height: 16),

            // ── Quick stats row ───────────────────────
            Row(children: [
              Expanded(child: _StatChip(
                label: 'Active days',
                value: '$activeDays',
                icon: '💧',
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatChip(
                label: 'This week',
                value: '${(weekPct * 100).round()}%',
                icon: '📅',
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatChip(
                label: 'Habits tracked',
                value: '${_habits.length}',
                icon: '🌊',
              )),
            ]),
            const SizedBox(height: 20),

            // ── Calendar heatmap ──────────────────────
            _CalendarSection(
              key: ValueKey(_refreshKey),
              habits: _habits,
              completions: _completions,
              year: _calYear,
              month: _calMonth,
              installDate: _installDate,
              onDayTap: _showRetroEdit,
              onPrev: () => setState(() {
                if (_calMonth == 0) { _calYear--; _calMonth = 11; }
                else _calMonth--;
              }),
              onNext: () => setState(() {
                if (_calMonth == 11) { _calYear++; _calMonth = 0; }
                else _calMonth++;
              }),
            ),
            const SizedBox(height: 20),

            // ── Per-habit streaks ─────────────────────
            if (_habits.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('HABIT STREAKS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 1.0, color: kSeaFoam)),
              ),
              ..._habits.map((h) => _StreakRow(
                habit: h,
                streak: _streakFor(h),
                maxStreak: _habits.map(_streakFor).fold(1, (a, b) => a > b ? a : b),
              )),
              const SizedBox(height: 24),
            ],

            // ── Per-habit day strips ──────────────────
            if (_habits.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('HABIT HISTORY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 1.0, color: kSeaFoam)),
              ),
              ..._habits.map((h) => _HabitDayStrip(
                habit: h,
                completions: _completions,
                installDate: _installDate,
              )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Stage card ────────────────────────────────────────────
class _StageCard extends StatelessWidget {
  final WaterStage stage;
  final int activeDays, toNext;
  final double stageProgress;
  const _StageCard({
    required this.stage, required this.activeDays,
    required this.toNext, required this.stageProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isOcean = stage == WaterStage.ocean;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kMidnightTide,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kReefBlue.withOpacity(0.5), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(ProgressionService.stageEmoji(stage),
            style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your flow',
              style: const TextStyle(color: kSeaFoam, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            Text(ProgressionService.stageName(stage),
              style: const TextStyle(color: Colors.white,
                  fontSize: 22, fontWeight: FontWeight.w800)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kOceanBlue.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Day $activeDays',
              style: const TextStyle(color: kSeaFoam,
                  fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(ProgressionService.stageDescription(stage),
          style: const TextStyle(color: kSeaFoam, fontSize: 13, height: 1.4)),
        if (!isOcean) ...[
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$toNext consistent days to ${ProgressionService.stageName(WaterStage.values[stage.index + 1])}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('${(stageProgress * 100).round()}%',
              style: const TextStyle(color: kSeaFoam, fontSize: 12,
                  fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stageProgress,
              minHeight: 8,
              backgroundColor: kOceanBlue.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(kReefBlue),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value, icon;
  const _StatChip({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF083348),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kOceanBlue.withOpacity(0.3), width: 0.5),
    ),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(value,
        style: const TextStyle(color: Colors.white,
            fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, textAlign: TextAlign.center,
        style: const TextStyle(color: kSeaFoam, fontSize: 10)),
    ]),
  );
}

// ── Calendar heatmap ──────────────────────────────────────
class _CalendarSection extends StatefulWidget {
  final List<Habit> habits;
  final Set<String> completions;
  final int year, month;
  final String? installDate;
  final void Function(DateTime) onDayTap;
  final VoidCallback onPrev, onNext;

  const _CalendarSection({
    super.key,
    required this.habits, required this.completions,
    required this.year, required this.month,
    this.installDate,
    required this.onDayTap,
    required this.onPrev, required this.onNext,
  });

  @override
  State<_CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<_CalendarSection> {
  bool _graphView = false; // false = Calendar (single month), true = Graph (heatmap)
  final _graphScrollCtrl = ScrollController();

  @override
  void dispose() {
    _graphScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollGraphToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_graphScrollCtrl.hasClients) {
        _graphScrollCtrl.jumpTo(_graphScrollCtrl.position.maxScrollExtent);
      }
    });
  }

  static const _monthNames = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];
  static const _monthShort = ['Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];
  static const _dayLabels = ['M','T','W','T','F','S','S'];

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Color _dayColor(DateTime date, String todayStr, String? installDate) {
    final ds = _dateKey(date);
    final isFuture    = ds.compareTo(todayStr) > 0;
    final isPreInstall = installDate != null && ds.compareTo(installDate) < 0;
    final scheduled = widget.habits.where((h) => h.isScheduledOn(date)).toList();
    final done = scheduled.where((h) =>
        widget.completions.contains(StorageService.completionKey(h.id, date))).length;
    final isPerfect  = !isFuture && !isPreInstall && scheduled.isNotEmpty && done == scheduled.length;
    final hasPartial = !isFuture && !isPreInstall && done > 0 && done < scheduled.length;

    if (isFuture || isPreInstall) return kOceanBlue.withOpacity(0.1);
    if (isPerfect)                return kSuccess;
    if (hasPartial)               return kWarning;
    if (scheduled.isEmpty)        return kOceanBlue.withOpacity(0.2);
    return kDanger.withOpacity(0.6);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kMidnightTide,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOceanBlue.withOpacity(0.3), width: 0.5),
      ),
      child: Column(children: [
        // Header row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _graphView
              ? const SizedBox(width: 40)
              : IconButton(
                  onPressed: widget.onPrev,
                  icon: const Icon(Icons.chevron_left, color: kSeaFoam)),
          Text(
            _graphView
                ? 'Graph View'
                : '${_monthNames[widget.month]} ${widget.year}',
            style: const TextStyle(color: Colors.white,
                fontSize: 15, fontWeight: FontWeight.w700)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (!_graphView)
              IconButton(
                  onPressed: widget.onNext,
                  icon: const Icon(Icons.chevron_right, color: kSeaFoam)),
            GestureDetector(
              onTap: () {
                setState(() => _graphView = !_graphView);
                if (_graphView) _scrollGraphToEnd();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kOceanBlue.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_graphView ? '← Calendar' : '📊 Graph',
                  style: const TextStyle(color: kSeaFoam,
                      fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 8),
        if (_graphView) _buildGraphView() else _buildMonthView(),
        const SizedBox(height: 12),
        // Legend
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _dot(kSuccess), const SizedBox(width: 4),
          const Text('All done', style: TextStyle(color: kSeaFoam, fontSize: 10)),
          const SizedBox(width: 12),
          _dot(kWarning), const SizedBox(width: 4),
          const Text('Partial', style: TextStyle(color: kSeaFoam, fontSize: 10)),
          const SizedBox(width: 12),
          _dot(kDanger, opacity: 0.6), const SizedBox(width: 4),
          const Text('Missed', style: TextStyle(color: kSeaFoam, fontSize: 10)),
          const SizedBox(width: 8),
          const Text('← Tap a day to edit',
            style: TextStyle(color: kSeaFoam, fontSize: 9,
                fontStyle: FontStyle.italic)),
        ]),
      ]),
    );
  }

  // ── Calendar View: single month with navigation ──────────
  Widget _buildMonthView() {
    final todayStr    = _dateKey(DateTime.now());
    final firstDay    = DateTime(widget.year, widget.month + 1, 1);
    final daysInMonth = DateTime(widget.year, widget.month + 2, 0).day;
    final startOffset = (firstDay.weekday - 1) % 7;

    return Column(children: [
      // Day-of-week header
      Row(children: _dayLabels.map((d) => Expanded(
        child: Center(child: Text(d,
          style: const TextStyle(color: kSeaFoam,
              fontSize: 10, fontWeight: FontWeight.w600))),
      )).toList()),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: startOffset + daysInMonth,
        itemBuilder: (_, idx) {
          if (idx < startOffset) return const SizedBox();
          final day  = idx - startOffset + 1;
          final date = DateTime(widget.year, widget.month + 1, day);
          final ds   = _dateKey(date);
          final isToday  = ds == todayStr;
          final isFuture = ds.compareTo(todayStr) > 0;
          final color    = _dayColor(date, todayStr, widget.installDate);
          final isPerfect  = color == kSuccess;
          final hasPartial = color == kWarning;

          return GestureDetector(
            onTap: isFuture ? null : () => widget.onDayTap(date),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: kSeaFoam, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text('$day',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                    color: isFuture ? kOceanBlue.withOpacity(0.3)
                        : isPerfect || hasPartial ? kDeepOcean
                        : Colors.white70,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }

  // ── Graph View: per-habit heatmap with frozen names ───────
  Widget _buildGraphView() {
    final todayStr  = _dateKey(DateTime.now());
    final today     = DateTime.now();
    const days      = 90;
    const cellSize  = 10.0;
    const cellGap   = 2.0;
    const nameWidth = 88.0;
    const rowHeight = 15.0;   // cellSize + bottom padding
    const headerH   = 27.0;   // month row + day-num row + gap

    final dates  = List.generate(days, (i) => today.subtract(Duration(days: days - 1 - i)));
    final habits = widget.habits;

    if (habits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('Add habits to see your graph',
              style: TextStyle(color: kSeaFoam, fontSize: 12))),
      );
    }

    _scrollGraphToEnd();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Frozen left: spacer + habit names ────────────
        SizedBox(
          width: nameWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spacer matching header rows height
              const SizedBox(height: headerH),
              ...habits.map((h) => SizedBox(
                height: rowHeight,
                child: Row(
                  children: [
                    Text(h.icon, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(h.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),

        // ── Scrollable right: headers + cell grid ────────
        Expanded(
          child: SingleChildScrollView(
            controller: _graphScrollCtrl,
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Month labels
                Row(children: dates.map((date) {
                  final show = date.day == 1 || date == dates.first;
                  return SizedBox(
                    width: cellSize + cellGap,
                    child: show
                        ? Text(_monthShort[date.month - 1],
                            style: const TextStyle(color: kReefBlue,
                                fontSize: 7, fontWeight: FontWeight.w700))
                        : null,
                  );
                }).toList()),

                // Day-of-month numbers every 5th
                Row(children: dates.map((date) {
                  final show = date.day % 5 == 0;
                  return SizedBox(
                    width: cellSize + cellGap,
                    child: show
                        ? Text('${date.day}',
                            style: const TextStyle(color: kSeaFoam, fontSize: 6))
                        : null,
                  );
                }).toList()),
                const SizedBox(height: 5),

                // One row of cells per habit
                ...habits.map((habit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: dates.map((date) {
                        final ds         = _dateKey(date);
                        final isFuture   = ds.compareTo(todayStr) > 0;
                        final isToday    = ds == todayStr;
                        final isPreInstall = widget.installDate != null &&
                            ds.compareTo(widget.installDate!) < 0;
                        final scheduled  = habit.isScheduledOn(date);
                        final done       = widget.completions.contains(
                            StorageService.completionKey(habit.id, date));

                        Color color;
                        if (!scheduled || isPreInstall || isFuture) {
                          color = kOceanBlue.withOpacity(0.08);
                        } else if (done) {
                          color = kSuccess;
                        } else {
                          color = kDanger.withOpacity(0.6);
                        }

                        return GestureDetector(
                          onTap: (isFuture || isPreInstall)
                              ? null
                              : () => widget.onDayTap(date),
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            margin: const EdgeInsets.symmetric(horizontal: cellGap / 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                              border: isToday
                                  ? Border.all(color: kSeaFoam, width: 1)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color c, {double opacity = 1}) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(
      color: c.withOpacity(opacity),
      shape: BoxShape.circle,
    ),
  );
}

// ── Streak row ────────────────────────────────────────────
class _StreakRow extends StatelessWidget {
  final Habit habit;
  final int streak, maxStreak;
  const _StreakRow({required this.habit, required this.streak, required this.maxStreak});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF083348),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kOceanBlue.withOpacity(0.25), width: 0.5),
    ),
    child: Row(children: [
      Text(habit.icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(habit.name,
          style: const TextStyle(color: Colors.white,
              fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: maxStreak == 0 ? 0 : streak / maxStreak,
            minHeight: 6,
            backgroundColor: kOceanBlue.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(kReefBlue),
          ),
        ),
      ])),
      const SizedBox(width: 12),
      Text(streak > 0 ? '${streak}d 🔥' : '—',
        style: TextStyle(
          color: streak > 0 ? kWarning : kSeaFoam.withOpacity(0.4),
          fontSize: 12, fontWeight: FontWeight.w700)),
    ]),
  );
}

// ── Per-habit scrollable day strip ───────────────────────
class _HabitDayStrip extends StatefulWidget {
  final Habit habit;
  final Set<String> completions;
  final String? installDate;

  const _HabitDayStrip({
    required this.habit,
    required this.completions,
    this.installDate,
  });

  @override
  State<_HabitDayStrip> createState() => _HabitDayStripState();
}

class _HabitDayStripState extends State<_HabitDayStrip> {
  final _scrollCtrl = ScrollController();

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    // Scroll to today (rightmost) after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const days = 60;
    final dates = List.generate(days,
        (i) => today.subtract(Duration(days: days - 1 - i)));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF083348),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOceanBlue.withOpacity(0.25), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(widget.habit.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(widget.habit.name,
              style: const TextStyle(color: Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const Text('← swipe',
            style: TextStyle(color: kSeaFoam, fontSize: 9,
                fontStyle: FontStyle.italic)),
        ]),
        const SizedBox(height: 10),
        // Scrollable day strip — oldest to newest (left=oldest, right=today)
        // Each column: day-of-week letter → dot with date number
        SizedBox(
          height: 52,
          child: ListView.builder(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (_, i) {
              final date = dates[i];
              final ds = _fmt(date);
              final isToday = ds == _fmt(today);
              final isPreInstall = widget.installDate != null &&
                  ds.compareTo(widget.installDate!) < 0;
              final scheduled = widget.habit.isScheduledOn(date);
              final done = widget.completions.contains(
                  StorageService.completionKey(widget.habit.id, date));

              Color dotColor;
              if (isPreInstall || !scheduled) {
                dotColor = kOceanBlue.withOpacity(0.1);
              } else if (done) {
                dotColor = kSuccess;
              } else {
                dotColor = kDanger.withOpacity(0.55);
              }

              const dayLetters = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
              final dayLetter = dayLetters[date.weekday - 1];
              final isMonday = date.weekday == 1;
              // Show month label at month boundary or start
              const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
                  'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              final showMonth = date.day == 1 || i == 0;

              return SizedBox(
                width: 28,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Day-of-week letter
                    Text(
                      showMonth ? months[date.month] : dayLetter,
                      style: TextStyle(
                        color: showMonth
                            ? kReefBlue
                            : isToday
                                ? kSeaFoam
                                : kSeaFoam.withOpacity(0.45),
                        fontSize: 7,
                        fontWeight: showMonth || isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Dot with date number inside
                    Container(
                      width: isToday ? 24 : 22,
                      height: isToday ? 24 : 22,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: kSeaFoam, width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: isToday
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: (isPreInstall || !scheduled)
                              ? kSeaFoam.withOpacity(0.3)
                              : done
                                  ? kDeepOcean
                                  : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
