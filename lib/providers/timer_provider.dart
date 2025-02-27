import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerStatus { initial, running, paused, finished }

class TimerRecord {
  final String title;
  final int initialDuration;
  final int actualDuration;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCompleted;

  TimerRecord({
    required this.title,
    required this.initialDuration,
    required this.actualDuration,
    required this.startTime,
    required this.endTime,
    required this.isCompleted,
  });

  double get progressRate => actualDuration / initialDuration;
}

class TimerProvider with ChangeNotifier {
  static const String _settingsKey = 'timer_settings';
  static const String _timerStateKey = 'timer_state';
  Timer? _timer;
  int _duration = 1800; // 기본 30분
  int _remainingTime = 1800;
  TimerStatus _status = TimerStatus.initial;
  late SharedPreferences _prefs;
  String _title = '무제';
  DateTime? _startTime;
  int _initialDuration = 1800; // 처음 설정된 시간
  final List<TimerRecord> _records = [];
  bool _isTimerBeingRestored = false; // 타이머 복원 중 플래그

  TimerProvider() {
    _loadSettings();
  }

  int get duration => _duration;
  int get remainingTime => _remainingTime;
  TimerStatus get status => _status;
  double get progress => _remainingTime / _duration;
  String get title => _title;
  DateTime? get startTime => _startTime;
  int get initialDuration => _initialDuration;
  List<TimerRecord> get records => List.unmodifiable(_records);
  bool get isRunning => _status == TimerStatus.running;

  Future<void> _loadSettings() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        _prefs = await SharedPreferences.getInstance();
        _duration = _prefs.getInt(_settingsKey) ?? 1800;
        _remainingTime = _duration;

        // 타이머 상태 복원 시도
        await restoreTimerState();

        notifyListeners();
        return;
      } catch (e) {
        retryCount++;
        debugPrint('SharedPreferences retry $retryCount/$maxRetries: $e');
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }
    }

    // 모든 재시도 실패 후 기본값 사용
    debugPrint('Using default values after all retries failed');
    _duration = 1800;
    _remainingTime = 1800;
    notifyListeners();
  }

  Future<bool> setDuration(int minutes) async {
    final oldDuration = _duration;
    try {
      _duration = minutes * 60;
      _remainingTime = _duration;

      await _prefs.setInt(_settingsKey, _duration);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving timer duration: $e');
      // 저장 실패 시 이전 상태로 복원
      _duration = oldDuration;
      _remainingTime = oldDuration;
      notifyListeners();
      return false;
    }
  }

  void start() {
    if (_status == TimerStatus.initial ||
        _status == TimerStatus.paused ||
        _status == TimerStatus.finished) {
      // 이미 타이머가 실행 중인 경우 중복 실행 방지
      if (_timer != null && _timer!.isActive) {
        debugPrint('Timer is already running, not starting a new one');
        return;
      }

      _status = TimerStatus.running;

      // Cancel any existing timer first to prevent multiple timers
      _timer?.cancel();

      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      if (_title.trim().isEmpty) {
        _title = '무제';
      }
      if (_status == TimerStatus.finished || _startTime == null) {
        _startTime = DateTime.now();
        _initialDuration = _duration;
      }

      // 타이머 상태 저장
      saveTimerState();

      notifyListeners();
    }
  }

  void pause() {
    _timer?.cancel();
    _status = TimerStatus.paused;

    // 타이머 상태 저장
    saveTimerState();

    notifyListeners();
  }

  void reset() {
    if (_status == TimerStatus.running) {
      addRecord();
    }
    _timer?.cancel();
    _duration = 1800;
    _remainingTime = _duration;
    _status = TimerStatus.initial;
    _title = '무제';
    _startTime = null;
    _initialDuration = 1800;

    // 타이머 상태 초기화
    clearTimerState();

    notifyListeners();
  }

  void _tick(Timer timer) {
    // 타이머 객체가 현재 타이머와 다른 경우 무시 (중복 타이머 방지)
    if (_timer != timer) {
      debugPrint('Ignoring tick from old timer');
      timer.cancel();
      return;
    }

    if (_remainingTime > 0) {
      _remainingTime--;

      // 웹에서 타이머가 두 배 빠르게 감소하는 문제 해결을 위한 디버그 로그
      debugPrint('Timer tick: $_remainingTime seconds remaining');

      notifyListeners();
    } else {
      timer.cancel();
      _status = TimerStatus.finished;
      addRecord();
      notifyListeners();
    }
  }

  void adjustDuration(int minutes) {
    // 최소 시간을 1분으로 설정
    final newDuration = duration + (minutes * 60);
    final newRemainingTime = remainingTime + (minutes * 60);

    // 새로운 시간이 60초(1분) 미만이면 조정하지 않음
    if (newDuration < 60 || newRemainingTime < 60) {
      return;
    }

    _duration = newDuration;
    _remainingTime = newRemainingTime;
    if (_status == TimerStatus.running) {
      _initialDuration = _duration;
    }
    notifyListeners();
  }

  void setTitle(String newTitle) {
    _title = newTitle.isEmpty ? '무제' : newTitle;
    notifyListeners();
  }

  String getTimerLog() {
    if (_startTime == null) return '';

    final endTime = DateTime.now();
    final duration = _initialDuration - _remainingTime;
    final minutes = duration ~/ 60;

    return '''
제목: $_title
설정 시간: ${_initialDuration ~/ 60}분
총 진행 시간: $minutes분
시작 시간: ${_formatDateTime(_startTime!)}
종료 시간: ${_formatDateTime(endTime)}
''';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  void addRecord() {
    if (_startTime == null) return;

    final endTime = DateTime.now();
    final duration = _initialDuration - _remainingTime;

    _records.add(TimerRecord(
      title: _title,
      initialDuration: _initialDuration,
      actualDuration: duration,
      startTime: _startTime!,
      endTime: endTime,
      isCompleted: _status == TimerStatus.finished,
    ));
    notifyListeners();
  }

  void deleteRecord(int index) {
    if (index >= 0 && index < _records.length) {
      _records.removeAt(index);
      notifyListeners();
    }
  }

  void setCurrentTask(String taskTitle) {
    setTitle(taskTitle);
  }

  Future<void> clearAllRecords() async {
    _records.clear();
    notifyListeners();
  }

  // 웹 페이지 가시성 변경 시 타이머 상태 업데이트
  void updateTimerOnVisibilityChange() {
    if (_startTime == null || _status != TimerStatus.running) return;

    // 마지막 시작 시간부터 현재까지 경과 시간 계산 (초 단위)
    final now = DateTime.now();
    final elapsedSeconds = now.difference(_startTime!).inSeconds;

    // 경과 시간이 초기 설정 시간보다 크거나 같으면 타이머 완료 처리
    if (elapsedSeconds >= _initialDuration) {
      _remainingTime = 0;
      _timer?.cancel();
      _status = TimerStatus.finished;
      addRecord();
    } else {
      // 남은 시간 업데이트
      _remainingTime = _initialDuration - elapsedSeconds;

      // 타이머가 실행 중이 아니면 다시 시작
      if (_timer == null || !_timer!.isActive) {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      }
    }

    notifyListeners();
  }

  // 타이머 상태 저장
  Future<void> saveTimerState() async {
    if (_status == TimerStatus.initial) {
      await clearTimerState();
      return;
    }

    try {
      final timerState = {
        'status': _status.index,
        'title': _title,
        'initialDuration': _initialDuration,
        'remainingTime': _remainingTime,
        'startTimeMillis': _startTime?.millisecondsSinceEpoch ?? 0,
      };

      await _prefs.setString(_timerStateKey, timerState.toString());
      debugPrint('Timer state saved: $timerState');
    } catch (e) {
      debugPrint('Error saving timer state: $e');
    }
  }

  // 타이머 상태 복원
  Future<void> restoreTimerState(
      {DateTime? startTime,
      int? initialDuration,
      int? remainingTime,
      bool finished = false}) async {
    // 이미 복원 중인 경우 중복 실행 방지
    if (_isTimerBeingRestored) return;
    _isTimerBeingRestored = true;

    try {
      // 웹 환경에서 직접 파라미터가 전달된 경우
      if (startTime != null &&
          initialDuration != null &&
          remainingTime != null) {
        debugPrint(
            'Restoring timer state from parameters: start=$startTime, initial=$initialDuration, remaining=$remainingTime, finished=$finished');
        _startTime = startTime;
        _initialDuration = initialDuration;
        _remainingTime = remainingTime;

        if (finished) {
          _status = TimerStatus.finished;
        } else {
          // 일시정지 상태로 복원 (start() 메소드에서 타이머 다시 시작)
          _status = TimerStatus.paused;
        }

        notifyListeners();
        return;
      }

      // SharedPreferences에서 복원하는 기존 로직
      try {
        final stateString = _prefs.getString(_timerStateKey);
        if (stateString == null || stateString.isEmpty) return;

        // 문자열에서 Map으로 변환
        final stateStr = stateString.replaceAll('{', '').replaceAll('}', '');
        final statePairs = stateStr.split(',');
        final Map<String, dynamic> state = {};

        for (final pair in statePairs) {
          final keyValue = pair.trim().split(':');
          if (keyValue.length == 2) {
            final key = keyValue[0].trim().replaceAll("'", "");
            final value = keyValue[1].trim();

            if (key == 'status' ||
                key == 'initialDuration' ||
                key == 'remainingTime' ||
                key == 'startTimeMillis') {
              state[key] = int.tryParse(value) ?? 0;
            } else if (key == 'title') {
              state[key] = value.replaceAll("'", "");
            }
          }
        }

        // 상태 복원
        final statusIndex = state['status'] as int;
        _status = TimerStatus.values[statusIndex];
        _title = state['title'] as String? ?? '무제';
        _initialDuration = state['initialDuration'] as int? ?? 1800;
        _remainingTime = state['remainingTime'] as int? ?? _initialDuration;

        final startTimeMillis = state['startTimeMillis'] as int?;
        if (startTimeMillis != null && startTimeMillis > 0) {
          _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        }

        // 실행 중이었던 타이머 상태 업데이트
        if (_status == TimerStatus.running) {
          updateTimerOnVisibilityChange();
        }

        debugPrint('Timer state restored: $_status, $_title, $_remainingTime');
      } catch (e) {
        debugPrint('Error restoring timer state: $e');
        // 오류 발생 시 타이머 초기화
        _status = TimerStatus.initial;
        _remainingTime = _duration;
        _startTime = null;
      }
    } finally {
      _isTimerBeingRestored = false;
    }
  }

  // 타이머 상태 초기화
  Future<void> clearTimerState() async {
    try {
      await _prefs.remove(_timerStateKey);
    } catch (e) {
      debugPrint('Error clearing timer state: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
