import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/journal_service.dart';
import 'diary_summary_page.dart';

class JournalCalendarPage extends StatefulWidget {
  const JournalCalendarPage({super.key});

  @override
  State<JournalCalendarPage> createState() => _JournalCalendarPageState();
}

class _JournalCalendarPageState extends State<JournalCalendarPage> {
  final service = JournalService();
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> journalMap = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await service.getJournals();
    final map = <DateTime, List<Map<String, dynamic>>>{};

    for (final j in list) {
      final date = DateTime.parse(j['created_at']);
      final key = DateTime(date.year, date.month, date.day);
      map.putIfAbsent(key, () => []).add(j);
    }

    setState(() => journalMap = map);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Journal Calendar")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            focusedDay: focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return journalMap[key] ?? [];
            },
          ),
          Expanded(
            child: ListView(
              children:
                  (journalMap[DateTime(
                            selectedDay?.year ?? 0,
                            selectedDay?.month ?? 0,
                            selectedDay?.day ?? 0,
                          )] ??
                          [])
                      .map(
                        (j) => ListTile(
                          title: Text(
                            j['content'].length > 40
                                ? "${j['content'].substring(0, 40)}..."
                                : j['content'],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DiarySummaryPage(
                                  journalId: j['id'],
                                  autoGenerate:
                                      (j['journal_ai_summaries'] as List)
                                          .isEmpty,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
