import 'package:flutter/material.dart';

class AdminPDFsPage extends StatelessWidget {
  const AdminPDFsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ("Atomic Habits.pdf", "Self-help"),
      ("Quick Recipes.pdf", "Cooking"),
      ("Yoga Beginner.pdf", "Fitness"),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "PDF Library",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            ...items.map(
              (e) => Card(
                color: Colors.white10,
                child: ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white,
                  ),
                  title: Text(
                    e.$1,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    e.$2,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
