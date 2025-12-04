// lib/todo/todo_data.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class TodoHive {
  String id;
  String title;
  String? description;
  bool isDone;
  DateTime createdAt;
  // start and end stored as "HH:mm"
  String startTime;
  String endTime;
  // repeatType: 'none' | 'daily' | 'weekly'
  String repeatType;
  // weekdays: List<int> with 1 = Monday ... 7 = Sunday
  List<int> weekdays;

  TodoHive({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.isDone = false,
    DateTime? createdAt,
    this.repeatType = 'none',
    List<int>? weekdays,
  }) : createdAt = createdAt ?? DateTime.now(),
       weekdays = weekdays ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'startTime': startTime,
    'endTime': endTime,
    'repeatType': repeatType,
    'weekdays': weekdays,
  };

  static TodoHive fromMap(Map m) {
    return TodoHive(
      id: m['id']?.toString() ?? const Uuid().v4(),
      title: m['title']?.toString() ?? '',
      description: m['description']?.toString(),
      isDone: m['isDone'] == true,
      createdAt:
          DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
      startTime: m['startTime']?.toString() ?? '09:00',
      endTime: m['endTime']?.toString() ?? '10:00',
      repeatType: m['repeatType']?.toString() ?? 'none',
      weekdays: (m['weekdays'] is List)
          ? List<int>.from(
              (m['weekdays'] as List)
                  .map((e) => int.tryParse(e.toString()) ?? 0)
                  .where((v) => v >= 1 && v <= 7),
            )
          : <int>[],
    );
  }

  /// Duration in minutes
  int get durationMinutes {
    final s = _parse(startTime);
    final e = _parse(endTime);
    return e.difference(s).inMinutes;
  }

  static DateTime _parse(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }
}

class TodoData {
  static const _boxName = 'todo_box';
  final Uuid _uuid = const Uuid();
  static final TodoData _instance = TodoData._internal();
  factory TodoData() => _instance;
  TodoData._internal();

  Box? _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    try {
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      // try recreate if open failed
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
    }
    _initialized = true;
  }

  List<TodoHive> get todos {
    if (_box == null) return [];
    final out = <TodoHive>[];
    for (final v in _box!.values) {
      try {
        if (v is Map) {
          out.add(TodoHive.fromMap(Map<String, dynamic>.from(v)));
        } else if (v is TodoHive) {
          out.add(v);
        } else {
          out.add(TodoHive.fromMap(Map<String, dynamic>.from(v as dynamic)));
        }
      } catch (_) {
        // skip bad entries
      }
    }
    // older first
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  Future<TodoHive> addTodo({
    required String title,
    required String startTime, // "HH:mm"
    required String endTime, // "HH:mm"
    String? description,
    String repeatType = 'none',
    List<int>? weekdays,
  }) async {
    final t = TodoHive(
      id: _uuid.v4(),
      title: title,
      startTime: startTime,
      endTime: endTime,
      description: description,
      repeatType: repeatType,
      weekdays: weekdays ?? [],
    );
    await _box!.put(t.id, t.toMap());
    return t;
  }

  Future<void> updateTodo(TodoHive t) async {
    await _box!.put(t.id, t.toMap());
  }

  Future<void> toggleDone(TodoHive t) async {
    t.isDone = !t.isDone;
    await updateTodo(t);
  }

  Future<void> delete(String id) async {
    await _box!.delete(id);
  }

  // ---------- Scheduling helpers (start/end aware) ----------

  // parse "HH:mm" into today's DateTime at that time
  DateTime _todayAt(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  // Returns tasks that will occur today (including daily/weekly/one-time created today)
  List<TodoHive> tasksOccurringToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all = todos;
    final List<TodoHive> out = [];
    for (final t in all) {
      if (t.repeatType == 'daily') {
        out.add(t);
      } else if (t.repeatType == 'weekly') {
        if (t.weekdays.contains(now.weekday)) out.add(t);
      } else {
        // 'none' — include if created on this day
        final created = DateTime(
          t.createdAt.year,
          t.createdAt.month,
          t.createdAt.day,
        );
        if (created.isAtSameMomentAs(today)) out.add(t);
      }
    }
    // sort by start time
    out.sort((a, b) {
      final aStart = _todayAt(a.startTime);
      final bStart = _todayAt(b.startTime);
      return aStart.compareTo(bStart);
    });
    return out;
  }

  // Checks if a new appointment starting at startHHMM and ending at endHHMM overlaps any task today.
  bool isOverlapping(String startHHMM, String endHHMM, {String? exceptId}) {
    final newStart = _todayAt(startHHMM);
    final newEnd = _todayAt(endHHMM);

    if (!newStart.isBefore(newEnd)) {
      // invalid range — treat as overlapping to prevent saving
      return true;
    }

    final todays = tasksOccurringToday();
    for (final t in todays) {
      if (exceptId != null && t.id == exceptId) continue;
      final tStart = _todayAt(t.startTime);
      final tEnd = _todayAt(t.endTime);
      if (newStart.isBefore(tEnd) && newEnd.isAfter(tStart)) {
        return true;
      }
    }
    return false;
  }

  // Finds next available start time for today given a duration in minutes.
  // Starts searching from 09:00 (or from now rounded up) in 15-minute steps up to 23:45.
  // Returns HH:mm string of first non-overlapping start. If none found, returns "09:00".
  String getNextAvailableStart(int durationMinutes) {
    // start search at 09:00
    DateTime candidate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      9,
      0,
    );

    final lastPossibleStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      23,
      59,
    );

    // If candidate is before now, try to start from "now rounded up to next 15 minutes"
    final now = DateTime.now();
    if (candidate.isBefore(now)) {
      final minutes = now.minute;
      final remainder = minutes % 15;
      final add = remainder == 0 ? 0 : (15 - remainder);
      final rounded = now.add(Duration(minutes: add));
      candidate = DateTime(
        now.year,
        now.month,
        now.day,
        rounded.hour,
        rounded.minute,
      );
    }

    String fmt(DateTime d) {
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    while (!candidate.isAfter(lastPossibleStart)) {
      final candStart = fmt(candidate);
      final candEnd = fmt(candidate.add(Duration(minutes: durationMinutes)));
      if (!isOverlapping(candStart, candEnd)) {
        return candStart;
      }
      candidate = candidate.add(const Duration(minutes: 15));
    }

    // fallback
    return "09:00";
  }
}
