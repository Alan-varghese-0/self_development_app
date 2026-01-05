class AiProjectDay {
  final String id;
  final String projectId;
  final DateTime date;
  final String title;
  final List<String> tasks;
  final List<bool> taskStatus;
  final int status;

  AiProjectDay({
    required this.id,
    required this.projectId,
    required this.date,
    required this.title,
    required this.tasks,
    required this.taskStatus,
    required this.status,
  });

  factory AiProjectDay.fromMap(Map<String, dynamic> m) {
    return AiProjectDay(
      id: m['id'],
      projectId: m['project_id'],
      date: DateTime.parse(m['date']),
      title: m['title'],
      tasks: List<String>.from(m['tasks']),
      taskStatus: List<bool>.from(m['task_status']),
      status: m['status'],
    );
  }
}
