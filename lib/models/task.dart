class Task {
  final String id;
  final String title;
  bool isCompleted;
  final DateTime date;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? date,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'],
      date: DateTime.parse(json['date']),
    );
  }
}
