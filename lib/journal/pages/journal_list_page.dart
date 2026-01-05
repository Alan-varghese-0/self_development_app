import 'package:flutter/material.dart';
import '../services/journal_service.dart';
import 'diary_entry_page.dart';
import 'diary_summary_page.dart';
import 'journal_calendar_page.dart';

class JournalListPage extends StatelessWidget {
  const JournalListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = JournalService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Journal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalCalendarPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Today"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiaryEntryPage()),
          );
        },
      ),
      body: FutureBuilder(
        future: service.getJournals(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data!;
          if (list.isEmpty) {
            return const Center(child: Text("No journals yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final j = list[i];
              final hasAI = (j['journal_ai_summaries'] as List).isNotEmpty;

              return Card(
                child: ListTile(
                  title: Text(
                    j['content'].length > 40
                        ? "${j['content'].substring(0, 40)}..."
                        : j['content'],
                  ),
                  trailing: Icon(
                    hasAI ? Icons.check_circle : Icons.hourglass_empty,
                    color: hasAI ? Colors.green : Colors.orange,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiarySummaryPage(
                          journalId: j['id'],
                          autoGenerate: !hasAI,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
