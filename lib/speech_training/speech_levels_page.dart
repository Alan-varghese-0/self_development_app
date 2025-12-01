// lib/speech_training/speech_levels_page.dart
// import 'dart:math'; // no longer used after removing streak UI
import 'package:flutter/material.dart';
import 'speech_training_page.dart';

class SpeechLevelsPage extends StatelessWidget {
  const SpeechLevelsPage({super.key});

  // Example sentence packs — you can move these into a JSON or DB later.
  static final List<String> beginner = [
    "Hello",
    "Good morning",
    "Thank you",
    "How are you",
    "I am fine",
  ];

  static final List<String> intermediate = [
    "I will finish my work today",
    "You are doing a great job",
    "This app helps me learn",
    "I like improving myself",
  ];

  static final List<String> advanced = [
    "I want to become a more confident speaker in my life",
    "Today I will complete all my important tasks on time",
    "I am learning to express my thoughts more clearly",
    "Speaking practice helps improve communication skills quickly",
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Practice'),
        centerTitle: true,
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      backgroundColor: scheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Minimal view: only level tiles
            _levelTile(
              context,
              title: "Beginner",
              subtitle: "Short phrases & greetings",
              color: Colors.green,
              sentences: beginner,
            ),
            const SizedBox(height: 12),
            _levelTile(
              context,
              title: "Intermediate",
              subtitle: "Short sentences",
              color: Colors.orange,
              sentences: intermediate,
            ),
            const SizedBox(height: 12),
            _levelTile(
              context,
              title: "Advanced",
              subtitle: "Long sentences & fluency",
              color: Colors.purple,
              sentences: advanced,
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required List<String> sentences,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SpeechTrainingPage(sentences: sentences, level: title),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(Icons.school, size: 34, color: color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        // streak removed
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Random practice removed — minimal UI only shows three levels
}
