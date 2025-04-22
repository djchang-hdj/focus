class Task {
  final String id;
  final String title;
  bool isCompleted;
  final DateTime date;
  bool isEditing;
  bool isHovered;
  int order;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.isEditing = false,
    this.isHovered = false,
    this.order = 0,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? date,
    bool? isEditing,
    bool? isHovered,
    int? order,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      isEditing: isEditing ?? this.isEditing,
      isHovered: isHovered ?? this.isHovered,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
      'isEditing': isEditing,
      'order': order,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] ?? false,
      date: DateTime.parse(json['date']),
      isEditing: json['isEditing'] ?? false,
      isHovered: false,
      order: json['order'] as int? ?? 0,
    );
  }
}
