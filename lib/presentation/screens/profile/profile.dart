import 'package:flutter/material.dart';
import 'package:self_develpoment_app/presentation/screens/auth/login/login.dart';
import 'package:self_develpoment_app/presentation/screens/setting/avatar_setting.dart';
import 'package:self_develpoment_app/presentation/screens/setting/color_setting.dart';
import 'package:self_develpoment_app/presentation/screens/setting/change_pass.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 1,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: const _OverviewSection(),
    );
  }
}

// =====================================================
// OVERVIEW SECTION
// =====================================================
class _OverviewSection extends StatefulWidget {
  const _OverviewSection();

  @override
  State<_OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<_OverviewSection> {
  String? username;
  String? avatar;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  bool get isDemoAccount {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return email.contains('demo');
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('name, avatar')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      username = profile?['name'] ?? "User";
      avatar = profile?['avatar'];
      loading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => Login()),
      (_) => false,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final theme = Theme.of(context);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
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
    );

    if (shouldLogout == true) await _logout(context);
  }

  void _showDemo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Demo Feature"),
        content: const Text(
          "This feature is shown for demonstration purposes "
          "and will be available in a future update.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "Self Development App",
      applicationVersion: "1.0.0 (Demo)",
      applicationIcon: const Icon(Icons.self_improvement),
      children: const [
        SizedBox(height: 8),
        Text(
          "A self-development app focused on habits, learning, "
          "and personal growth.",
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= PROFILE HEADER =================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.9),
                  theme.colorScheme.secondary.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AvatarSelectionPage(),
                      ),
                    );
                    _loadUserData();
                  },
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    backgroundImage: avatar != null && avatar!.contains('.')
                        ? AssetImage(avatar!)
                        : null,
                    child: avatar == null
                        ? Text(
                            username != null && username!.isNotEmpty
                                ? username![0].toUpperCase()
                                : "?",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username ?? "User",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDemoAccount ? "Demo account" : "Manage your account",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ================= ACCOUNT =================
          Text(
            "Account",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: Icon(
                    Icons.color_lens,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text("App Color Theme"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ThemeSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ================= APP & DEVICE (DEMO) =================
          Text(
            "App & Device",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text("Device Permissions"),
                  subtitle: const Text("Camera, storage, microphone"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDemo(context),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.accessibility_new_outlined),
                  title: const Text("Accessibility"),
                  subtitle: const Text("Text size, contrast"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDemo(context),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text("Language"),
                  subtitle: const Text("English (Default)"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDemo(context),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text("Help & Support"),
                  subtitle: const Text("FAQs, contact"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDemo(context),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("About"),
                  subtitle: const Text("App version & details"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),

          // ================= ACCOUNT STATUS =================
          if (isDemoAccount) ...[
            const SizedBox(height: 24),
            Text(
              "Account Status",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.verified_user_outlined,
                  color: Colors.orange.shade700,
                ),
                title: const Text("Demo Account"),
                subtitle: const Text("Limited features • Temporary data"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "DEMO",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ================= LOGOUT =================
          Text(
            "Danger Zone",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            color: theme.colorScheme.error.withOpacity(0.05),
            child: ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: const Text("Logout"),
              onTap: () => _confirmLogout(context),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
