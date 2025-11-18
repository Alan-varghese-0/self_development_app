import 'package:flutter/material.dart';
import 'package:self_develpoment_app/presentation/screens/onbording/onboarding_screen.dart';
import 'package:self_develpoment_app/navigation/bottumbar.dart';
import 'package:self_develpoment_app/presentation/screens/auth/login/login.dart';
import 'package:self_develpoment_app/presentation/screens/admin/admin_home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // FIRST TIME USER → SHOW ONBOARDING
    if (!_hasSeenOnboarding) {
      return const OnboardingPage();
    }

    // AUTH STATE LISTENER
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return FutureBuilder(
            future: Supabase.instance.client
                .from("profiles")
                .select("role")
                .eq("id", session.user.id)
                .single(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = snap.data?["role"].toString().trim().toLowerCase();

              print("🟣 AUTH WRAPPER ROLE: $role");

              if (role == "admin") {
                return const AdminHome();
              } else {
                return const Bottumbar();
              }
            },
          );
        }

        return Login();
      },
    );
  }
}
