import 'package:flutter/material.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Settings",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text(
                "Maintenance Mode",
                style: TextStyle(color: Colors.white),
              ),
              activeColor: Colors.white,
            ),

            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.white),
              title: const Text(
                "Sync now",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
