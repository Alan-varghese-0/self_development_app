// lib/todo/todo_data.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class TodoHive {
  String id;
  String title;
  String? description;
  bool isDone;
  DateTime createdAt;
  String startTime;
  String endTime;
  String repeatType;
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

  static TodoHive fromMap(Map m) => TodoHive(
    id: m['id'],
    title: m['title'],
    description: m['description'],
    isDone: m['isDone'] == true,
    createdAt: DateTime.parse(m['createdAt']),
    startTime: m['startTime'],
    endTime: m['endTime'],
    repeatType: m['repeatType'],
    weekdays: List<int>.from(m['weekdays'] ?? []),
  );
}

class TodoData {
  static const _boxName = 'todo_box';
  static final TodoData _instance = TodoData._internal();
  factory TodoData() => _instance;
  TodoData._internal();

  final Uuid _uuid = const Uuid();
  Box? _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _initialized = true;
  }

  List<TodoHive> get todos =>
      _box!.values.map((e) => TodoHive.fromMap(Map.from(e))).toList();

  // ✅ RETURNS TodoHive (needed for AnimatedList)
  Future<TodoHive> addTodo({
    required String title,
    required String startTime,
    required String endTime,
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
      weekdays: weekdays,
    );
    await _box!.put(t.id, t.toMap());
    return t;
  }

  Future<void> updateTodo(TodoHive t) async {
    await _box!.put(t.id, t.toMap());
  }

  Future<void> delete(String id) async {
    await _box!.delete(id);
  }

  Future<void> toggleDone(TodoHive t) async {
    t.isDone = !t.isDone;
    await updateTodo(t);
  }

  // ---------- Helpers ----------

  DateTime _todayAt(String hhmm) {
    final p = hhmm.split(':');
    return DateTime.now().copyWith(
      hour: int.parse(p[0]),
      minute: int.parse(p[1]),
    );
  }

  bool isOverlapping(String start, String end, {String? exceptId}) {
    final s = _todayAt(start);
    final e = _todayAt(end);
    for (final t in todos) {
      if (t.id == exceptId) continue;
      final ts = _todayAt(t.startTime);
      final te = _todayAt(t.endTime);
      if (s.isBefore(te) && e.isAfter(ts)) return true;
    }
    return false;
  }

  String getNextAvailableStart(int minutes) {
    DateTime t = DateTime.now().copyWith(hour: 9, minute: 0);
    while (t.hour < 23) {
      final s =
          "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
      final e = t.add(Duration(minutes: minutes));
      final es =
          "${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}";
      if (!isOverlapping(s, es)) return s;
      t = t.add(const Duration(minutes: 15));
    }
    return "09:00";
  }

  // ✅ SAFE (used by weekly progress)
  List<TodoHive> todosForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final out = <TodoHive>[];

    for (final t in todos) {
      if (t.repeatType == 'daily')
        out.add(t);
      else if (t.repeatType == 'weekly' && t.weekdays.contains(date.weekday))
        out.add(t);
      else if (t.repeatType == 'none') {
        final c = DateTime(
          t.createdAt.year,
          t.createdAt.month,
          t.createdAt.day,
        );
        if (c == day) out.add(t);
      }
    }
    return out;
  }
}
