import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:self_develpoment_app/presentation/screens/user/audiobook.dart';
import 'package:self_develpoment_app/scheduler/multi_project_scheduler_clean.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  double progress = 0.75;

  final List<Map<String, dynamic>> tasks = [
    {"title": "Read 10 pages", "done": false},
    {"title": "Audiobook - 10 minutes", "done": true},
    {"title": "Complete a brain game", "done": false},
  ];

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _fade(int delay) =>
      CurvedAnimation(parent: _controller, curve: Interval(delay * 0.15, 1.0));

  Animation<Offset> _slide(int delay) =>
      Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(delay * 0.15, 1.0, curve: Curves.easeOut),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: const Text(
          "Auvyra",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Greeting
            _AnimatedSection(
              fade: _fade(0),
              slide: _slide(0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Hello, Alex 👋",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Weekly Progress
            _AnimatedSection(
              fade: _fade(1),
              slide: _slide(1),
              child: _weeklyProgress(theme, scheme),
            ),
            const SizedBox(height: 28),

            // Recent Activity
            _AnimatedSection(
              fade: _fade(2),
              slide: _slide(2),
              child: _recentActivity(theme, scheme),
            ),
            const SizedBox(height: 28),

            // To-Do List
            _AnimatedSection(
              fade: _fade(3),
              slide: _slide(3),
              child: _todoList(theme, scheme),
            ),
            const SizedBox(height: 28),

            // Quick Access
            _AnimatedSection(
              fade: _fade(4),
              slide: _slide(4),
              child: _quickAccessGrid(theme, scheme),
            ),
            const SizedBox(height: 28),

            // Chart
            _AnimatedSection(
              fade: _fade(5),
              slide: _slide(5),
              child: _progressChart(theme, scheme),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------
  //  UI Components
  // --------------------------

  Widget _weeklyProgress(ThemeData theme, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 50,
            lineWidth: 8,
            percent: progress,
            progressColor: scheme.primary,
            backgroundColor: scheme.primary.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
            center: Text(
              "${(progress * 100).round()}%",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weekly Progress",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Streak: 12 Days 🔥",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivity(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activity",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            "• Completed: Mindfulness Module 1\n"
            "• Listened: Habit-Building Audiobook (Ch. 3)",
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _todoList(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Tasks",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Column(
          children: tasks.map((t) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    t["done"] ? Icons.check_circle : Icons.circle_outlined,
                    color: t["done"] ? scheme.primary : scheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t["title"],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: t["done"]
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _quickAccessGrid(ThemeData theme, ColorScheme scheme) {
    return Column(
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
              icon: Icons.psychology_alt_rounded,
              title: "Brain Games",
              scheme: scheme,
              page: const MultiProjectSchedulerPage(),
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
              page: const AudiobooksPage(),
            ),
            _QuickCard(
              icon: Icons.checklist_rounded,
              title: "To-Do List",
              scheme: scheme,
              page: const AudiobooksPage(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _progressChart(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Progress Over Time",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
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
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          width: 18,
        ),
      ],
    );
  }
}

//
// Animates any child (fade + slide)
//
class _AnimatedSection extends StatelessWidget {
  final Widget child;
  final Animation<double> fade;
  final Animation<Offset> slide;

  const _AnimatedSection({
    required this.child,
    required this.fade,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

//
// Quick Access Card with TAP animation
//
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
            color: widget.scheme.surfaceContainerHigh,
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
