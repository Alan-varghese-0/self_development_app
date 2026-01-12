import 'package:flutter/material.dart';
import 'package:self_develpoment_app/presentation/screens/auth/auth_wrapper.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Fade in
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _opacity = 1.0);
    });

    // Fade out
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _opacity = 0.0);
    });

    // Navigate after fade
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo/Auvyra.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),

              Transform.translate(
                offset: const Offset(0, -50), // 👈 pulls text upward
                child: const Text(
                  'auvyra',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A5AE0),
                    letterSpacing: 1.2,
                    height: 1.0, // 👈 removes extra line height
                  ),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Learn • Grow • Transform',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
