// lib/presentation/screens/user/user_home_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:self_develpoment_app/presentation/screens/admin/admin_pdfs_page.dart';
import 'package:self_develpoment_app/presentation/screens/user/weekly_progress_detail_page.dart';
import 'package:self_develpoment_app/speech_training/speech_levels_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iconsax/iconsax.dart';

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
  double _completionRate = 0.0;
  int _totalTasks = 0;
  int _completedTasks = 0;

  // Weekly progress: completed tasks this week (index 0 = Monday, index 6 = Sunday)
  List<double> _weeklyCompletedTasks = List.filled(7, 0.0);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
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

      await _todo.init();
      await _scheduler.init(supabaseClient: client);

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
      _computeCompletionRate();
      _computeWeeklyProgress(); // Will now fill data correctly Mon → Sun
    } catch (e, st) {
      debugPrint("Home setup error: $e\n$st");
    }

    if (mounted) setState(() => _loading = false);
  }

  void _computeCompletionRate() {
    _totalTasks = _todayTasks.length;
    _completedTasks = _todayTasks.where((t) => t.isDone).length;
    _completionRate = _totalTasks > 0 ? _completedTasks / _totalTasks : 0.0;
  }

  void _computeTodayTasks() {
    final all = _todo.todos;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = now.weekday;

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

    _todayTasks.sort((a, b) {
      final ap = _parseTimeParts(a.startTime);
      final bp = _parseTimeParts(b.startTime);
      if (ap[0] != bp[0]) return ap[0].compareTo(bp[0]);
      return ap[1].compareTo(bp[1]);
    });

    _computeCalendarDays();
    _computeCompletionRate();
    _computeWeeklyProgress();
    if (mounted) setState(() {});
  }

  // FIXED: Now fills _weeklyCompletedTasks with Monday (index 0) → Sunday (index 6)
  // FIXED VERSION - Weekly Progress now correctly shows Monday to Sunday
  // with today's completed tasks on the correct bar (e.g., Tuesday → second bar "T")

  void _computeWeeklyProgress() {
    final allTodos = _todo.todos;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = now.weekday; // 1=Mon ... 7=Sun

    final Map<DateTime, int> completedPerDay = {};

    // Find this week's Monday
    final daysSinceMonday = weekday - 1; // e.g., Tuesday = 1
    final thisMonday = today.subtract(Duration(days: daysSinceMonday));

    // Initialize all 7 days of this week
    for (int i = 0; i < 7; i++) {
      final day = thisMonday.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      completedPerDay[dayKey] = 0;
    }

    for (final task in allTodos) {
      // One-time tasks: if created this week and completed
      if (task.repeatType == 'none') {
        final taskDate = DateTime(
          task.createdAt.year,
          task.createdAt.month,
          task.createdAt.day,
        );
        if (taskDate.isAfter(thisMonday.subtract(const Duration(days: 1))) &&
            taskDate.isBefore(thisMonday.add(const Duration(days: 7))) &&
            task.isDone) {
          final dayKey = taskDate;
          if (completedPerDay.containsKey(dayKey)) {
            completedPerDay[dayKey] = (completedPerDay[dayKey] ?? 0) + 1;
          }
        }
      }
      // Repeating tasks (daily/weekly): count today's completion if applicable and done
      else if (task.isDone) {
        bool appearsToday = false;
        if (task.repeatType == 'daily') {
          appearsToday = true;
        } else if (task.repeatType == 'weekly') {
          appearsToday = task.weekdays.contains(weekday);
        }
        if (appearsToday) {
          completedPerDay[today] = (completedPerDay[today] ?? 0) + 1;
        }
      }
    }

    // Fill list: index 0 = Monday, 1=Tue, ..., 6=Sunday
    _weeklyCompletedTasks = List.generate(7, (index) {
      final day = thisMonday.add(Duration(days: index));
      final dayKey = DateTime(day.year, day.month, day.day);
      return (completedPerDay[dayKey] ?? 0).toDouble();
    });

    if (mounted) setState(() {});
  }

  void _computeCalendarDays() {
    final now = DateTime.now();
    final daysToSunday = now.weekday % 7;
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

  List<int> _parseTimeParts(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return [h, m];
  }

  bool _isMissed(TodoHive t) {
    final now = DateTime.now();
    final parts = _parseTimeParts(t.endTime);
    final due = DateTime(now.year, now.month, now.day, parts[0], parts[1]);

    if (t.repeatType == 'none') {
      final today = DateTime(now.year, now.month, now.day);
      final created = DateTime(
        t.createdAt.year,
        t.createdAt.month,
        t.createdAt.day,
      );
      if (created.isBefore(today)) return !t.isDone;
      return due.isBefore(now) && !t.isDone;
    }

    if (t.repeatType == 'daily') return due.isBefore(now) && !t.isDone;

    if (t.repeatType == 'weekly') {
      if (t.weekdays.contains(now.weekday)) {
        return due.isBefore(now) && !t.isDone;
      }
    }

    return false;
  }

  String _repeatSummary(TodoHive t) {
    if (t.repeatType == 'none') return 'One-time';
    if (t.repeatType == 'daily') return 'Daily';
    if (t.repeatType == 'weekly') {
      if (t.weekdays.isEmpty) return 'Weekly';
      final names = t.weekdays.map((d) => _weekdayName(d)).join(', ');
      return 'Weekly: $names';
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
  // UI COMPONENTS
  // -----------------------

  Widget _welcomeSection(ThemeData theme) {
    return FadeTransition(
      opacity: _anim(0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.colorScheme.secondary.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"The only limit is our doubts of today."',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
              child: Icon(
                Iconsax.user,
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressOverview(ThemeData theme) {
    // ... (unchanged - same as before)
    return FadeTransition(
      opacity: _anim(1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Progress",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_completedTasks/$_totalTasks',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CircularProgress(
                    progress: _completionRate,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatItem(
                        icon: Iconsax.tick_circle,
                        label: 'Completed',
                        value: '$_completedTasks tasks',
                        color: Colors.green,
                        theme: theme,
                      ),
                      const SizedBox(height: 6),
                      _StatItem(
                        icon: Iconsax.clock,
                        label: 'Pending',
                        value: '${_totalTasks - _completedTasks} tasks',
                        color: Colors.orange,
                        theme: theme,
                      ),
                      const SizedBox(height: 6),
                      _StatItem(
                        icon: Iconsax.calendar,
                        label: 'Weekly Streak',
                        value: '5 days',
                        color: theme.colorScheme.primary,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarGrid(ThemeData theme) {
    // ... (unchanged - full code from your original)
    final rows = 2;
    final totalDays = rows * 7;

    return FadeTransition(
      opacity: _anim(2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Schedule Overview",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '2 Weeks',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (day) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalDays,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) =>
                  _calendarCell(_calendarDays[index], theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarCell(DateTime day, ThemeData theme) {
    // ... (unchanged)
    final assignments = _scheduler.getAssignmentsFor(day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = DateTime(day.year, day.month, day.day);
    final isToday = dayKey.isAtSameMomentAs(today);
    final isPast = dayKey.isBefore(today);

    return GestureDetector(
      onTap: () => _showDayDetailSheet(day, assignments),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isToday
              ? theme.colorScheme.primary.withOpacity(0.1)
              : (isPast
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                    : theme.colorScheme.surfaceVariant),
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(
                          isPast ? 0.4 : 0.8,
                        ),
                ),
              ),
              if (assignments.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 3,
                  width: 3,
                  decoration: BoxDecoration(
                    color: Color(assignments.first.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetailSheet(DateTime day, List<ProjectHive> assignments) {
    final todos = _todo.todosForDate(day);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // date header
                  Text(
                    "${_monthName(day.month)} ${day.day}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    "Tasks & Schedule",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // -------- TODOS --------
                        if (todos.isNotEmpty) ...[
                          Text(
                            "To-Dos",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          ...todos.map(
                            (t) => ListTile(
                              leading: Icon(
                                t.isDone
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: t.isDone ? Colors.green : Colors.grey,
                              ),
                              title: Text(t.title),
                              subtitle: Text("${t.startTime} – ${t.endTime}"),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // -------- PROJECTS --------
                        if (assignments.isNotEmpty) ...[
                          Text(
                            "Projects",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          ...assignments.map(
                            (p) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(p.colorValue),
                                radius: 6,
                              ),
                              title: Text(p.title),
                              subtitle: Text("${p.dailyHours} hrs planned"),
                            ),
                          ),
                        ],

                        if (todos.isEmpty && assignments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                "No tasks or projects for this day",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  Widget _quickAccess(ThemeData theme) {
    // ... (unchanged - keep your original full code)
    final cards = [
      _QuickAccessCard(
        title: "Schedule",
        subtitle: "Plan projects",
        icon: Iconsax.calendar_1,
        color: const Color(0xFF4F46E5),
        page: const MultiProjectSchedulerPage(),
        anim: _anim(4),
      ),
      _QuickAccessCard(
        title: "Tasks",
        subtitle: "Manage to-dos",
        icon: Iconsax.task_square,
        color: const Color(0xFF059669),
        page: const TodoPage(),
        anim: _anim(5),
      ),
      _QuickAccessCard(
        title: "Resources",
        subtitle: "Learning materials",
        icon: Iconsax.book_1,
        color: const Color(0xFFDC2626),
        page: const AdminPDFsPage(),
        anim: _anim(6),
      ),
      _QuickAccessCard(
        title: "Speech",
        subtitle: "Training exercises",
        icon: Iconsax.voice_cricle,
        color: const Color(0xFF7C3AED),
        page: const SpeechLevelsPage(),
        anim: _anim(7),
      ),
    ];

    return FadeTransition(
      opacity: _anim(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Access",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            physics: const NeverScrollableScrollPhysics(),
            children: cards,
          ),
        ],
      ),
    );
  }

  // FIXED Weekly Progress - now matches M T W T F S S labels perfectly
  Widget _weeklyProgress(ThemeData theme) {
    return FadeTransition(
      opacity: _anim(5),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Weekly Progress",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.more, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeeklyProgressDetailPage(),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final index = value.toInt();
                          if (index < 0 || index >= days.length)
                            return const Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[index],
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _weeklyCompletedTasks[index],
                          width: 12,
                          borderRadius: BorderRadius.circular(6),
                          color: theme.colorScheme.primary.withOpacity(0.8),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.radar, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your journey...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant,
      body: RefreshIndicator(
        onRefresh: () async => await _setup(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _welcomeSection(theme),
                const SizedBox(height: 16),
                _progressOverview(theme),
                const SizedBox(height: 16),
                _calendarGrid(theme),
                const SizedBox(height: 16),
                _quickAccess(theme),
                const SizedBox(height: 16),
                _weeklyProgress(theme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TodoPage()),
            );
            _computeTodayTasks();
            _computeWeeklyProgress();
          },
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// -----------------------------
// SUPPORTING WIDGETS (unchanged)
// -----------------------------

class _CircularProgress extends StatelessWidget {
  final double progress;
  final Color color;
  const _CircularProgress({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
  final Animation<double> anim;
  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
    required this.anim,
  });

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.anim,
      child: ScaleTransition(
        scale: widget.anim,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => widget.page),
            );
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withOpacity(0.75),
                  widget.color.withOpacity(0.50),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
