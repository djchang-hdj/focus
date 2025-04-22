class Task {
  final String id;
  final String title;
  bool isCompleted;
  final DateTime date;
  bool isEditing;
  bool isHovered;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.isEditing = false,
    this.isHovered = false,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? date,
    bool? isEditing,
    bool? isHovered,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      isEditing: isEditing ?? this.isEditing,
      isHovered: isHovered ?? this.isHovered,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
      'isEditing': isEditing,
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
    );
  }
}
