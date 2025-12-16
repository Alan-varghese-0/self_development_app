// lib/daily_challenge/daily_challenge_service.dart
import 'dart:math';
import 'package:flutter/material.dart';

enum Mood { tired, normal, energetic, low }

enum TimeBlock { morning, day, evening, night, sleep }

class DailyChallengeService {
  static TimeBlock getTimeBlock() {
    final now = TimeOfDay.now();
    final minutes = now.hour * 60 + now.minute;

    if (minutes >= 1350 || minutes < 360)
      return TimeBlock.sleep; // 22:30 – 06:00
    if (minutes < 600) return TimeBlock.morning; // 06:00 – 10:00
    if (minutes < 960) return TimeBlock.day; // 10:00 – 16:00
    if (minutes < 1230) return TimeBlock.evening; // 16:00 – 20:30
    return TimeBlock.night; // 20:30 – 22:30
  }

  static String getChallenge(Mood mood) {
    final block = getTimeBlock();
    if (block == TimeBlock.sleep)
      return "It's time to rest 🌙\nGet some sleep and come back refreshed!";

    // Expanded challenge pool
    final Map<String, List<String>> challenges = {
      // Physical – higher energy
      "physical": [
        "Take a 15-minute brisk walk outdoors",
        "Do 20 squats or lunges",
        "Stretch your full body for 10 minutes",
        "Do 3 sets of 10 push-ups",
        "Dance to your favorite song",
        "Climb stairs for 5 minutes",
        "Hold a plank for 45 seconds",
      ],
      // Productive – focus & accomplishment
      "productive": [
        "Clean or organize your workspace",
        "Read 10–15 pages of a book",
        "Plan tomorrow’s top 3 priorities",
        "Reply to one important message/email",
        "Learn one new useful fact or skill (5 min)",
        "Tidy one drawer or shelf",
        "Write a quick to-do list for the week",
      ],
      // Mental / Relaxing – suitable for low energy
      "mental": [
        "Practice 10 deep breaths (4-7-8 technique)",
        "Write down 3 things you're grateful for",
        "Meditate or sit quietly for 5 minutes",
        "Listen to calming music for 10 minutes",
        "Journal your thoughts for 5 minutes",
        "Visualize a peaceful place for 3 minutes",
        "Drink a full glass of water mindfully",
        "Do a quick body scan relaxation",
        "Smile in the mirror and say something kind to yourself",
      ],
    };

    // Determine allowed categories based on time + mood
    List<String> categories = [];

    switch (block) {
      case TimeBlock.morning:
        categories.addAll(["physical", "productive"]);
        break;
      case TimeBlock.day:
        categories.addAll(["productive", "physical"]);
        break;
      case TimeBlock.evening:
        categories.addAll(["physical", "mental", "productive"]);
        break;
      case TimeBlock.night:
        categories.addAll(["mental"]);
        break;
      default:
        break;
    }

    // Mood overrides
    if (mood == Mood.energetic) {
      // Can do everything
    } else if (mood == Mood.normal) {
      // Remove some heavy physical if in evening/night
      if (block == TimeBlock.night) categories.remove("physical");
    } else if (mood == Mood.tired || mood == Mood.low) {
      categories.removeWhere((c) => c == "physical" || c == "productive");
      categories.add("mental"); // ensure mental is available
    }

    final List options = categories
        .expand((cat) => challenges[cat] ?? [])
        .toList();

    if (options.isEmpty) {
      return "Take a moment to breathe and relax 🌿";
    }

    return options[Random().nextInt(options.length)];
  }
}
