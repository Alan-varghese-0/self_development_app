// lib/daily_challenge/mood_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_challenge_service.dart';

class MoodStorage {
  static const _moodKey = 'user_mood';
  static const _challengeKey = 'daily_challenge';
  static const _dateKey = 'challenge_date';
  static const _statusKey = 'challenge_status';

  // Mood
  static Future<void> saveMood(Mood mood) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_moodKey, mood.index);
  }

  static Future<Mood> loadMood() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_moodKey);
    return Mood.values[index ?? Mood.normal.index];
  }

  // Challenge persistence
  static Future<void> saveChallenge(String challenge) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;

    await prefs.setString(_challengeKey, challenge);
    await prefs.setString(_dateKey, today);
    await prefs.setString(_statusKey, 'idle');
  }

  static Future<Map<String, String?>> loadChallengeData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final savedDate = prefs.getString(_dateKey);

    if (savedDate != today) {
      return {'challenge': null, 'status': 'idle'};
    }

    return {
      'challenge': prefs.getString(_challengeKey),
      'status': prefs.getString(_statusKey) ?? 'idle',
    };
  }

  static Future<void> setChallengeStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, 'started');
  }

  // Fully reset / generate new challenge (used for Skip or after completion)
  static Future<void> generateNewChallenge(Mood mood) async {
    final newChallenge = DailyChallengeService.getChallenge(mood);
    await saveChallenge(newChallenge);
  }

  // Clear everything (used after completion → cooldown period)
  static Future<void> clearChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_challengeKey);
    await prefs.remove(_dateKey);
    await prefs.remove(_statusKey);
  }
}
