import 'package:flutter/material.dart';

class DiaryTimelinePage extends StatelessWidget {
  const DiaryTimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Journey Timeline"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10, // replace with saved entries count
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text("Day ${index + 1}  •  Score: ${5 + index % 5}/10"),
              subtitle: const Text("Tap to view details..."),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
