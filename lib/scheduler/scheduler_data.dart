// lib/scheduler/scheduler_data.dart
// Robust map-based Hive storage + Supabase sync with migration from "local" -> real user id.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProjectHive {
  String id;
  String userId;
  String title;
  int dailyHours;
  DateTime startDate;
  DateTime deadline;
  int colorValue;
  DateTime createdAt;
  DateTime updatedAt;
  bool pending;

  ProjectHive({
    required this.id,
    required this.userId,
    required this.title,
    required this.dailyHours,
    required this.startDate,
    required this.deadline,
    required this.colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pending = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'dailyHours': dailyHours,
    'startDate': startDate.toIso8601String(),
    'deadline': deadline.toIso8601String(),
    'colorValue': colorValue,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pending': pending,
  };

  static ProjectHive fromSupabase(Map<String, dynamic> row) {
    DateTime parseDateFallback(Object? val, {DateTime? fallback}) {
      if (val == null) return fallback ?? DateTime.now();
      try {
        final s = val.toString();
        if (s.isEmpty) return fallback ?? DateTime.now();
        return DateTime.parse(s);
      } catch (e) {
        debugPrint('ProjectHive.fromSupabase: failed to parse date "$val": $e');
        return fallback ?? DateTime.now();
      }
    }

    final id = row['id']?.toString() ?? const Uuid().v4();
    final userId =
        row['user_id']?.toString() ?? row['userId']?.toString() ?? 'unknown';
    final title = row['title']?.toString() ?? '';
    final dailyHours = () {
      final v = row['daily_hours'] ?? row['dailyHours'];
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }();

    final startDate = parseDateFallback(
      row['start_date'] ?? row['startDate'] ?? row['created_at'],
      fallback: DateTime.now(),
    );

    final deadline = parseDateFallback(row['deadline'], fallback: startDate);

    final colorValue = () {
      final v = row['color'] ?? row['color_value'] ?? row['colorValue'];
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }();

    final createdAt = parseDateFallback(
      row['created_at'] ?? row['createdAt'],
      fallback: DateTime.now(),
    );
    final updatedAt = parseDateFallback(
      row['updated_at'] ?? row['updatedAt'],
      fallback: createdAt,
    );

    return ProjectHive(
      id: id,
      userId: userId,
      title: title,
      dailyHours: dailyHours,
      startDate: startDate,
      deadline: deadline,
      colorValue: colorValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
      pending: false,
    );
  }

  static ProjectHive fromMap(Map m) {
    DateTime safeParse(dynamic v, [DateTime? fallback]) {
      if (v == null) return fallback ?? DateTime.now();
      try {
        final s = v.toString();
        if (s.isEmpty) return fallback ?? DateTime.now();
        return DateTime.parse(s);
      } catch (_) {
        return fallback ?? DateTime.now();
      }
    }

    final id = m['id']?.toString() ?? const Uuid().v4();
    final userId = m['userId']?.toString() ?? 'local';
    final title = m['title']?.toString() ?? '';
    final dailyHours = (() {
      final v = m['dailyHours'];
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    })();
    final startDate = safeParse(m['startDate'], DateTime.now());
    final deadline = safeParse(m['deadline'], startDate);
    final colorValue = (() {
      final v = m['colorValue'];
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    })();
    final createdAt = safeParse(m['createdAt'], DateTime.now());
    final updatedAt = safeParse(m['updatedAt'], createdAt);
    final pending = m['pending'] == true;

    return ProjectHive(
      id: id,
      userId: userId,
      title: title,
      dailyHours: dailyHours,
      startDate: startDate,
      deadline: deadline,
      colorValue: colorValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
      pending: pending,
    );
  }
}

class SchedulerData {
  static const _boxName = 'scheduler_projects_box';
  final Uuid _uuid = const Uuid();
  Box? _box;
  SupabaseClient? supabase;
  bool _initialized = false;

  // guard to prevent concurrent syncs
  bool _syncing = false;

  static final SchedulerData _instance = SchedulerData._internal();
  factory SchedulerData() => _instance;
  SchedulerData._internal();

  Future<void> init({required SupabaseClient supabaseClient}) async {
    if (_initialized) return;

    await Hive.initFlutter();
    supabase = supabaseClient;

    try {
      _box = await Hive.openBox(_boxName);
    } catch (e, st) {
      debugPrint('Hive openBox failed: $e\n$st');
      debugPrint(
        'Attempting to delete box and recreate (will remove local data).',
      );
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        debugPrint('Deleted box "$_boxName". Recreating...');
      } catch (delErr) {
        debugPrint('Failed to delete box $_boxName: $delErr');
        rethrow;
      }
      _box = await Hive.openBox(_boxName);
    }

    _initialized = true;
  }

  List<ProjectHive> get projects {
    if (_box == null) return [];
    final out = <ProjectHive>[];
    for (final v in _box!.values) {
      try {
        if (v is ProjectHive) {
          out.add(v);
        } else if (v is Map) {
          out.add(ProjectHive.fromMap(v));
        } else {
          final m = Map<String, dynamic>.from(v as dynamic);
          out.add(ProjectHive.fromMap(m));
        }
      } catch (e) {
        debugPrint('projects: failed to parse stored value: $e — value: $v');
      }
    }
    return out;
  }

  Future<void> _put(ProjectHive p) async {
    if (_box == null) throw Exception('SchedulerData not initialized');
    await _box!.put(p.id, p.toMap());
  }

  Future<ProjectHive> addLocal({
    required String title,
    required int dailyHours,
    required DateTime startDate,
    required DateTime deadline,
    required int colorValue,
    required String userId,
  }) async {
    final now = DateTime.now();
    final p = ProjectHive(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      dailyHours: dailyHours,
      startDate: startDate,
      deadline: deadline,
      colorValue: colorValue,
      createdAt: now,
      updatedAt: now,
      pending: true,
    );
    await _put(p);
    debugPrint('addLocal: saved project locally id=${p.id} user=${p.userId}');
    return p;
  }

  Future<void> updateLocal(ProjectHive p) async {
    p.pending = true;
    p.updatedAt = DateTime.now();
    await _put(p);
    debugPrint('updateLocal: updated project locally id=${p.id}');
  }

  Future<void> deleteLocal(String id) async {
    if (_box == null) throw Exception('SchedulerData not initialized');
    await _box!.delete(id);
    debugPrint('deleteLocal: deleted $id');
  }

  ProjectHive? getById(String id) {
    if (_box == null) return null;
    final v = _box!.get(id);
    if (v == null) return null;
    try {
      if (v is ProjectHive) return v;
      if (v is Map) return ProjectHive.fromMap(v);
      return ProjectHive.fromMap(Map<String, dynamic>.from(v as dynamic));
    } catch (e) {
      debugPrint('getById parse error: $e — value: $v');
      return null;
    }
  }

  String _dayKey(DateTime d) => d.toIso8601String().split('T').first;

  Map<String, List<ProjectHive>> getAssignmentsMap() {
    final map = <String, List<ProjectHive>>{};
    for (final p in projects) {
      DateTime day = DateTime(
        p.startDate.year,
        p.startDate.month,
        p.startDate.day,
      );
      final end = DateTime(p.deadline.year, p.deadline.month, p.deadline.day);
      while (!day.isAfter(end)) {
        final key = _dayKey(day);
        map.putIfAbsent(key, () => []);
        if (!map[key]!.any((x) => x.id == p.id)) {
          map[key]!.add(p);
        }
        day = day.add(const Duration(days: 1));
      }
    }
    return map;
  }

  List<ProjectHive> getAssignmentsFor(DateTime d) {
    final key = _dayKey(d);
    return getAssignmentsMap()[key] ?? [];
  }

  // Helper: simple uuid-ish check
  bool _looksLikeUuid(String v) {
    final re = RegExp(r'^[0-9a-fA-F-]{36}$');
    return re.hasMatch(v);
  }

  // Migrate all local items to a given userId (call when user signs in)
  Future<void> migrateLocalToUser(String userId) async {
    if (_box == null) return;
    for (final p in projects) {
      if (p.userId == 'local') {
        p.userId = userId;
        p.pending = true;
        await _put(p);
        debugPrint('migrateLocalToUser: migrated ${p.id} -> $userId');
      }
    }
  }

  // ------------------------------
  // Supabase sync (improved)
  // ------------------------------
  Future<void> syncUp({required String userId}) async {
    if (supabase == null) {
      debugPrint('syncUp: supabase client is null — skipping');
      return;
    }
    if (_syncing) {
      debugPrint('syncUp: already syncing — skipping concurrent call');
      return;
    }
    if (!_looksLikeUuid(userId)) {
      debugPrint(
        'syncUp: provided userId does not look like UUID -> "$userId" — aborting server sync',
      );
      return;
    }

    _syncing = true;
    try {
      final pending = projects.where((p) => p.pending).toList();
      debugPrint('syncUp: pending count=${pending.length}');
      for (final p in pending) {
        try {
          final projectMap = {
            'id': p.id,
            'user_id': p.userId,
            'title': p.title,
            'daily_hours': p.dailyHours,
            'start_date': _dayKey(p.startDate),
            'deadline': _dayKey(p.deadline),
            'color': p.colorValue,
            'created_at': p.createdAt.toUtc().toIso8601String(),
            'updated_at': p.updatedAt.toUtc().toIso8601String(),
          };

          debugPrint('syncUp: upserting project ${p.id}');
          final upsertRes = await supabase!
              .from('projects')
              .upsert(projectMap)
              .select();
          debugPrint(
            'syncUp: upsertRes=${upsertRes.runtimeType} => ${upsertRes.toString()}',
          );

          // generate assignments (safe-check for duplicates)
          await _generateAssignments(p);

          p.pending = false;
          await _put(p);
          debugPrint('syncUp: project ${p.id} marked synced.');
        } catch (e, st) {
          debugPrint('syncUp ERROR for project ${p.id}: $e\n$st');
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> _generateAssignments(ProjectHive p) async {
    if (supabase == null) {
      debugPrint('_generateAssignments: supabase null');
      return;
    }
    debugPrint(
      '_generateAssignments: project=${p.id} start=${_dayKey(p.startDate)} end=${_dayKey(p.deadline)}',
    );

    for (
      DateTime day = p.startDate;
      !day.isAfter(p.deadline);
      day = day.add(const Duration(days: 1))
    ) {
      final dateStr = _dayKey(day);
      try {
        final existing = await supabase!
            .from('project_assignments')
            .select('id')
            .eq('project_id', p.id)
            .eq('date', dateStr)
            .limit(1);

        final hasExisting =
            (existing != null) &&
            ((existing is List && existing.isNotEmpty) ||
                (existing is Map && existing.isNotEmpty));

        if (hasExisting) {
          debugPrint(
            '_generateAssignments: already exists ${p.id} / $dateStr -> skipping',
          );
          continue;
        }

        final insertRes = await supabase!.from('project_assignments').insert({
          'user_id': p.userId,
          'project_id': p.id,
          'date': dateStr,
          'hours': p.dailyHours,
        }).select();

        debugPrint(
          '_generateAssignments: inserted ${p.id} / $dateStr => ${insertRes.toString()}',
        );
      } catch (e, st) {
        debugPrint(
          '_generateAssignments ERROR for ${p.id} on $dateStr: $e\n$st',
        );
      }
    }
  }

  Future<void> syncDown({required String userId}) async {
    if (supabase == null) {
      debugPrint('syncDown: supabase null');
      return;
    }
    if (!_looksLikeUuid(userId)) {
      debugPrint('syncDown: invalid userId: $userId');
      return;
    }

    try {
      final rows = await supabase!
          .from('projects')
          .select()
          .eq('user_id', userId);
      debugPrint(
        'syncDown: fetched projects rowsCount=${rows is List ? rows.length : 0}',
      );
      for (final r in rows) {
        try {
          final row = Map<String, dynamic>.from(r as Map);
          final remote = ProjectHive.fromSupabase(row);
          final local = getById(remote.id);
          if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
            await _put(remote);
            debugPrint('syncDown: wrote remote project ${remote.id} to local');
          }
        } catch (e) {
          debugPrint('syncDown row parse error: $e — row: $r');
        }
      }
    } catch (e) {
      debugPrint('syncDown ERROR: $e');
    }
  }

  Future<void> syncBoth({required String userId}) async {
    await syncUp(userId: userId);
    await syncDown(userId: userId);
  }
}
