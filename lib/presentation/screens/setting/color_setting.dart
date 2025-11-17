import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:self_develpoment_app/data/models/theme_provider.dart';
import 'package:self_develpoment_app/navigation/bottumbar.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeProvider>(context, listen: false);

    final colorCombos = [
      // ORIGINALS
      {
        "primary": Colors.blueAccent,
        "secondary": Colors.blue,
        "name": "Ocean Blue",
      },
      {
        "primary": Colors.deepPurple,
        "secondary": Colors.purpleAccent,
        "name": "Royal Purple",
      },
      {
        "primary": Colors.green,
        "secondary": Colors.teal,
        "name": "Fresh Green",
      },
      {
        "primary": Colors.orange,
        "secondary": Colors.deepOrange,
        "name": "Sunset Orange",
      },
      {
        "primary": Colors.pinkAccent,
        "secondary": Colors.redAccent,
        "name": "Romantic Pink",
      },

      // NEW PREMIUM THEMES
      {
        "primary": Color(0xFF4FBDBA),
        "secondary": Color(0xFF35858B),
        "name": "Mint Breeze",
      },
      {
        "primary": Color(0xFF3A0CA3),
        "secondary": Color(0xFF4361EE),
        "name": "Midnight Indigo",
      },
      {
        "primary": Color(0xFFFFB300),
        "secondary": Color(0xFFFF8F00),
        "name": "Amber Gold",
      },
      {
        "primary": Color(0xFFFF5D8F),
        "secondary": Color(0xFFFF91AF),
        "name": "Blossom Pink",
      },
      {
        "primary": Color(0xFFD90429),
        "secondary": Color(0xFFEF233C),
        "name": "Crimson Flame",
      },
      {
        "primary": Color(0xFF48CAE4),
        "secondary": Color(0xFF0096C7),
        "name": "Ice Blue",
      },
      {
        "primary": Color(0xFF2A9D8F),
        "secondary": Color(0xFF264653),
        "name": "Forest Emerald",
      },
      {
        "primary": Color(0xFFFF6F61),
        "secondary": Color(0xFFFF8C79),
        "name": "Coral Sunset",
      },
      {
        "primary": Color(0xFF6C757D),
        "secondary": Color(0xFF495057),
        "name": "Slate Storm",
      },
      {
        "primary": Color(0xFF7209B7),
        "secondary": Color(0xFFB5179E),
        "name": "Cosmic Purple",
      },

      // PASTEL THEMES
      {
        "primary": Color(0xFFFFE066),
        "secondary": Color(0xFFFFD93D),
        "name": "Pastel Lemon",
      },
      {
        "primary": Color(0xFFBFA2DB),
        "secondary": Color(0xFFDAB6FC),
        "name": "Pastel Lavender",
      },
      {
        "primary": Color(0xFFFFCDB2),
        "secondary": Color(0xFFFFB4A2),
        "name": "Pastel Peach",
      },

      // DARK & TECH THEMES
      {
        "primary": Color(0xFF0A84FF),
        "secondary": Color(0xFF5E5CE6),
        "name": "Neon Blue",
      },
      {
        "primary": Color(0xFF00C853),
        "secondary": Color(0xFF1B5E20),
        "name": "Cyber Green",
      },
      {
        "primary": Color(0xFFF50057),
        "secondary": Color(0xFFC51162),
        "name": "Neon Pink",
      },
      {
        "primary": Color(0xFF00E5FF),
        "secondary": Color(0xFF00B8D4),
        "name": "Electric Cyan",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Theme Settings")),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Color Themes",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // 🌈 NEW GRID UI
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: colorCombos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final combo = colorCombos[index];

              return GestureDetector(
                onTap: () async {
                  await provider.setTheme(
                    combo["primary"] as Color,
                    combo["secondary"] as Color,
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Bottumbar()),
                    (route) => false,
                  );
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 75,
                      width: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            combo["primary"] as Color,
                            combo["secondary"] as Color,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (combo["primary"] as Color).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      combo["name"].toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          const Text(
            "Theme Mode",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ListTile(
            title: const Text("Light Mode"),
            leading: const Icon(Icons.light_mode),
            onTap: () {
              provider.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),

          ListTile(
            title: const Text("Dark Mode"),
            leading: const Icon(Icons.dark_mode),
            onTap: () {
              provider.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
