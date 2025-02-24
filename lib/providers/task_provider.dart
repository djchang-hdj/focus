import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'dart:async';

class TaskProvider with ChangeNotifier {
  static const String _tasksKey = 'tasks';
  late SharedPreferences _prefs;
  Map<String, List<Task>> _tasks = {};
  DateTime _selectedDate = DateTime.now();
  bool _isInitialized = false;

  final Completer<void> _initializationCompleter = Completer<void>();
  Future<void> get initialized => _initializationCompleter.future;

  TaskProvider() {
    _loadTasks();
  }

  bool get isInitialized => _isInitialized;

  DateTime get selectedDate => _selectedDate;
  List<Task> get currentTasks => _tasks[_getDateKey(_selectedDate)] ?? [];

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTasks() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final tasksJson = _prefs.getString(_tasksKey);
      if (tasksJson != null) {
        try {
          final tasksMap = json.decode(tasksJson) as Map<String, dynamic>;
          _tasks = tasksMap.map((key, value) {
            final List<dynamic> taskList = value;
            return MapEntry(
              key,
              taskList.map((task) => Task.fromJson(task)).toList(),
            );
          });
        } catch (e) {
          debugPrint('Error loading tasks: $e');
          _tasks = {};
        }
      }
      _isInitialized = true;
      notifyListeners();
      _initializationCompleter.complete();
    } catch (e) {
      _initializationCompleter.completeError(e);
      rethrow;
    }
  }

  Future<void> _saveTasks() async {
    final tasksJson = json.encode(_tasks.map((key, value) {
      return MapEntry(key, value.map((task) => task.toJson()).toList());
    }));
    await _prefs.setString(_tasksKey, tasksJson);
  }

  Future<void> addTask(String title) async {
    final dateKey = _getDateKey(_selectedDate);
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: _selectedDate,
    );

    if (!_tasks.containsKey(dateKey)) {
      _tasks[dateKey] = [];
    }
    _tasks[dateKey]!.add(task);

    await _saveTasks();
    notifyListeners();
  }

  Future<void> toggleTask(String taskId) async {
    final dateKey = _getDateKey(_selectedDate);
    final taskIndex = _tasks[dateKey]?.indexWhere((t) => t.id == taskId) ?? -1;

    if (taskIndex != -1) {
      _tasks[dateKey]![taskIndex].isCompleted =
          !_tasks[dateKey]![taskIndex].isCompleted;
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    final dateKey = _getDateKey(_selectedDate);
    _tasks[dateKey]?.removeWhere((task) => task.id == taskId);
    await _saveTasks();
    notifyListeners();
  }

  double get completionRate {
    final tasks = currentTasks;
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((task) => task.isCompleted).length;
    return completed / tasks.length;
  }

  void initializeDefaultTasks() {
    final dateKey = _getDateKey(_selectedDate);
    if (!_tasks.containsKey(dateKey)) {
      _tasks[dateKey] = [];
    }

    _tasks[dateKey]!.addAll([
      Task(
        id: DateTime.now().toString() + '1',
        title: '운동하기',
        isCompleted: false,
        date: _selectedDate,
      ),
      Task(
        id: DateTime.now().toString() + '2',
        title: '독서하기',
        isCompleted: false,
        date: _selectedDate,
      ),
      Task(
        id: DateTime.now().toString() + '3',
        title: '코딩하기',
        isCompleted: false,
        date: _selectedDate,
      ),
    ]);

    notifyListeners();
  }

  void removeTask(String taskId) {
    final dateKey = _getDateKey(_selectedDate);
    _tasks[dateKey]?.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }
}
