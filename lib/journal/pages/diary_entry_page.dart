import 'package:flutter/material.dart';
import '../services/journal_service.dart';
import 'diary_summary_page.dart';

class DiaryEntryPage extends StatefulWidget {
  const DiaryEntryPage({super.key});

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  final controller = TextEditingController();
  final service = JournalService();
  double mood = 5;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Journal")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Slider(
              value: mood,
              min: 1,
              max: 10,
              divisions: 9,
              label: mood.toStringAsFixed(0),
              onChanged: saving ? null : (v) => setState(() => mood = v),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                expands: true,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "Write your thoughts...",
                ),
              ),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;
                      setState(() => saving = true);

                      final id = await service.createJournal(controller.text);

                      service.generateAI(
                        journalId: id,
                        content: controller.text,
                        score: mood,
                      );

                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiarySummaryPage(journalId: id),
                        ),
                      );
                    },
              child: const Text("Save & Analyze"),
            ),
          ],
        ),
      ),
    );
  }
}
