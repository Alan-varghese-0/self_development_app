// lib/scheduler/multi_project_scheduler.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scheduler_data.dart';

class MultiProjectSchedulerPage extends StatefulWidget {
  const MultiProjectSchedulerPage({super.key});

  @override
  State<MultiProjectSchedulerPage> createState() =>
      _MultiProjectSchedulerPageState();
}

class _MultiProjectSchedulerPageState extends State<MultiProjectSchedulerPage> {
  final SchedulerData data = SchedulerData();

  DateTime _focused = DateTime.now();
  DateTime? _selected;

  // Form inputs
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _hoursCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _deadline;
  Color _pickedColor = Colors.blue;

  bool _loading = true;
  String? _currentUserId;
  String? _error;

  // timeouts
  static const Duration initTimeout = Duration(seconds: 12);
  static const Duration syncTimeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _initScheduler();
  }

  Future<void> _initScheduler() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      if (client == null) throw Exception('Supabase client not initialized');

      await data
          .init(supabaseClient: client)
          .timeout(
            initTimeout,
            onTimeout: () {
              throw Exception('Hive init/openBox timed out');
            },
          );

      _currentUserId = client.auth.currentUser?.id;

      // migrate any local items to the real user id if user is signed in
      if (_currentUserId != null) {
        await data.migrateLocalToUser(_currentUserId!);
        try {
          await data.syncBoth(userId: _currentUserId!).timeout(syncTimeout);
        } catch (e) {
          debugPrint('Initial sync failed: $e');
          _error = 'Initial sync failed: ${_shortError(e)}';
        }
      }
    } catch (e, st) {
      debugPrint('Scheduler init error: $e\n$st');
      _error = 'Initialization error: ${_shortError(e)}';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _shortError(Object? e) {
    if (e == null) return 'unknown';
    final s = e.toString();
    return s.length > 200 ? '${s.substring(0, 200)}...' : s;
  }

  String _dayKey(DateTime d) => d.toIso8601String().split('T').first;

  List<ProjectHive> _eventsForDay(DateTime day) => data.getAssignmentsFor(day);

  Future<void> _openAddDialog({ProjectHive? editing}) async {
    if (editing != null) {
      _titleCtrl.text = editing.title;
      _hoursCtrl.text = editing.dailyHours.toString();
      _startDate = editing.startDate;
      _deadline = editing.deadline;
      _pickedColor = Color(editing.colorValue);
    } else {
      _titleCtrl.clear();
      _hoursCtrl.clear();
      _startDate = DateTime.now();
      _deadline = null;
      _pickedColor = Colors.blue;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            final quickHours = [2, 4, 6, 8, 12, 16];
            final colors = [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
              Colors.teal,
              Colors.brown,
              Colors.indigo,
              Colors.pink,
              Colors.cyan,
            ];

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(editing == null ? 'New Project' : 'Edit Project'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                height: 470,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Project Title',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _hoursCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hours per day (1–16)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: quickHours.map((h) {
                          return ActionChip(
                            label: Text('${h}h'),
                            onPressed: () {
                              _hoursCtrl.text = h.toString();
                              setDialog(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        title: Text(
                          _startDate == null
                              ? 'Select start date'
                              : 'Start: ${_dayKey(_startDate!)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: _startDate ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 10),
                          );
                          if (picked != null)
                            setDialog(() => _startDate = picked);
                        },
                      ),
                      ListTile(
                        title: Text(
                          _deadline == null
                              ? 'Select deadline'
                              : 'Deadline: ${_dayKey(_deadline!)}',
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          if (_startDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Select start date first'),
                              ),
                            );
                            return;
                          }

                          final initial =
                              _deadline ??
                              _startDate!.add(const Duration(days: 1));
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: initial,
                            firstDate: _startDate!,
                            lastDate: DateTime(DateTime.now().year + 10),
                          );
                          if (picked != null) {
                            setDialog(
                              () => _deadline = picked.isBefore(_startDate!)
                                  ? _startDate
                                  : picked,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text('Color:'),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 110,
                        child: GridView.count(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          physics: const NeverScrollableScrollPhysics(),
                          children: colors.map((c) {
                            final sel = _pickedColor == c;
                            return GestureDetector(
                              onTap: () => setDialog(() => _pickedColor = c),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: sel ? 44 : 36,
                                height: sel ? 44 : 36,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: sel ? Colors.black : Colors.black26,
                                    width: sel ? 2 : 1,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = _titleCtrl.text.trim();
                    final hours = int.tryParse(_hoursCtrl.text.trim()) ?? 0;

                    if (title.isEmpty ||
                        hours < 1 ||
                        hours > 16 ||
                        _startDate == null ||
                        _deadline == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fill all fields correctly'),
                        ),
                      );
                      return;
                    }

                    if (editing == null) {
                      final userId = _currentUserId ?? 'local';
                      await data.addLocal(
                        title: title,
                        dailyHours: hours,
                        startDate: _startDate!,
                        deadline: _deadline!,
                        colorValue: _pickedColor.value,
                        userId: userId,
                      );
                    } else {
                      editing.title = title;
                      editing.dailyHours = hours;
                      editing.startDate = _startDate!;
                      editing.deadline = _deadline!;
                      editing.colorValue = _pickedColor.value;
                      editing.pending = true;
                      editing.updatedAt = DateTime.now();
                      await data.updateLocal(editing);
                    }

                    // If signed in try sync (migration + sync)
                    if (_currentUserId != null) {
                      try {
                        await data.migrateLocalToUser(_currentUserId!);
                        await data
                            .syncBoth(userId: _currentUserId!)
                            .timeout(syncTimeout);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved and synced')),
                        );
                      } catch (e) {
                        debugPrint('Sync after add failed: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Saved locally — sync failed: ${_shortError(e)}',
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved locally')),
                      );
                    }

                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: Text(editing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _projectList() {
    final list = data.projects;

    if (list.isEmpty) return const Center(child: Text('No projects yet.'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final p = list[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Color(p.colorValue)),
            title: Text(p.title),
            subtitle: Text(
              '${p.dailyHours}h/day • ${_dayKey(p.startDate)} → ${_dayKey(p.deadline)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _openAddDialog(editing: p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    // remove local copy
                    await data.deleteLocal(p.id);
                    // also remove remote if we have current user
                    if (_currentUserId != null) {
                      try {
                        await Supabase.instance.client
                            .from('projects')
                            .delete()
                            .eq('id', p.id);
                      } catch (e) {
                        debugPrint('Remote delete failed: $e');
                      }
                    }
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project deleted')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fullCalendar() {
    return TableCalendar(
      focusedDay: _focused,
      firstDay: DateTime(DateTime.now().year - 1),
      lastDay: DateTime(DateTime.now().year + 3),
      eventLoader: _eventsForDay,
      selectedDayPredicate: (d) =>
          _selected != null && _dayKey(_selected!) == _dayKey(d),
      onDaySelected: (sel, foc) => setState(() {
        _selected = sel;
        _focused = foc;
      }),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (_, day, __) => _dayMarker(day),
      ),
    );
  }

  Widget _dayMarker(DateTime day) {
    final events = data.getAssignmentsFor(day);
    final todayKey = _dayKey(DateTime.now());
    final dayKey = _dayKey(day);

    // Colors per your request:
    // past -> black, future -> white, today -> theme color
    final isToday = dayKey == todayKey;
    final now = DateTime.now();
    final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
    final textColor = isToday
        ? Theme.of(context).colorScheme.primary
        : (isPast ? Colors.black : Colors.white);

    return Column(
      children: [
        Text(
          '${day.day}',
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
        if (events.isNotEmpty)
          Wrap(
            spacing: 3,
            children: events.take(4).map((p) {
              // color dots without shadow
              return Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Color(p.colorValue),
                  shape: BoxShape.circle,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Scheduler — Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  'Initialization failed',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initScheduler,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _error = null),
                  icon: const Icon(Icons.data_saver_off),
                  label: const Text('Use local data'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Scheduler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              if (_currentUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not signed in — cannot sync.')),
                );
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Syncing...')));
              try {
                // migrate any local "local" items to real user id, then sync
                await data.migrateLocalToUser(_currentUserId!);
                await data
                    .syncBoth(userId: _currentUserId!)
                    .timeout(syncTimeout);
                setState(() {});
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Sync complete')));
              } catch (e) {
                debugPrint('Manual sync failed: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sync failed: ${_shortError(e)}')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: _fullCalendar()),
          Expanded(child: _projectList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }
}
