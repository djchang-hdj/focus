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

  TimerRecord({
    required this.title,
    required this.initialDuration,
    required this.actualDuration,
    required this.startTime,
    required this.endTime,
  });
}

class TimerProvider with ChangeNotifier {
  static const String _settingsKey = 'timer_settings';
  Timer? _timer;
  int _duration = 1800; // 기본 30분
  int _remainingTime = 1800;
  TimerStatus _status = TimerStatus.initial;
  late SharedPreferences _prefs;
  String _title = '무제';
  DateTime? _startTime;
  int _initialDuration = 1800; // 처음 설정된 시간
  final List<TimerRecord> _records = [];

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

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _duration = _prefs.getInt(_settingsKey) ?? 1800;
    _remainingTime = _duration;
    notifyListeners();
  }

  Future<void> setDuration(int minutes) async {
    _duration = minutes * 60;
    _remainingTime = _duration;
    await _prefs.setInt(_settingsKey, _duration);
    notifyListeners();
  }

  void start() {
    if (_status == TimerStatus.initial || _status == TimerStatus.paused) {
      _status = TimerStatus.running;
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      if (_title.trim().isEmpty) {
        _title = '무제';
      }
      if (_startTime == null) {
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
      notifyListeners();
    }
  }

  void adjustDuration(int minutes) {
    final newDuration = duration + (minutes * 60);
    final newRemainingTime = remainingTime + (minutes * 60);

    if (newDuration >= 0 && newRemainingTime >= 0) {
      _duration = newDuration;
      _remainingTime = newRemainingTime;
      if (_status == TimerStatus.running) {
        _initialDuration = _duration;
      }
      notifyListeners();
    }
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
    ));
    notifyListeners();
  }

  void deleteRecord(int index) {
    if (index >= 0 && index < _records.length) {
      _records.removeAt(index);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
