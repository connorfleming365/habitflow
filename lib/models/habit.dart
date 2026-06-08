import 'dart:convert';

class Habit {
  final String id;
  final String name;
  final String icon;
  final String color; // hex string e.g. '#7C6AF7'
  final String freq;  // daily | weekdays | weekends | weekly6 | weekly5 | weekly4 | weekly3 | weekly2 | weekly1 | custom
  final List<int> days; // 0=Sun..6=Sat for custom
  final String reminderTime; // 'HH:mm' or ''
  final String amPm; // '' | 'am' | 'pm'
  final int createdAt;

  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.freq,
    required this.days,
    required this.reminderTime,
    this.amPm = '',
    required this.createdAt,
  });

  Habit copyWith({
    String? name,
    String? icon,
    String? color,
    String? freq,
    List<int>? days,
    String? reminderTime,
    String? amPm,
  }) => Habit(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    freq: freq ?? this.freq,
    days: days ?? this.days,
    reminderTime: reminderTime ?? this.reminderTime,
    amPm: amPm ?? this.amPm,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'icon': icon, 'color': color,
    'freq': freq, 'days': days, 'reminderTime': reminderTime,
    'amPm': amPm, 'createdAt': createdAt,
  };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
    id: j['id'], name: j['name'], icon: j['icon'], color: j['color'],
    freq: j['freq'], days: List<int>.from(j['days'] ?? []),
    reminderTime: j['reminderTime'] ?? '',
    amPm: j['amPm'] ?? '',
    createdAt: j['createdAt'] ?? 0,
  );

  String get freqLabel {
    switch (freq) {
      case 'daily':    return 'Every day';
      case 'weekdays': return 'Weekdays';
      case 'weekends': return 'Weekends';
      case 'weekly6':  return '6× per week';
      case 'weekly5':  return '5× per week';
      case 'weekly4':  return '4× per week';
      case 'weekly3':  return '3× per week';
      case 'weekly2':  return '2× per week';
      case 'weekly1':  return '1× per week';
      case 'custom':   return 'Custom days';
      default:         return freq;
    }
  }

  bool isScheduledOn(DateTime date) {
    final dow = date.weekday % 7; // 0=Sun,1=Mon...6=Sat
    switch (freq) {
      case 'daily':    return true;
      case 'weekdays': return dow >= 1 && dow <= 5;
      case 'weekends': return dow == 0 || dow == 6;
      case 'weekly6':  return true;
      case 'weekly5':  return true;
      case 'weekly4':  return true;
      case 'weekly3':  return true;
      case 'weekly2':  return true;
      case 'weekly1':  return true;
      case 'custom':   return days.contains(dow);
      default:         return true;
    }
  }

  static String encode(List<Habit> habits) =>
      jsonEncode(habits.map((h) => h.toJson()).toList());

  static List<Habit> decode(String s) {
    try {
      return (jsonDecode(s) as List).map((e) => Habit.fromJson(e)).toList();
    } catch (_) { return []; }
  }
}

// Preset habits
const List<Map<String, String>> kPresets = [
  {'name': 'Drink Water',     'icon': '💧', 'color': '#4FC3F7', 'freq': 'daily'},
  {'name': 'Exercise',        'icon': '🏋️', 'color': '#EF5350', 'freq': 'daily'},
  {'name': 'Meditate',        'icon': '🧘', 'color': '#AB47BC', 'freq': 'daily'},
  {'name': 'Read',            'icon': '📖', 'color': '#FF8A65', 'freq': 'daily'},
  {'name': 'Journal',         'icon': '📝', 'color': '#A5D6A7', 'freq': 'daily'},
  {'name': 'Sleep 8 Hours',   'icon': '😴', 'color': '#5C6BC0', 'freq': 'daily'},
  {'name': 'Walk 10k Steps',  'icon': '🚶', 'color': '#66BB6A', 'freq': 'daily'},
  {'name': 'Vitamins',        'icon': '💊', 'color': '#FFA726', 'freq': 'daily'},
  {'name': 'No Social Media', 'icon': '📵', 'color': '#EF5350', 'freq': 'daily'},
  {'name': 'Gratitude',       'icon': '🙏', 'color': '#FFCC02', 'freq': 'daily'},
  {'name': 'Cold Shower',     'icon': '🚿', 'color': '#29B6F6', 'freq': 'daily'},
  {'name': 'Cook at Home',    'icon': '🍳', 'color': '#FFA726', 'freq': 'daily'},
  {'name': 'Stretch',         'icon': '🤸', 'color': '#EC407A', 'freq': 'daily'},
  {'name': 'No Alcohol',      'icon': '🚫', 'color': '#8D6E63', 'freq': 'daily'},
  {'name': 'Gym',             'icon': '💪', 'color': '#FF7043', 'freq': 'weekly3'},
  {'name': 'Learn Language',  'icon': '🗣️', 'color': '#26C6DA', 'freq': 'daily'},
];

const List<String> kEmojis = [
  '💧','🏋️','🧘','📖','📝','😴','🚶','💊','📵','🙏','🚿','🍳',
  '🎯','🔥','⚡','🌟','🌱','🏃','🚴','🧠','❤️','🌅','☀️','🌙',
  '✨','🎵','🎨','💻','📚','🏊','🧩','🍎','🥗','☕','💪','🤸',
];

const List<String> kColors = [
  '#7C6AF7','#4FC3F7','#EF5350','#66BB6A','#FFA726','#AB47BC',
  '#FF8A65','#26C6DA','#EC407A','#5C6BC0','#A5D6A7','#FFCC02',
];
