class JournalEntry {
  final String id;
  final String content;
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
