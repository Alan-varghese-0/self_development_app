import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:self_develpoment_app/scheduler/fallback_templates.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProjectHive {
  String id;
  String userId;
  String title;
  String description;
  int dailyHours;
  DateTime startDate;
  DateTime deadline;
  int colorValue;
  bool pending;

  ProjectHive({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dailyHours,
    required this.startDate,
    required this.deadline,
    required this.colorValue,
    this.pending = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'dailyHours': dailyHours,
    'startDate': startDate.toIso8601String(),
    'deadline': deadline.toIso8601String(),
    'colorValue': colorValue,
    'pending': pending,
  };

  static ProjectHive fromMap(Map m) => ProjectHive(
    id: m['id'],
    userId: m['userId'],
    title: m['title'],
    description: m['description'] ?? '',
    dailyHours: m['dailyHours'],
    startDate: DateTime.parse(m['startDate']),
    deadline: DateTime.parse(m['deadline']),
    colorValue: m['colorValue'],
    pending: m['pending'] == true,
  );
}

class SchedulerData {
  static const _boxName = 'scheduler_projects';
  final _uuid = const Uuid();

  Box? _box;
  SupabaseClient? supabase;
  bool _syncing = false;

  static final SchedulerData _i = SchedulerData._();
  factory SchedulerData() => _i;
  SchedulerData._();

  Future<void> init({required SupabaseClient supabaseClient}) async {
    await Hive.initFlutter();
    _box ??= await Hive.openBox(_boxName);
    supabase = supabaseClient;
  }

  List<ProjectHive> get projects =>
      _box!.values.map((e) => ProjectHive.fromMap(Map.from(e))).toList();

  // Private method (used internally)
  String _day(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  // PUBLIC method — this is what external classes should use
  String formatDate(DateTime d) => _day(d);

  Future<ProjectHive> addLocal({
    required String title,
    required String description,
    required int dailyHours,
    required DateTime startDate,
    required DateTime deadline,
    required int colorValue,
    required String userId,
  }) async {
    final p = ProjectHive(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      description: description,
      dailyHours: dailyHours,
      startDate: startDate,
      deadline: deadline,
      colorValue: colorValue,
      pending: true,
    );
    await _box!.put(p.id, p.toMap());
    return p;
  }

  Future<void> updateLocal(ProjectHive p) async {
    p.pending = true;
    await _box!.put(p.id, p.toMap());
  }

  Future<void> deleteProject(ProjectHive p) async {
    if (supabase != null) {
      await supabase!.from('ai_project_days').delete().eq('project_id', p.id);
      await supabase!
          .from('project_assignments')
          .delete()
          .eq('project_id', p.id);
      await supabase!.from('projects').delete().eq('id', p.id);
    }
    await _box!.delete(p.id);
  }

  List<ProjectHive> getAssignmentsFor(DateTime d) {
    return projects.where((p) {
      return !d.isBefore(p.startDate) && !d.isAfter(p.deadline);
    }).toList();
  }

  Future<void> syncBoth({required String userId}) async {
    await syncUp(userId: userId);
    await syncDown(userId: userId);
  }

  Future<void> syncUp({required String userId}) async {
    if (_syncing || supabase == null) return;
    _syncing = true;

    try {
      for (final p in projects.where((x) => x.pending)) {
        await supabase!.from('projects').upsert({
          'id': p.id,
          'user_id': userId,
          'title': p.title,
          'description': p.description,
          'daily_hours': p.dailyHours,
          'start_date': _day(p.startDate),
          'deadline': _day(p.deadline),
          'color': p.colorValue,
        });

        await _generateAssignments(p);
        await _generateAI(p);

        p.pending = false;
        await _box!.put(p.id, p.toMap());
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> syncDown({required String userId}) async {
    if (supabase == null) return;

    final rows = await supabase!
        .from('projects')
        .select()
        .eq('user_id', userId);

    for (final r in rows) {
      final p = ProjectHive(
        id: r['id'],
        userId: r['user_id'],
        title: r['title'],
        description: r['description'] ?? '',
        dailyHours: r['daily_hours'],
        startDate: DateTime.parse(r['start_date']),
        deadline: DateTime.parse(r['deadline']),
        colorValue: r['color'],
        pending: false,
      );
      await _box!.put(p.id, p.toMap());
    }
  }

  Future<void> _generateAssignments(ProjectHive p) async {
    for (
      DateTime d = p.startDate;
      !d.isAfter(p.deadline);
      d = d.add(const Duration(days: 1))
    ) {
      await supabase!.from('project_assignments').upsert({
        'user_id': p.userId,
        'project_id': p.id,
        'date': _day(d),
        'hours': p.dailyHours,
      });
    }
  }

  Future<void> _generateAI(ProjectHive p) async {
    final exists = await supabase!
        .from('ai_project_days')
        .select('id')
        .eq('project_id', p.id)
        .limit(1);

    if (exists.isNotEmpty) return;

    final totalDays = p.deadline.difference(p.startDate).inDays + 1;
    List days;

    try {
      final res = await supabase!.functions.invoke(
        'generate_schedule',
        body: {
          "projectTitle": p.title,
          "description": p.description,
          "hoursPerDay": p.dailyHours,
          "totalDays": totalDays,
          "goal":
              "Finish before deadline with testing, bug fixing, and final polish",
        },
      );
      days = res.data['days'];
    } catch (e) {
      debugPrint('AI failed → fallback used: $e');
      days = fallbackSchedule(totalDays: totalDays, title: p.title);
    }

    for (final d in days) {
      final date = p.startDate.add(Duration(days: d['day'] - 1));
      await supabase!.from('ai_project_days').insert({
        'project_id': p.id,
        'date': _day(date),
        'title': d['title'],
        'tasks': d['tasks'],
        'task_status': List.filled(d['tasks'].length, false),
        'status': 0,
      });
    }
  }

  Future<void> migrateLocalToUser(String userId) async {
    for (final p in projects) {
      if (p.userId == 'local') {
        p.userId = userId;
        p.pending = true;
        await _box!.put(p.id, p.toMap());
      }
    }
  }
}
