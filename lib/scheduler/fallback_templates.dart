List<Map<String, dynamic>> fallbackSchedule({
  required int totalDays,
  required String title,
}) {
  final phases = [
    "Planning & Research",
    "Setup Project Structure",
    "UI Design & Prototyping",
    "Core Feature Implementation",
    "Authentication & Backend",
    "Testing & Bug Fixes",
    "Polish & Final Review",
  ];

  return List.generate(totalDays, (i) {
    final phaseIndex = (i / totalDays * phases.length).floor();
    final phase = phases[phaseIndex.clamp(0, phases.length - 1)];

    return {
      "day": i + 1,
      "title": "Day ${i + 1}: $phase",
      "tasks": [
        "Work on $phase",
        "Implement key features",
        "Test functionality",
        "Refactor code if needed",
      ],
    };
  });
}
