import 'dart:async';
import 'dart:convert';
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

  // 날짜 포맷 (YYYY-MM-DD)
  String get dateKey =>
      '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';

  // JSON 변환을 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'initialDuration': initialDuration,
      'actualDuration': actualDuration,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
  }

  // JSON에서 객체 생성을 위한 팩토리 메서드
  factory TimerRecord.fromJson(Map<String, dynamic> json) {
    return TimerRecord(
      title: json['title'] as String,
      initialDuration: json['initialDuration'] as int,
      actualDuration: json['actualDuration'] as int,
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime'] as int),
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

class TimerProvider with ChangeNotifier {
  static const String _settingsKey = 'timer_settings';
  static const String _recordsKey = 'timer_records';
  Timer? _timer;
  int _duration = 1800; // 기본 30분
  int _remainingTime = 1800;
  TimerStatus _status = TimerStatus.initial;
  late SharedPreferences _prefs;
  String _title = '무제';
  DateTime? _startTime;
  int _initialDuration = 1800; // 처음 설정된 시간

  // 날짜별 기록 저장을 위한 맵
  final Map<String, List<TimerRecord>> _recordsByDate = {};

  TimerProvider() {
    _loadSettings();
    _loadRecords();
  }

  int get duration => _duration;
  int get remainingTime => _remainingTime;
  TimerStatus get status => _status;
  // 진행률 계산 - 시간이 지날수록 값이 작아지는 방식 (1.0에서 시작해서 0.0으로 줄어듦)
  double get progress => _remainingTime / _duration;
  String get title => _title;
  DateTime? get startTime => _startTime;
  int get initialDuration => _initialDuration;

  // 모든 타이머 기록을 날짜별 그룹화 없이 가져옴
  List<TimerRecord> get allRecords {
    final List<TimerRecord> allRecords = [];
    _recordsByDate.values.forEach(allRecords.addAll);
    return List.unmodifiable(allRecords);
  }

  // 날짜별로 그룹화된 타이머 기록을 가져옴
  Map<String, List<TimerRecord>> get recordsByDate =>
      Map.unmodifiable(_recordsByDate);

  // 특정 날짜의 타이머 기록만 가져옴
  List<TimerRecord> getRecordsForDate(String date) {
    return List.unmodifiable(_recordsByDate[date] ?? []);
  }

  // 최근 7일간의 타이머 기록을 가져옴
  Map<String, List<TimerRecord>> getRecentRecords({int days = 7}) {
    final now = DateTime.now();
    final Map<String, List<TimerRecord>> result = {};

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (_recordsByDate.containsKey(dateKey)) {
        result[dateKey] = List.unmodifiable(_recordsByDate[dateKey]!);
      }
    }

    return Map.unmodifiable(result);
  }

  bool get isRunning => _status == TimerStatus.running;

  Future<void> _loadSettings() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        _prefs = await SharedPreferences.getInstance();
        _duration = _prefs.getInt(_settingsKey) ?? 1800;
        _remainingTime = _duration;
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

  // 저장된 타이머 기록 불러오기
  Future<void> _loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getString(_recordsKey);

      if (recordsJson != null) {
        final Map<String, dynamic> recordsMap = jsonDecode(recordsJson);

        _recordsByDate.clear();
        recordsMap.forEach((date, records) {
          final List<dynamic> recordsList = records as List<dynamic>;
          _recordsByDate[date] = recordsList
              .map((record) =>
                  TimerRecord.fromJson(record as Map<String, dynamic>))
              .toList();
        });

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading timer records: $e');
    }
  }

  // 타이머 기록 저장하기
  Future<void> _saveRecords() async {
    try {
      final recordsMap = <String, dynamic>{};

      _recordsByDate.forEach((date, records) {
        recordsMap[date] = records.map((record) => record.toJson()).toList();
      });

      final recordsJson = jsonEncode(recordsMap);
      await _prefs.setString(_recordsKey, recordsJson);
    } catch (e) {
      debugPrint('Error saving timer records: $e');
    }
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
      _status = TimerStatus.running;
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      if (_title.trim().isEmpty) {
        _title = '무제';
      }
      if (_status == TimerStatus.finished) {
        _startTime = DateTime.now();
        _initialDuration = _duration;
      } else if (_startTime == null) {
        _startTime = DateTime.now();
        _initialDuration = _duration;
      }
      notifyListeners();
    }
  }

  void pause() {
    _timer?.cancel();
    _status = TimerStatus.paused;
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
    notifyListeners();
  }

  void _tick(Timer timer) {
    if (_remainingTime > 0) {
      _remainingTime--;
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

    final record = TimerRecord(
      title: _title,
      initialDuration: _initialDuration,
      actualDuration: duration,
      startTime: _startTime!,
      endTime: endTime,
      isCompleted: _status == TimerStatus.finished,
    );

    // 날짜별로 기록 추가
    final dateKey = record.dateKey;
    if (!_recordsByDate.containsKey(dateKey)) {
      _recordsByDate[dateKey] = [];
    }
    _recordsByDate[dateKey]!.add(record);

    // 기록 저장
    _saveRecords();

    notifyListeners();
  }

  void deleteRecord(String dateKey, int index) {
    if (_recordsByDate.containsKey(dateKey) &&
        index >= 0 &&
        index < _recordsByDate[dateKey]!.length) {
      _recordsByDate[dateKey]!.removeAt(index);

      // 날짜에 기록이 없으면 해당 날짜 키도 제거
      if (_recordsByDate[dateKey]!.isEmpty) {
        _recordsByDate.remove(dateKey);
      }

      _saveRecords();
      notifyListeners();
    }
  }

  void setCurrentTask(String taskTitle) {
    setTitle(taskTitle);
  }

  Future<void> clearAllRecords() async {
    _recordsByDate.clear();
    await _prefs.remove(_recordsKey);
    notifyListeners();
  }

  // 특정 날짜의 기록만 삭제
  Future<void> clearRecordsForDate(String dateKey) async {
    if (_recordsByDate.containsKey(dateKey)) {
      _recordsByDate.remove(dateKey);
      _saveRecords();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
