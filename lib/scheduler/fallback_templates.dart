List<Map<String, dynamic>> fallbackSchedule({
  required int totalDays,
  required String title,
}) {
  final List<Map<String, dynamic>> out = [];

  for (int i = 1; i <= totalDays; i++) {
    out.add({
      "day": i,
      "title": "Work on $title",
      "tasks": [
        "Review previous work",
        "Continue core development",
        "Test & note improvements",
      ],
    });
  }

  return out;
}
