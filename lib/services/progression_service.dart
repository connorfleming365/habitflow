/// Water progression system.
/// Overall consistency (days with ≥1 habit done) drives the stage.
library;

enum WaterStage {
  drop,   // day 1–6
  puddle, // day 7–20
  spring, // day 21–44
  stream, // day 45–89
  tide,   // day 90–179
  ocean,  // day 180+
}

class ProgressionService {
  static const _stageDays = [0, 7, 21, 45, 90, 180];
  static const _stageNames = ['Drop', 'Puddle', 'Spring', 'Stream', 'Tide', 'Ocean'];
  static const _stageEmojis = ['💧', '💦', '🌱', '🌊', '🏄', '🌅'];
  static const _stageDescriptions = [
    'Every ocean starts with a single drop.\nComplete your daily habits to grow your flow.',
    'Your drops are forming a puddle. Something real is beginning.',
    'Three weeks in — your habits are springing to life.\nThis is where change becomes real.',
    'Six weeks of flow. You\'re a stream of consistent action.\nKeep the momentum going.',
    'Three months. You\'re riding the tide now.\nThe ocean is within reach — don\'t stop.',
    'You\'ve reached the ocean. You are the tide.\nKeep up your incredible work.',
  ];

  /// Count how many distinct days had at least one completion.
  static int countActiveDays(Set<String> completions) {
    final days = <String>{};
    for (final key in completions) {
      // keys are like "habitId_2025-05-29"
      final parts = key.split('_');
      if (parts.length >= 2) days.add(parts.last);
    }
    return days.length;
  }

  static WaterStage stageForDays(int days) {
    if (days >= 180) return WaterStage.ocean;
    if (days >= 90)  return WaterStage.tide;
    if (days >= 45)  return WaterStage.stream;
    if (days >= 21)  return WaterStage.spring;
    if (days >= 7)   return WaterStage.puddle;
    return WaterStage.drop;
  }

  static String stageName(WaterStage s)        => _stageNames[s.index];
  static String stageEmoji(WaterStage s)       => _stageEmojis[s.index];
  static String stageDescription(WaterStage s) => _stageDescriptions[s.index];

  /// Days until next stage (0 if at ocean).
  static int daysToNext(int days) {
    for (final threshold in _stageDays) {
      if (days < threshold) return threshold - days;
    }
    return 0;
  }

  static int nextThreshold(int days) {
    for (final threshold in _stageDays) {
      if (days < threshold) return threshold;
    }
    return _stageDays.last;
  }

  /// 0.0–1.0 progress within current stage toward next.
  static double progressToNext(int days) {
    final stage = stageForDays(days);
    if (stage == WaterStage.ocean) return 1.0;
    final start = _stageDays[stage.index];
    final end   = _stageDays[stage.index + 1];
    return (days - start) / (end - start);
  }

  /// Milestone day thresholds
  static const milestones = [7, 21, 45, 90, 180];

  static String milestoneTitle(int days) {
    switch (days) {
      case 7:   return 'First Week! 💦';
      case 21:  return 'Three Weeks! 🌱';
      case 45:  return 'Six Weeks! 🌊';
      case 90:  return 'Three Months! 🏄';
      case 180: return 'Half a Year! 🌅';
      default:  return 'Milestone! 💧';
    }
  }

  static String milestoneMessage(int days) {
    switch (days) {
      case 7:   return 'Seven days of showing up. Your drops\nare becoming a puddle. That\'s real.';
      case 21:  return 'Three weeks in. Your habits are\nspringing to life. Keep going.';
      case 45:  return 'Six weeks of consistent action.\nYou\'re a flowing stream now.';
      case 90:  return 'Three months. You\'re riding the tide.\nThe ocean is within reach.';
      case 180: return 'Half a year. You didn\'t just build habits —\nyou became the ocean.';
      default:  return 'Keep flowing.';
    }
  }
}

// ── Daily motivational quotes (flow / water themed) ──────
const _quotes = [
  'Small drops carve the deepest canyons.',
  'Water does not force its way; it finds it.',
  'Every river starts as a single raindrop.',
  'The ocean refuses no river.',
  'Flow around obstacles, not against them.',
  'Consistency is the current that carries you forward.',
  'A river cuts through rock not by force, but persistence.',
  'Your habits are the tide. Show up daily.',
  'Still water runs deep. So do steady habits.',
  'The best time to plant a habit was yesterday. The next best time is now.',
  'Like water, take the shape of your best self each day.',
  'Even the smallest stream reaches the sea.',
  'Progress flows; it doesn\'t leap.',
  'Be like water: flexible, persistent, unstoppable.',
  'One drop today. One drop tomorrow. An ocean eventually.',
  'The river that knows its destination does not stop.',
  'Your potential is as deep as the ocean.',
  'Depth is built one fathom at a time.',
  'Calm water reflects clearly. A calm habit reflects clearly too.',
  'Flow is found in the doing, not the thinking.',
  'Let today\'s effort flow into tomorrow\'s strength.',
  'Waves look wild, but they move in a constant rhythm.',
  'The tide waits for no one, but it always returns.',
  'Every habit is a tributary feeding your greater river.',
  'Water carves its path by showing up every single day.',
  'Stay fluid. Adapt. Keep moving forward.',
  'The deepest oceans were once just scattered raindrops.',
  'Your streak is a current — keep it flowing.',
  'Small actions, done daily, become the ocean.',
  'You are further along than yesterday\'s shore.',
  'Let your habits flow like water — effortless and relentless.',
];

String dailyQuote() {
  final day = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
  return _quotes[day % _quotes.length];
}
