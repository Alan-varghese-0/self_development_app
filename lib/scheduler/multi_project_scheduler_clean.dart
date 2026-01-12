import 'package:flutter/material.dart';
import 'package:self_develpoment_app/scheduler/Ai_project_day.dart';
import 'package:self_develpoment_app/scheduler/scheduler_data.dart';
import 'package:self_develpoment_app/scheduler/add_project_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MultiProjectSchedulerPage extends StatefulWidget {
  const MultiProjectSchedulerPage({super.key});

  @override
  State<MultiProjectSchedulerPage> createState() =>
      _MultiProjectSchedulerPageState();
}

class _MultiProjectSchedulerPageState extends State<MultiProjectSchedulerPage> {
  final SchedulerData data = SchedulerData();

  bool _loading = true;
  String? _error;
  String? _currentUserId;

  final PageController _pageController = PageController(initialPage: 1000);
  int _currentPage = 1000;

  @override
  void initState() {
    super.initState();
    _initScheduler();
  }

  Future<void> _initScheduler() async {
    try {
      final client = Supabase.instance.client;

      await data.init(supabaseClient: client);

      _currentUserId = client.auth.currentUser?.id;

      if (_currentUserId != null) {
        await data.migrateLocalToUser(_currentUserId!);
        await data.syncBoth(userId: _currentUserId!);
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  DateTime _monthFromPage(int page) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + (page - 1000), 1);
  }

  List<DateTime> _daysForMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysBefore = first.weekday - 1;
    final start = first.subtract(Duration(days: daysBefore));

    final list = <DateTime>[];
    for (int i = 0; i < 42; i++) {
      list.add(start.add(Duration(days: i)));
    }
    return list;
  }

  Widget _buildDay(DateTime day, DateTime month) {
    final events = data.getAssignmentsFor(day);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday =
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;

    final isPast = day.isBefore(today);
    final isOutsideMonth = day.month != month.month;

    Color textColor = isToday
        ? Theme.of(context).colorScheme.primary
        : isOutsideMonth
        ? Colors.grey
        : Colors.black;

    return InkWell(
      onTap: events.isEmpty ? null : () => _showDayDetails(day, events),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(
              "${day.day}",
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 6),
            if (events.isNotEmpty)
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: events.take(4).map((p) {
                  return Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Color(p.colorValue),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDayDetails(DateTime day, List<ProjectHive> projects) async {
    if (projects.isEmpty) return;

    final project = projects.first;

    try {
      final aiDays = await Supabase.instance.client
          .from('ai_project_days')
          .select()
          .eq('project_id', project.id)
          .eq('date', data.formatDate(day));

      if (aiDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tasks scheduled for this day.')),
        );
        return;
      }

      final Map<String, dynamic> row = aiDays.first;
      AiProjectDay dayData = AiProjectDay.fromMap(row);
      List<bool> localTaskStatus = List.from(dayData.taskStatus);

      showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('${project.title} – ${dayData.title}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: dayData.tasks.length,
                itemBuilder: (context, i) {
                  return CheckboxListTile(
                    title: Text(dayData.tasks[i]),
                    value: localTaskStatus[i],
                    onChanged: (bool? value) async {
                      if (value == null) return;
                      setDialogState(() => localTaskStatus[i] = value);

                      // Update in Supabase
                      localTaskStatus[i] = value;
                      await Supabase.instance.client
                          .from('ai_project_days')
                          .update({'task_status': localTaskStatus})
                          .eq('id', dayData.id);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildMonthPage(int page) {
    final month = _monthFromPage(page);
    final days = _daysForMonth(month);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            "${_monthName(month.month)} ${month.year}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _Weekday("Mon"),
            _Weekday("Tue"),
            _Weekday("Wed"),
            _Weekday("Thu"),
            _Weekday("Fri"),
            _Weekday("Sat"),
            _Weekday("Sun"),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (_, i) => _buildDay(days[i], month),
          ),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m - 1];
  }

  Widget _projectList() {
    final list = data.projects;
    if (list.isEmpty) {
      return const Center(child: Text("No projects yet."));
    }

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
              "${p.dailyHours}h/day • "
              "${p.startDate.year}-${p.startDate.month}-${p.startDate.day} → "
              "${p.deadline.year}-${p.deadline.month}-${p.deadline.day}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProjectPage(projectToEdit: p),
                      ),
                    );
                    if (updated == true && _currentUserId != null) {
                      await data.syncBoth(userId: _currentUserId!);
                      setState(() {});
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await data.deleteProject(p);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scheduler Error")),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Project Scheduler")),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (p) => setState(() => _currentPage = p),
              itemBuilder: (_, pageIndex) => _buildMonthPage(pageIndex),
            ),
          ),
          Expanded(flex: 4, child: _projectList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProjectPage()),
          );
          if (result == true && _currentUserId != null) {
            await data.syncBoth(userId: _currentUserId!);
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  final String label;
  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
