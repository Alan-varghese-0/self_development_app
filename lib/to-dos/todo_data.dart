// lib/todo/todo_data.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class TodoHive {
  String id;
  String title;
  String? description;
  bool isDone;
  DateTime createdAt;
  // time stored as "HH:mm"
  String time;
  // repeatType: 'none' | 'daily' | 'weekly'
  String repeatType;
  // weekdays: List<int> with 1 = Monday ... 7 = Sunday
  List<int> weekdays;

  TodoHive({
    required this.id,
    required this.title,
    required this.time,
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
    'time': time,
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
      time: m['time']?.toString() ?? '09:00',
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
    // older first; UI reverses to show newest on top
    return out;
  }

  Future<TodoHive> addTodo({
    required String title,
    required String time, // "HH:mm"
    String? description,
    String repeatType = 'none',
    List<int>? weekdays,
  }) async {
    final t = TodoHive(
      id: _uuid.v4(),
      title: title,
      time: time,
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
}
