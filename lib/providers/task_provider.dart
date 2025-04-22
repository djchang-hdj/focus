import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

class TaskProvider with ChangeNotifier {
  static const String _tasksKey = 'tasks';
  static const uuid = Uuid();
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
  List<Task> get currentTasks {
    final tasks = _tasks[_getDateKey(_selectedDate)] ?? [];

    // 완료 상태와 order로 정렬
    return tasks
      ..sort((a, b) {
        // 먼저 완료 상태로 정렬
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? -1 : 1; // 완료된 항목이 위로
        }
        // 같은 완료 상태 내에서는 order로 정렬
        return a.order.compareTo(b.order);
      });
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTasks() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        _prefs = await SharedPreferences.getInstance();
        final tasksJson = _prefs.getString(_tasksKey);

        if (tasksJson != null) {
          final tasksMap = json.decode(tasksJson) as Map<String, dynamic>;
          _tasks = tasksMap.map((key, value) {
            final List<dynamic> taskList = value;
            return MapEntry(
              key,
              taskList.map((task) => Task.fromJson(task)).toList(),
            );
          });
        }

        _isInitialized = true;
        notifyListeners();
        _initializationCompleter.complete();
        return;
      } catch (e) {
        retryCount++;
        debugPrint('Tasks loading retry $retryCount/$maxRetries: $e');
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }
    }

    // 모든 재시도 실패 후 기본값 사용
    debugPrint('Using empty tasks after all retries failed');
    _tasks = {};
    _isInitialized = true;
    notifyListeners();
    _initializationCompleter.complete();
  }

  Future<bool> _saveTasks() async {
    try {
      final tasksJson = json.encode(_tasks.map((key, value) {
        return MapEntry(key, value.map((task) => task.toJson()).toList());
      }));
      await _prefs.setString(_tasksKey, tasksJson);
      return true;
    } catch (e) {
      debugPrint('Error saving tasks: $e');
      return false;
    }
  }

  Future<bool> addTask(String title) async {
    final dateKey = _getDateKey(_selectedDate);
    if (!_tasks.containsKey(dateKey)) {
      _tasks[dateKey] = [];
    }

    // 새 작업의 order 계산
    final maxOrder = _tasks[dateKey]!.isEmpty
        ? 0
        : _tasks[dateKey]!.map((t) => t.order).reduce((a, b) => a > b ? a : b);

    _tasks[dateKey]!.add(Task(
      id: uuid.v4(),
      title: title,
      isCompleted: false,
      date: _selectedDate,
      order: maxOrder + 10, // 새 작업은 항상 맨 아래에 추가
    ));

    final success = await _saveTasks();
    if (!success) {
      _tasks[dateKey]?.removeLast();
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> toggleTask(String taskId) async {
    final dateKey = _getDateKey(_selectedDate);
    final taskIndex = _tasks[dateKey]?.indexWhere((t) => t.id == taskId) ?? -1;

    if (taskIndex != -1) {
      final previousState = _tasks[dateKey]![taskIndex].isCompleted;
      _tasks[dateKey]![taskIndex].isCompleted = !previousState;

      final success = await _saveTasks();
      if (!success) {
        _tasks[dateKey]![taskIndex].isCompleted = previousState;
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteTask(String taskId) async {
    final dateKey = _getDateKey(_selectedDate);
    final taskToDelete =
        _tasks[dateKey]?.firstWhere((task) => task.id == taskId);
    if (taskToDelete == null) return false;

    _tasks[dateKey]?.removeWhere((task) => task.id == taskId);

    final success = await _saveTasks();
    if (!success) {
      _tasks[dateKey]?.add(taskToDelete);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> moveTaskToDate(String taskId, DateTime targetDate) async {
    final currentDateKey = _getDateKey(_selectedDate);
    final targetDateKey = _getDateKey(targetDate);

    final taskIndex =
        _tasks[currentDateKey]?.indexWhere((t) => t.id == taskId) ?? -1;

    if (taskIndex == -1) return false;

    final taskToMove = _tasks[currentDateKey]![taskIndex];

    if (!_tasks.containsKey(targetDateKey)) {
      _tasks[targetDateKey] = [];
    }

    final duplicateTaskIndex =
        _tasks[targetDateKey]?.indexWhere((t) => t.title == taskToMove.title) ??
            -1;

    if (duplicateTaskIndex != -1) {
      _tasks[currentDateKey]!.removeAt(taskIndex);
      final success = await _saveTasks();
      if (!success) {
        _tasks[currentDateKey]!.insert(taskIndex, taskToMove);
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    }

    final movedTask = taskToMove.copyWith(date: targetDate);

    _tasks[currentDateKey]!.removeAt(taskIndex);

    _tasks[targetDateKey]!.add(movedTask);

    final success = await _saveTasks();
    if (!success) {
      _tasks[currentDateKey]!.insert(taskIndex, taskToMove);
      _tasks[targetDateKey]!.remove(movedTask);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> updateTask(String taskId, String newTitle) async {
    final dateKey = _getDateKey(_selectedDate);
    final taskIndex = _tasks[dateKey]?.indexWhere((t) => t.id == taskId) ?? -1;

    if (taskIndex != -1) {
      final oldTask = _tasks[dateKey]![taskIndex];
      _tasks[dateKey]![taskIndex] = oldTask.copyWith(title: newTitle);

      final success = await _saveTasks();
      if (!success) {
        _tasks[dateKey]![taskIndex] = oldTask;
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  double get completionRate {
    final tasks = currentTasks;
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((task) => task.isCompleted).length;
    return completed / tasks.length;
  }

  Future<bool> reorderTasks(int oldIndex, int newIndex) async {
    final dateKey = _getDateKey(_selectedDate);
    if (!_tasks.containsKey(dateKey) || _tasks[dateKey]!.isEmpty) {
      return false;
    }

    final tasks = currentTasks;
    if (oldIndex < 0 ||
        oldIndex >= tasks.length ||
        newIndex < 0 ||
        newIndex >= tasks.length) {
      return false;
    }

    // 이동할 작업
    final taskToMove = tasks[oldIndex];
    final isCompleted = taskToMove.isCompleted;

    // 같은 완료 상태를 가진 작업들만 필터링
    final sameCompletionTasks =
        tasks.where((t) => t.isCompleted == isCompleted).toList();

    // 이전 상태 저장
    final List<Task> previousTasks = List.from(_tasks[dateKey]!);

    // 모든 작업의 order 재조정
    for (var i = 0; i < _tasks[dateKey]!.length; i++) {
      _tasks[dateKey]![i] = _tasks[dateKey]![i].copyWith(order: i * 10);
    }

    // 이동할 작업의 새 order 계산
    int newOrder;
    if (newIndex == 0) {
      // 맨 위로 이동
      newOrder = _tasks[dateKey]!.first.order - 10;
    } else if (newIndex >= _tasks[dateKey]!.length) {
      // 맨 아래로 이동
      newOrder = _tasks[dateKey]!.last.order + 10;
    } else {
      // 중간으로 이동
      final prevOrder = _tasks[dateKey]![newIndex - 1].order;
      final nextOrder = _tasks[dateKey]![newIndex].order;
      newOrder = prevOrder + ((nextOrder - prevOrder) ~/ 2);
    }

    // 작업 이동
    _tasks[dateKey]!.removeWhere((t) => t.id == taskToMove.id);
    final movedTask = taskToMove.copyWith(order: newOrder);

    // 새 위치에 삽입
    var insertIndex = 0;
    while (insertIndex < _tasks[dateKey]!.length &&
        _tasks[dateKey]![insertIndex].order < newOrder) {
      insertIndex++;
    }
    _tasks[dateKey]!.insert(insertIndex, movedTask);

    // 변경사항 저장
    final success = await _saveTasks();
    if (!success) {
      _tasks[dateKey] = previousTasks;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  void initializeDefaultTasks() {
    final dateKey = _getDateKey(_selectedDate);
    if (!_tasks.containsKey(dateKey)) {
      _tasks[dateKey] = [];
    }

    _tasks[dateKey]!.addAll([
      Task(
        id: uuid.v4(),
        title: '운동하기',
        isCompleted: false,
        date: _selectedDate,
      ),
      Task(
        id: uuid.v4(),
        title: '독서하기',
        isCompleted: false,
        date: _selectedDate,
      ),
      Task(
        id: uuid.v4(),
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

  Future<void> clearAllTasks() async {
    _tasks.clear();
    await _saveTasks();
    notifyListeners();
  }
}
