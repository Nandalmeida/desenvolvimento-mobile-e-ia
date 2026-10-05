class SubTask {
  String title;
  bool done;

  SubTask({required this.title, this.done = false});

  Map<String, dynamic> toJson() => {'title': title, 'done': done};

  factory SubTask.fromJson(Map<String, dynamic> j) =>
      SubTask(title: j['title'] as String, done: j['done'] as bool? ?? false);
}

/// Prioridade: 0 = baixa, 1 = média, 2 = alta
class Task {
  final String id;
  String title;
  bool done;
  int priority;
  List<SubTask> subtasks;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.done = false,
    this.priority = 1,
    List<SubTask>? subtasks,
    DateTime? createdAt,
  })  : subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'priority': priority,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String,
        done: j['done'] as bool? ?? false,
        priority: j['priority'] as int? ?? 1,
        subtasks: (j['subtasks'] as List? ?? [])
            .map((e) => SubTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}
