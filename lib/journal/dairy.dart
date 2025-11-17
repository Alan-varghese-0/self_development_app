import 'package:flutter/material.dart';
import 'package:self_develpoment_app/journal/Ai_summery.dart';

class DiaryEntryPage extends StatefulWidget {
  const DiaryEntryPage({super.key});

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  final TextEditingController entryController = TextEditingController();
  double moodValue = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Journey"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How are you feeling today?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            // Mood Slider
            Slider(
              value: moodValue,
              min: 1,
              max: 10,
              divisions: 9,
              label: moodValue.toStringAsFixed(0),
              onChanged: (value) {
                setState(() {
                  moodValue = value;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Write about your day",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: TextField(
                controller: entryController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText:
                      "Write anything you want...\nYour thoughts, events, feelings...",
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (entryController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Write something before saving"),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiarySummaryPage(
                          text: entryController.text,
                          mood: moodValue,
                        ),
                      ),
                    );
                  }
                },
                child: const Text("Save & Generate Summary"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
