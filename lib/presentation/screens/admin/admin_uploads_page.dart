import 'package:flutter/material.dart';

class AdminUploadsPage extends StatelessWidget {
  const AdminUploadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Uploads",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.white),
              title: const Text(
                "Upload PDF",
                style: TextStyle(color: Colors.white),
              ),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text("Upload"),
              ),
            ),

            const Divider(color: Colors.white24),

            ListTile(
              leading: const Icon(Icons.headset, color: Colors.white),
              title: const Text(
                "Upload Audiobook",
                style: TextStyle(color: Colors.white),
              ),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text("Upload"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
