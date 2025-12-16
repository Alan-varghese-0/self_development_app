// lib/daily_challenge/daily_challenge_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Keep for working icons like flame, timer, play, etc.
import 'daily_challenge_service.dart';
import 'mood_storage.dart';

class DailyChallengePage extends StatefulWidget {
  const DailyChallengePage({super.key});

  @override
  State<DailyChallengePage> createState() => _DailyChallengePageState();
}

class _DailyChallengePageState extends State<DailyChallengePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Animation<double> _anim(int delay) => CurvedAnimation(
    parent: _controller,
    curve: Interval(delay * 0.1, 1.0, curve: Curves.easeOut),
  );

  Mood _currentMood = Mood.normal;
  String _challenge = "";
  bool _isStarted = false;
  bool _isLoading = true;
  bool _inCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });

    _loadEverything();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadEverything() async {
    setState(() => _isLoading = true);

    final mood = await MoodStorage.loadMood();
    final data = await MoodStorage.loadChallengeData();

    setState(() {
      _currentMood = mood;
      if (data['challenge'] == null) {
        _challenge = DailyChallengeService.getChallenge(mood);
      } else {
        _challenge = data['challenge']!;
      }
      _isStarted = data['status'] == 'started';
      _isLoading = false;
      _inCooldown = false;
    });
  }

  Future<void> _onMoodChanged(Mood newMood) async {
    await MoodStorage.saveMood(newMood);
    await MoodStorage.generateNewChallenge(newMood);

    final data = await MoodStorage.loadChallengeData();
    setState(() {
      _currentMood = newMood;
      _challenge = data['challenge']!;
      _isStarted = false;
    });
  }

  Future<void> _startNewChallenge() async {
    await MoodStorage.generateNewChallenge(_currentMood);
    final data = await MoodStorage.loadChallengeData();
    setState(() {
      _challenge = data['challenge']!;
      _isStarted = false;
      _inCooldown = false;
    });
  }

  Future<void> _completeChallenge() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Amazing! Challenge completed 🎉"),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );

    final randomMinutes = 5 + Random().nextInt(11); // 5–15 minutes
    _cooldownSeconds = randomMinutes * 60;

    await MoodStorage.clearChallenge();

    setState(() {
      _inCooldown = true;
      _isStarted = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          timer.cancel();
          _inCooldown = false;
          _loadEverything();
        }
      });
    });
  }

  String _formatCooldown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSleepTime = DailyChallengeService.getTimeBlock() == TimeBlock.sleep;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surfaceVariant,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.radar, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                'Preparing your challenge...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Daily Challenge",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadEverything,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // === SLEEP TIME ===
              if (isSleepTime)
                FadeTransition(
                  opacity: _anim(0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade100,
                          Colors.deepPurple.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.dark_mode,
                          size: 80,
                          color: Colors.indigo,
                        ), // Material icon
                        const SizedBox(height: 20),
                        Text(
                          "Time to Rest 🌙",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "You've earned your rest.\nCome back after 6:00 AM for a fresh challenge!",
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // === MOOD SELECTION ===
                FadeTransition(
                  opacity: _anim(0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.sentiment_satisfied,
                              size: 24,
                            ), // Material
                            const SizedBox(width: 12),
                            Text(
                              "How are you feeling today?",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: Mood.values.map((mood) {
                            final config = {
                              Mood.tired: (
                                "😴 Tired",
                                Colors.orange.shade100,
                                Icons.bedtime,
                              ),
                              Mood.low: (
                                "😔 Low",
                                Colors.blueGrey.shade100,
                                Icons.sentiment_dissatisfied,
                              ),
                              Mood.normal: (
                                "🙂 Normal",
                                Colors.lightBlue.shade100,
                                Icons.sentiment_neutral,
                              ),
                              Mood.energetic: (
                                "😄 Energetic",
                                Colors.green.shade100,
                                Icons.sentiment_very_satisfied,
                              ),
                            }[mood]!;

                            final (label, bg, icon) = config;

                            return FilterChip(
                              avatar: Icon(icon, size: 16),
                              label: Text(
                                label,
                                style: const TextStyle(fontSize: 15),
                              ),
                              selected: _currentMood == mood,
                              selectedColor: bg.withOpacity(0.4),
                              backgroundColor: Colors.grey.shade100,
                              onSelected: (_) => _onMoodChanged(mood),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // === COOLDOWN OR CHALLENGE CARD ===
                if (_inCooldown)
                  FadeTransition(
                    opacity: _anim(1),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.timer,
                              size: 60,
                              color: Colors.amber,
                            ), // Iconsax.timer exists
                            const SizedBox(height: 16),
                            Text(
                              "Great job! Take a break",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Next challenge in",
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatCooldown(_cooldownSeconds),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  FadeTransition(
                    opacity: _anim(1),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: _isStarted
                            ? LinearGradient(
                                colors: [
                                  Colors.green.shade100,
                                  Colors.teal.shade50,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _isStarted ? null : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              _isStarted
                                  ? Iconsax.frame
                                  : Icons
                                        .lightbulb, // flame = Iconsax (exists), idea = Material
                              size: 60,
                              color: _isStarted
                                  ? Colors.green.shade700
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _isStarted
                                  ? "Challenge in Progress"
                                  : "Your Daily Challenge",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isStarted
                                    ? Colors.green.shade800
                                    : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _challenge,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                height: 1.5,
                                color: _isStarted
                                    ? Colors.green.shade900
                                    : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // === ACTION BUTTONS ===
                if (!_inCooldown)
                  FadeTransition(
                    opacity: _anim(2),
                    child: Row(
                      children: [
                        if (!_isStarted) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await MoodStorage.setChallengeStarted();
                                setState(() => _isStarted = true);
                              },
                              icon: const Icon(
                                Iconsax.play,
                                size: 20,
                                color: Colors.black,
                              ),
                              label: const Text(
                                "Start Challenge",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _startNewChallenge,
                              icon: const Icon(Iconsax.refresh, size: 20),
                              label: const Text("New Challenge"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _completeChallenge,
                              icon: const Icon(Iconsax.tick_circle, size: 20),
                              label: const Text("Mark as Done"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  setState(() => _isStarted = false),
                              icon: const Icon(Iconsax.close_circle, size: 20),
                              label: const Text("Cancel"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
