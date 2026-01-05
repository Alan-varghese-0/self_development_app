import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_day_model.dart';

class DayDetailPage extends StatefulWidget {
  final DateTime date;
  const DayDetailPage({super.key, required this.date});

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  final supabase = Supabase.instance.client;
  bool _saving = false;

  String get dateStr => widget.date.toIso8601String().split('T').first;

  Future<List<AiProjectDay>> _load() async {
    final rows = await supabase
        .from('ai_project_days')
        .select()
        .eq('date', dateStr);

    return rows.map<AiProjectDay>((r) => AiProjectDay.fromMap(r)).toList();
  }

  Future<void> _toggleTask(AiProjectDay day, int index, bool value) async {
    setState(() => _saving = true);

    final updated = List<bool>.from(day.taskStatus);
    updated[index] = value;

    final completed = updated.every((v) => v);

    await supabase
        .from('ai_project_days')
        .update({"task_status": updated, "status": completed ? 1 : 0})
        .eq('id', day.id);

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tasks for $dateStr")),
      body: FutureBuilder(
        future: _load(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final days = snap.data!;
          if (days.isEmpty) {
            return const Center(child: Text("No tasks today"));
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(12),
                children: days.map((d) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(d.tasks.length, (i) {
                            return CheckboxListTile(
                              value: d.taskStatus[i],
                              onChanged: (v) => _toggleTask(d, i, v!),
                              title: Text(d.tasks[i]),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_saving)
                const Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
