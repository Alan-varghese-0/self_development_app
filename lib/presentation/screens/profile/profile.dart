import 'package:flutter/material.dart';
import 'package:self_develpoment_app/presentation/screens/auth/login/login.dart';
import 'package:self_develpoment_app/presentation/screens/setting/avatar_setting.dart';
import 'package:self_develpoment_app/presentation/screens/setting/color_setting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 1,
        backgroundColor: theme.colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: "Overview"),
            Tab(icon: Icon(Icons.emoji_events_outlined), text: "Achievements"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_OverviewTab(), _AchievementsTab()],
      ),
    );
  }
}

//
//  OVERVIEW TAB (STATEFUL)
//
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  String? username;
  String? avatar;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('name, avatar')
          .eq('id', user.id)
          .single();

      setState(() {
        username = profile['name'] ?? "User";
        avatar = profile['avatar']; // nullable
        loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Login()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final theme = Theme.of(context);

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 60,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  "Logout?",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to sign out?",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout == true) {
      await _logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // AVATAR SECTION
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AvatarSelectionPage()),
              );
              _loadUserData(); // Refresh after avatar update
            },
            child: avatar == null
                ? CircleAvatar(
                    radius: 45,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      username![0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 45,
                    backgroundImage: AssetImage(avatar!),
                  ),
          ),

          const SizedBox(height: 12),

          Text(
            username ?? "User",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Growing every day 🌱",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 20),

          // STATS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat("Level", "5", theme),
              _buildStat("XP", "1240", theme),
              _buildStat("Streak", "14 Days", theme),
            ],
          ),

          const SizedBox(height: 30),

          // EDIT PROFILE CARD
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
                size: 30,
              ),
              title: const Text("Edit Profile"),
              subtitle: const Text("Update your personal information"),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 10),

          // THEME SETTINGS
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(
                Icons.color_lens,
                color: theme.colorScheme.primary,
                size: 30,
              ),
              title: const Text("App Color Theme"),
              subtitle: const Text("Customize your app colors"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThemeSettingsPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // LOGOUT
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.error,
                size: 30,
              ),
              title: const Text("Logout"),
              subtitle: const Text("Sign out of your account"),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}

//
// ACHIEVEMENTS TAB
//
class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final achievements = [
      {
        "title": "Fast Learner",
        "desc": "Completed 5 modules in one week",
        "icon": Icons.bolt,
      },
      {
        "title": "Audio Explorer",
        "desc": "Listened to 10 audiobooks",
        "icon": Icons.headphones,
      },
      {
        "title": "Consistent Performer",
        "desc": "Maintained 7-day streak",
        "icon": Icons.trending_up,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final a = achievements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              child: Icon(
                a["icon"] as IconData,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              a["title"].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(a["desc"].toString()),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }
}
