class Todo {
  final String id;
  final String title;
  final String? description;
  final bool isDone;
  final bool pinned;
  final DateTime? reminderTime;
  final String priority;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.isDone = false,
    this.pinned = false,
    this.reminderTime,
    String? priority,
  }) : priority = priority ?? (reminderTime != null ? 'high' : 'normal');
  

  factory Todo.fromMap(Map<String, dynamic> map, String documentId) {
    return Todo(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'],
      isDone: map['isDone'] ?? false,
      pinned: map['pinned'] ?? false,
      reminderTime: map['reminderTime'] != null
          ? DateTime.tryParse(map['reminderTime'])
          : null,
      priority: map['priority'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isDone': isDone,
      'pinned': pinned,
      'reminderTime': reminderTime?.toIso8601String(),
      'priority': priority,
    };
  }
}
