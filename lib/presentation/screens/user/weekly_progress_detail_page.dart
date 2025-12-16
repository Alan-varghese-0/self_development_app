import 'package:flutter/material.dart';
import 'package:self_develpoment_app/to-dos/todo_data.dart';

class WeeklyProgressDetailPage extends StatefulWidget {
  const WeeklyProgressDetailPage({super.key});

  @override
  State<WeeklyProgressDetailPage> createState() =>
      _WeeklyProgressDetailPageState();
}

class _WeeklyProgressDetailPageState extends State<WeeklyProgressDetailPage> {
  final TodoData todoData = TodoData();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await todoData.init();
    setState(() => _ready = true);
  }

  DateTime _startOfWeek(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  String _dayName(int w) =>
      ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][w - 1];

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final start = _startOfWeek(DateTime.now());

    int total = 0;
    int done = 0;

    final week = List.generate(7, (i) {
      final date = start.add(Duration(days: i));
      final todos = todoData.todosForDate(date);
      final completed = todos.where((t) => t.isDone).length;

      total += todos.length;
      done += completed;

      return {'date': date, 'total': todos.length, 'done': completed};
    });

    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _stat("Productivity", "$percent%"),
                _stat("Done", "$done"),
                _stat("Missed", "${total - done}"),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (_, i) {
                  final d = week[i];
                  final total = d['total'] as int;
                  final done = d['done'] as int;

                  Color c;
                  if (total == 0) {
                    c = Colors.grey;
                  } else if (done == total) {
                    c = Colors.green;
                  } else if (done >= total / 2) {
                    c = Colors.orange;
                  } else {
                    c = Colors.red;
                  }

                  return ListTile(
                    leading: CircleAvatar(radius: 6, backgroundColor: c),
                    title: Text(_dayName((d['date'] as DateTime).weekday)),
                    subtitle: Text("$done / $total tasks completed"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String t, String v) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                v,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(t, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
