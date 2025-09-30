class Task {
  final String taskId;
  final String userId;
  final String taskClass;
  final String type;
  final int createdAt;
  final int? until;
  final String status;
  final String title;
  final String description;
  final int priority;
  final int? completedAt;
  final int exp;
  final int? target;
  final int? progress;

  Task({
    required this.taskId,
    required this.userId,
    required this.taskClass,
    required this.type,
    required this.createdAt,
    required this.until,
    required this.status,
    required this.title,
    required this.description,
    required this.priority,
    required this.completedAt,
    required this.exp,
    required this.target,
    required this.progress,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['task_id'],
      userId: json['user_id'],
      taskClass: json['task_class'],
      type: json['type'],
      createdAt: json['created_at'],
      until: json['until'],
      status: json['status'],
      title: json['title'],
      description: json['content']?['description'] ?? '',
      priority: json['priority'],
      completedAt: json['completed_at'],
      exp: json['exp'],
      target: json['target'],
      progress: json['progress'],
    );
  }

  bool get completed => status == 'completed';
}
