// lib/presentation/screens/user/user_home_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:self_develpoment_app/speech_training/speech_levels_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// pages
import 'package:self_develpoment_app/to-dos/todo-page.dart';
import 'package:self_develpoment_app/presentation/screens/user/audiobook.dart';
import 'package:self_develpoment_app/scheduler/multi_project_scheduler_clean.dart';

// data
import 'package:self_develpoment_app/scheduler/scheduler_data.dart';
import 'package:self_develpoment_app/to-dos/todo_data.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  // animation
  late final AnimationController _controller;
  Animation<double> _anim(int delay) =>
      CurvedAnimation(parent: _controller, curve: Interval(delay * 0.12, 1.0));

  // services
  final SchedulerData _scheduler = SchedulerData();
  final TodoData _todo = TodoData();

  // UI states
  bool _loading = true;
  String _userName = 'User';
  List<TodoHive> _todayTasks = [];
  List<DateTime> _calendarDays = [];
  bool _expandedFourWeeks = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });

    _setup();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    setState(() => _loading = true);

    try {
      final client = Supabase.instance.client;

      // init hive boxes
      await _todo.init();
      await _scheduler.init(supabaseClient: client);

      // load user's name
      final session = client.auth.currentSession;
      if (session != null) {
        try {
          final profile = await client
              .from('profiles')
              .select('name')
              .eq('id', session.user.id)
              .maybeSingle();

          if (profile != null && profile['name'] != null) {
            _userName = profile['name'].toString();
          } else {
            _userName = session.user.email ?? 'User';
          }
        } catch (_) {
          _userName = session.user.email ?? 'User';
        }
      }

      _computeTodayTasks();
      _computeCalendarDays();
    } catch (e, st) {
      debugPrint("Home setup error: $e\n$st");
    }

    if (mounted) setState(() => _loading = false);
  }

  // -------------------------------------------------------
  // TODAY’S TASKS
  // -------------------------------------------------------

  void _computeTodayTasks() {
    final all = _todo.todos;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = now.weekday; // 1..7 Mon→Sun

    _todayTasks = all.where((t) {
      if (t.repeatType == 'daily') return true;
      if (t.repeatType == 'weekly') return t.weekdays.contains(weekday);
      if (t.repeatType == 'none') {
        final created = DateTime(
          t.createdAt.year,
          t.createdAt.month,
          t.createdAt.day,
        );
        return created.isAtSameMomentAs(today);
      }
      return false;
    }).toList();

    // _expandedFourWeeks = _todayTasks.isEmpty;
    _computeCalendarDays();
    if (mounted) setState(() {});
  }

  // -------------------------------------------------------
  // CALENDAR DAYS (2 or 4 weeks, Sun→Sat)
  // -------------------------------------------------------

  void _computeCalendarDays() {
    final now = DateTime.now();

    // For Sunday-start week:
    // Dart weekday: Mon=1 ... Sun=7. We want distance to Sunday.
    final daysToSunday = now.weekday % 7; // Sun -> 0, Mon ->1, ... Sat->6
    final sunday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysToSunday));

    final rows = 2;
    final totalDays = rows * 7;

    _calendarDays = List.generate(
      totalDays,
      (i) => DateTime(sunday.year, sunday.month, sunday.day + i),
    );
  }

  // -------------------------------------------------------
  // TIME PARSE + MISSED DETECTION
  // -------------------------------------------------------

  List<int> _parseTimeParts(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return [h, m];
  }

  bool _isMissed(TodoHive t) {
    final now = DateTime.now();
    final parts = _parseTimeParts(t.time);
    final hour = parts[0];
    final minute = parts[1];

    final due = DateTime(now.year, now.month, now.day, hour, minute);
    final today = DateTime(now.year, now.month, now.day);

    if (t.repeatType == 'none') {
      final created = DateTime(
        t.createdAt.year,
        t.createdAt.month,
        t.createdAt.day,
      );
      if (created.isBefore(today)) return !t.isDone;
      return due.isBefore(now) && !t.isDone;
    }

    if (t.repeatType == 'daily') {
      return due.isBefore(now) && !t.isDone;
    }

    if (t.repeatType == 'weekly') {
      if (t.weekdays.contains(now.weekday)) {
        return due.isBefore(now) && !t.isDone;
      }
    }

    return false;
  }

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  String _repeatSummary(TodoHive t) {
    if (t.repeatType == 'none') return 'No repeat';
    if (t.repeatType == 'daily') return 'Repeats daily';
    if (t.repeatType == 'weekly') {
      if (t.weekdays.isEmpty) return 'Repeats weekly';
      final names = t.weekdays.map((d) => _weekdayName(d)).join(', ');
      return 'Repeats: $names';
    }
    return '';
  }

  String _weekdayName(int d) {
    const names = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return names[d] ?? d.toString();
  }

  // -----------------------
  // Calendar cell + header + details sheet
  // -----------------------

  Widget _calendarCell(DateTime day) {
    final assignments = _scheduler.getAssignmentsFor(day);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = DateTime(day.year, day.month, day.day);

    final isToday = dayKey.isAtSameMomentAs(today);
    final isPast = dayKey.isBefore(today);

    final textColor = isToday
        ? Theme.of(context).colorScheme.primary
        : (isPast ? Colors.black54 : Colors.white);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => _dayDetailSheet(day, assignments),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isPast
              ? Colors.transparent
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.6,
                )
              : null,
        ),
        child: Column(
          children: [
            Text(
              '${day.day}',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 6),
            if (assignments.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: assignments.take(4).map((p) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(p.colorValue),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _dayDetailSheet(DateTime day, List<ProjectHive> assignments) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.day} ${_monthName(day.month)} ${day.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (assignments.isEmpty)
            const Text('No projects scheduled for this day.')
          else
            ...assignments.map(
              (p) => ListTile(
                leading: CircleAvatar(backgroundColor: Color(p.colorValue)),
                title: Text(p.title),
                subtitle: Text('${p.dailyHours}h/day'),
              ),
            ),
        ],
      ),
    );
  }

  // -----------------------
  // Calendar header widget (Sun..Sat)
  // -----------------------

  Widget _calendarGrid(ThemeData theme) {
    final rows = 2;
    final totalDays = rows * 7;

    return FadeTransition(
      opacity: _anim(1),
      child: Container(
        padding: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          // Option C: fully white in light, near-black in dark
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Weekday header (Sun..Sat)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _CalHeader('Sun'),
                _CalHeader('Mon'),
                _CalHeader('Tue'),
                _CalHeader('Wed'),
                _CalHeader('Thu'),
                _CalHeader('Fri'),
                _CalHeader('Sat'),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalDays,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
                childAspectRatio: .75,
              ),
              itemBuilder: (context, index) {
                final day = _calendarDays[index];
                return _calendarCell(day);
              },
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------
  // Today's Tasks UI
  // -----------------------

  Widget _todaysTasks(ThemeData theme) {
    return FadeTransition(
      opacity: _anim(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Tasks",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_todayTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('No tasks for today.'),
            )
          else
            Column(
              children: _todayTasks.map((t) {
                final missed = _isMissed(t);
                final parts = _parseTimeParts(t.time);
                final tod = TimeOfDay(
                  hour: parts[0],
                  minute: parts[1],
                ).format(context);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (missed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "You can't complete a missed task",
                                ),
                              ),
                            );
                            return;
                          }
                          await _todo.toggleDone(t);
                          _computeTodayTasks();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: t.isDone
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: missed
                                  ? Colors.grey.shade400
                                  : (t.isDone
                                        ? theme.colorScheme.primary
                                        : Colors.grey),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: missed
                                ? Icon(
                                    Icons.block,
                                    color: Colors.grey.shade500,
                                    size: 18,
                                  )
                                : (t.isDone
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : const SizedBox.shrink()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: TextStyle(
                                decoration: t.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (t.description != null &&
                                t.description!.isNotEmpty)
                              Text(
                                t.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  tod,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _repeatSummary(t),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                if (missed) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'MISSED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TodoPage()),
                          );
                          _computeTodayTasks();
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // -----------------------
  // Quick Access + Chart
  // -----------------------

  Widget _quickAccessGrid(ThemeData theme, ColorScheme scheme) {
    return FadeTransition(
      opacity: _anim(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Access",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _QuickCard(
                icon: Icons.calendar_month_rounded,
                title: "Scheduler",
                scheme: scheme,
                page: const MultiProjectSchedulerPage(),
              ),
              _QuickCard(
                icon: Icons.checklist_rounded,
                title: "To-Do List",
                scheme: scheme,
                page: const TodoPage(),
              ),
              _QuickCard(
                icon: Icons.menu_book_rounded,
                title: "Audiobooks",
                scheme: scheme,
                page: const AudiobooksPage(),
              ),
              _QuickCard(
                icon: Icons.record_voice_over_rounded,
                title: "Speech Training",
                scheme: scheme,
                page: const SpeechLevelsPage(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressChart(ThemeData theme, ColorScheme scheme) {
    // small demo bar chart
    return FadeTransition(
      opacity: _anim(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Progress Over Time",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                barGroups: [
                  _bar(0, 4, scheme.primary),
                  _bar(1, 7, scheme.primary),
                  _bar(2, 5, scheme.primary),
                  _bar(3, 8, scheme.primary),
                  _bar(4, 6, scheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) => BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: y,
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        width: 18,
      ),
    ],
  );

  // -----------------------
  // Build
  // -----------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text(
          "Auvyra",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _setup();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _anim(0),
                child: Text(
                  'Hello, $_userName 👋',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _calendarGrid(theme),
              const SizedBox(height: 18),
              _todaysTasks(theme),
              const SizedBox(height: 18),
              _quickAccessGrid(theme, scheme),
              const SizedBox(height: 18),
              _progressChart(theme, scheme),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     // quick entry — open TodoPage
      //     await Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => const TodoPage()),
      //     );
      //     _computeTodayTasks();
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}

// -----------------------------
// Small supporting widgets
// -----------------------------

class _CalHeader extends StatelessWidget {
  final String title;
  const _CalHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _QuickCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final ColorScheme scheme;
  final Widget page;
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.scheme,
    required this.page,
    super.key,
  });

  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard>
    with SingleTickerProviderStateMixin {
  double scale = 1.0;
  void _tapDown() => setState(() => scale = 0.95);
  void _tapUp() => setState(() => scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapDown(),
      onTapCancel: _tapUp,
      onTapUp: (_) {
        _tapUp();
        Navigator.push(context, MaterialPageRoute(builder: (_) => widget.page));
      },
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.scheme.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: widget.scheme.primaryContainer,
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: widget.scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
