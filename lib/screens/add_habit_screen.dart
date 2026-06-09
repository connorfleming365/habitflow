import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? existing;
  const AddHabitScreen({super.key, this.existing});
  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameCtrl = TextEditingController();
  String _icon = '⭐';
  String _color = '#7C6AF7';
  String _freq = 'daily';
  List<int> _days = [1,2,3,4,5];
  String _amPm = '';
  int _targetCount = 1;
  TimeOfDay? _reminderTime;
  bool _showPresets = true;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final h = widget.existing!;
      _nameCtrl.text = h.name;
      _icon = h.icon; _color = h.color; _freq = h.freq; _days = h.days;
      _amPm = h.amPm; _targetCount = h.targetCount;
      _showPresets = false;
      if (h.reminderTime.isNotEmpty) {
        final p = h.reminderTime.split(':');
        _reminderTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
    }
  }
  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')));
      return;
    }
    final reminderStr = _reminderTime == null ? ''
        : '${_reminderTime!.hour.toString().padLeft(2,'0')}:${_reminderTime!.minute.toString().padLeft(2,'0')}';
    final habits = await StorageService.loadHabits();
    if (widget.existing != null) {
      final idx = habits.indexWhere((h) => h.id == widget.existing!.id);
      if (idx != -1) {
        habits[idx] = widget.existing!.copyWith(
          name: name, icon: _icon, color: _color, freq: _freq,
          days: _days, reminderTime: reminderStr, amPm: _amPm,
          targetCount: _targetCount,
        );
      }
    } else {
      habits.add(Habit(
        id: const Uuid().v4(), name: name, icon: _icon, color: _color,
        freq: _freq, days: _days, reminderTime: reminderStr, amPm: _amPm,
        targetCount: _targetCount,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    await StorageService.saveHabits(habits);
    try {
      final completions = await StorageService.loadCompletions();
      await WidgetService.update(habits, completions);
      await NotificationService.scheduleAll(habits);
    } catch (_) {
      // non-fatal — notifications or widget may fail; still pop
    }
    if (mounted) Navigator.pop(context, true);
  }

  void _applyPreset(Map<String, String> p) {
    setState(() {
      _nameCtrl.text = p['name']!;
      _icon = p['icon']!;
      _color = p['color']!;
      _freq = p['freq']!;
      _showPresets = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Habit' : 'Edit Habit'),
        actions: [
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white,
            ),
            child: Text(widget.existing == null ? 'Add' : 'Save',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Presets ──────────────────────────────────
          if (_showPresets) ...[
            _label('⚡ QUICK PRESETS'),
            const SizedBox(height: 8),
            FutureBuilder<List<Habit>>(
              future: StorageService.loadHabits(),
              builder: (ctx, snap) {
                final existing = snap.data?.map((h) => h.name.toLowerCase()).toSet() ?? {};
                final available = kPresets.where((p) => !existing.contains(p['name']!.toLowerCase())).toList();
                return Wrap(
                  spacing: 8, runSpacing: 8,
                  children: available.map((p) => GestureDetector(
                    onTap: () => _applyPreset(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(p['icon']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(p['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR BUILD YOUR OWN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Name ─────────────────────────────────────
          _label('HABIT NAME'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            maxLength: 40,
            decoration: InputDecoration(
              hintText: 'e.g. Morning run',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kPrimary, width: 2),
              ),
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),

          // ── Emoji ─────────────────────────────────────
          _label('ICON'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: cardDecoration(context),
            child: GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1,
              ),
              itemCount: kEmojis.length,
              itemBuilder: (_, i) {
                final e = kEmojis[i];
                return GestureDetector(
                  onTap: () => setState(() => _icon = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: e == _icon ? kPrimary.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: e == _icon ? kPrimary : Colors.transparent, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── Colour ────────────────────────────────────
          _label('COLOUR'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: kColors.map((c) {
              final col = hexColor(c);
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: col, shape: BoxShape.circle,
                    border: Border.all(
                      color: c == _color ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: c == _color ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 8)] : [],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Frequency ─────────────────────────────────
          _label('FREQUENCY'),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              // Row 1: specific day patterns
              _FreqChip(id:'daily',    label:'Every Day', icon:'🗓️', selected:_freq, onTap:(v)=>setState(()=>_freq=v)),
              _FreqChip(id:'weekdays', label:'Weekdays',  icon:'💼', selected:_freq, onTap:(v)=>setState(()=>_freq=v)),
              _FreqChip(id:'weekends', label:'Weekends',  icon:'🌅', selected:_freq, onTap:(v)=>setState(()=>_freq=v)),
              // Row 2: high weekly frequency
              _FreqChip(id:'weekly6',  label:'6×/week',   icon:'🔥', selected:_freq, onTap:(v)=>setState(()=>_freq=v)),
              _FreqChip(id:'weekly5',  label:'5×/week',   icon:'⚡', selected:_freq, onTap:(v)=>setState(()=>_freq=v)),
              _FreqChip(id:'weekly4',  label:'4×/week',   icon:'🔁', selected:_freq, onTap:(v)=>setState(()=>_freq=v)),
              // Row 3: lower weekly frequency
              _FreqChip(id:'weekly3',  label:'3×/week',   icon:'🔁', selected:_freq, onTap:(v)=>setState(()=>_freq=v)),
              _FreqChip(id:'weekly2',  label:'2×/week',   icon:'🔁', selected:_freq, onTap:(v)=>setState(()=>_freq=v)),
              _FreqChip(id:'weekly1',  label:'1×/week',   icon:'🌱', selected:_freq, onTap:(v)=>setState(()=>_freq=v)),
              // Row 4: custom
              _FreqChip(id:'custom',   label:'Custom',    icon:'⚙️', selected:_freq, onTap:(v)=>setState((){_freq=v;})),
            ],
          ),
          const SizedBox(height: 12),

          // ── Custom days ───────────────────────────────
          if (_freq == 'custom') ...[
            _label('WHICH DAYS?'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (i) {
                const names = ['Su','Mo','Tu','We','Th','Fr','Sa'];
                final sel = _days.contains(i);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (sel) _days.remove(i); else _days.add(i);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? kPrimary : Theme.of(context).dividerColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(names[i],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],

          // ── Daily target (multi-count) ───────────────
          _label('DAILY TARGET'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: cardDecoration(context),
            child: Row(children: [
              // Minus
              _StepperButton(
                icon: Icons.remove_rounded,
                enabled: _targetCount > 1,
                onTap: () => setState(() { if (_targetCount > 1) _targetCount--; }),
              ),
              // Count display
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$_targetCount',
                    style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                  Text(
                    _targetCount == 1 ? 'tap to complete' : 'taps to complete',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                    )),
                ]),
              ),
              // Plus
              _StepperButton(
                icon: Icons.add_rounded,
                enabled: _targetCount < 10,
                onTap: () => setState(() { if (_targetCount < 10) _targetCount++; }),
              ),
            ]),
          ),
          if (_targetCount > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                'Tap this habit $_targetCount times on the Today screen to mark it complete.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          const SizedBox(height: 20),

          // ── Time of day ───────────────────────────────
          _label('TIME OF DAY'),
          const SizedBox(height: 8),
          Row(children: [
            _TimeChip(id: 'am',        label: 'Morning',   emoji: '☀️', selected: _amPm, onTap: (v) => setState(() => _amPm = _amPm == v ? '' : v)),
            const SizedBox(width: 8),
            _TimeChip(id: 'afternoon', label: 'Afternoon', emoji: '🌤️', selected: _amPm, onTap: (v) => setState(() => _amPm = _amPm == v ? '' : v)),
            const SizedBox(width: 8),
            _TimeChip(id: 'pm',        label: 'Evening',   emoji: '🌙', selected: _amPm, onTap: (v) => setState(() => _amPm = _amPm == v ? '' : v)),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              _amPm.isEmpty ? 'No preference — shows in its own section' : 'Tap again to clear',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            ),
          ),
          const SizedBox(height: 20),

          // ── Reminder ──────────────────────────────────
          _label('DAILY REMINDER (optional)'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
              );
              if (t != null) setState(() => _reminderTime = t);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(context),
              child: Row(children: [
                const Icon(Icons.alarm, color: kPrimary),
                const SizedBox(width: 12),
                Text(
                  _reminderTime == null ? 'Tap to set reminder time'
                      : _reminderTime!.format(context),
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: _reminderTime == null
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (_reminderTime != null)
                  GestureDetector(
                    onTap: () => setState(() => _reminderTime = null),
                    child: Icon(Icons.close, size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 32),

          // ── Save button ───────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: Text(widget.existing == null ? 'Add Habit' : 'Save Changes'),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)));
}

class _TimeChip extends StatelessWidget {
  final String id, label, emoji, selected;
  final void Function(String) onTap;
  const _TimeChip({required this.id, required this.label, required this.emoji,
    required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sel = id == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? kPrimary.withOpacity(0.12) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? kPrimary : Theme.of(context).dividerColor,
              width: sel ? 2 : 1,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: sel ? kPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              )),
          ]),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final col = enabled
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.2);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44, height: 44,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? kPrimary.withOpacity(0.10) : Colors.transparent,
          border: Border.all(color: col, width: 1.5),
        ),
        child: Icon(icon, color: col, size: 20),
      ),
    );
  }
}

class _FreqChip extends StatelessWidget {
  final String id, label, icon, selected;
  final void Function(String) onTap;
  const _FreqChip({required this.id, required this.label, required this.icon,
    required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sel = id == selected;
    return GestureDetector(
      onTap: () => onTap(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: sel ? kPrimary.withOpacity(0.12) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? kPrimary : Theme.of(context).dividerColor, width: sel ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text('$icon $label',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: sel ? kPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ),
    );
  }
}
