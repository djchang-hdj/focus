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
  List<Task> get currentTasks => _tasks[_getDateKey(_selectedDate)] ?? [];

  void selectDate(DateTime date) async {
    // Close all editors before changing the date
    closeAllTaskEditors();

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
              taskList.map((task) {
                final loadedTask = Task.fromJson(task);
                return loadedTask.copyWith(isEditing: false);
              }).toList(),
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
        return MapEntry(
            key,
            value.map((task) {
              // Reset isEditing to false when saving to ensure it doesn't persist
              final taskToSave = task.copyWith(isEditing: false);
              return taskToSave.toJson();
            }).toList());
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

    _tasks[dateKey]!.add(Task(
      id: uuid.v4(),
      title: title,
      isCompleted: false,
      date: _selectedDate,
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

  Future<bool> updateTask(String taskId, String newTitle) async {
    final dateKey = _getDateKey(_selectedDate);
    final taskIndex = _tasks[dateKey]?.indexWhere((t) => t.id == taskId) ?? -1;

    if (taskIndex != -1) {
      final oldTask = _tasks[dateKey]![taskIndex];

      // 이미 같은 제목이면 변경 없이 성공으로 간주
      if (oldTask.title == newTitle) {
        return true;
      }

      // 먼저 UI 상태 업데이트를 위해 로컬 데이터 변경
      _tasks[dateKey]![taskIndex] = oldTask.copyWith(
        title: newTitle,
        isEditing: false, // 편집 상태 종료
      );

      // UI 업데이트를 위해 리스너에게 알림
      notifyListeners();

      try {
        // 그 후 비동기적으로 저장
        final success = await _saveTasks();
        if (!success) {
          // 저장 실패 시 이전 상태로 롤백
          _tasks[dateKey]![taskIndex] = oldTask;
          notifyListeners();
          return false;
        }
        return true;
      } catch (e) {
        // 예외 발생 시 이전 상태로 롤백
        debugPrint('Error updating task: $e');
        _tasks[dateKey]![taskIndex] = oldTask;
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  void setTaskEditing(String taskId, bool isEditing) {
    final dateKey = _getDateKey(_selectedDate);
    final taskIndex = _tasks[dateKey]?.indexWhere((t) => t.id == taskId) ?? -1;

    if (taskIndex != -1) {
      final oldTask = _tasks[dateKey]![taskIndex];
      _tasks[dateKey]![taskIndex] = oldTask.copyWith(isEditing: isEditing);
      notifyListeners();
    }
  }

  Future<bool> saveTaskAndCloseEditor(String taskId, String newText) async {
    // 먼저 편집 상태를 종료하여 UI 반응성 유지
    final dateKey = _getDateKey(_selectedDate);
    final taskIndex = _tasks[dateKey]?.indexWhere((t) => t.id == taskId) ?? -1;

    if (taskIndex != -1) {
      final oldTask = _tasks[dateKey]![taskIndex];

      // 이미 편집 상태가 아니면 바로 성공 반환
      if (!oldTask.isEditing) {
        return true;
      }

      // 먼저 편집 상태만 종료하여 UI 업데이트
      _tasks[dateKey]![taskIndex] = oldTask.copyWith(isEditing: false);
      notifyListeners();

      // 그 후 내용 업데이트 (별도 비동기 작업)
      return updateTask(taskId, newText);
    }

    // 작업을 찾지 못한 경우에도 편집 상태 종료
    setTaskEditing(taskId, false);
    return true;
  }

  void closeAllTaskEditors() {
    final dateKey = _getDateKey(_selectedDate);
    if (_tasks.containsKey(dateKey)) {
      bool hasChanges = false;
      for (int i = 0; i < _tasks[dateKey]!.length; i++) {
        final task = _tasks[dateKey]![i];
        if (task.isEditing) {
          _tasks[dateKey]![i] = task.copyWith(isEditing: false);
          hasChanges = true;
        }
      }
      if (hasChanges) {
        notifyListeners();
      }
    }
  }

  Future<void> saveAndCloseAllTaskEditors(
      Map<String, TextEditingController> controllers) async {
    final dateKey = _getDateKey(_selectedDate);
    if (_tasks.containsKey(dateKey)) {
      bool hasChanges = false;
      List<Future<bool>> saveFutures = [];
      Map<String, String> tasksToSave = {};

      // 먼저 모든 편집 중인 작업 수집
      for (int i = 0; i < _tasks[dateKey]!.length; i++) {
        final task = _tasks[dateKey]![i];
        if (task.isEditing) {
          final controller = controllers[task.id];
          if (controller != null) {
            // 저장할 텍스트 캡처
            tasksToSave[task.id] = controller.text;
          }

          // 즉시 편집 상태 종료 (UI 업데이트용)
          _tasks[dateKey]![i] = task.copyWith(isEditing: false);
          hasChanges = true;
        }
      }

      // UI 즉시 업데이트
      if (hasChanges) {
        notifyListeners();
      }

      // 그 후 비동기적으로 각 작업 저장
      for (final entry in tasksToSave.entries) {
        saveFutures.add(updateTask(entry.key, entry.value));
      }

      // 모든 저장 작업 완료 대기
      if (saveFutures.isNotEmpty) {
        await Future.wait(saveFutures);
      }
    }
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

  Future<bool> removeTask(String taskId) async {
    final dateKey = _getDateKey(_selectedDate);
    if (!_tasks.containsKey(dateKey)) return false;

    // Find the task to delete
    final taskIndex = _tasks[dateKey]!.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return false;

    // Store the task before removing it
    final taskToDelete = _tasks[dateKey]![taskIndex];

    // Remove the task
    _tasks[dateKey]!.removeAt(taskIndex);

    // Save the changes
    final success = await _saveTasks();
    if (!success) {
      // If saving failed, add the task back
      _tasks[dateKey]!.add(taskToDelete);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<void> clearAllTasks() async {
    _tasks.clear();
    await _saveTasks();
    notifyListeners();
  }

  void reorderTask(int oldIndex, int newIndex) {
    final dateKey = _getDateKey(_selectedDate);
    if (!_tasks.containsKey(dateKey)) {
      return;
    }

    final tasks = _tasks[dateKey]!;
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= tasks.length ||
        newIndex >= tasks.length) {
      return;
    }

    final task = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, task);

    // 완료된 항목과 미완료 항목을 각각의 그룹으로 유지
    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? -1 : 1;
      }
      return 0;
    });

    _saveTasks(); // 변경된 순서를 저장
    notifyListeners();
  }

  Future<bool> moveTaskToDate(String taskId, DateTime newDate) async {
    final currentDateKey = _getDateKey(_selectedDate);
    final newDateKey = _getDateKey(newDate);

    // 현재 날짜에서 작업 찾기
    final taskIndex =
        _tasks[currentDateKey]?.indexWhere((t) => t.id == taskId) ?? -1;
    if (taskIndex == -1) return false;

    // 작업 복사
    final task = _tasks[currentDateKey]![taskIndex];
    final movedTask = task.copyWith(date: newDate);

    // 새 날짜의 작업 목록 초기화 (없는 경우)
    if (!_tasks.containsKey(newDateKey)) {
      _tasks[newDateKey] = [];
    }

    // 작업을 새 날짜로 이동
    _tasks[newDateKey]!.add(movedTask);
    _tasks[currentDateKey]!.removeAt(taskIndex);

    // 변경사항 저장
    final success = await _saveTasks();
    if (!success) {
      // 저장 실패 시 변경 취소
      _tasks[currentDateKey]!.insert(taskIndex, task);
      _tasks[newDateKey]?.remove(movedTask);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }
}
