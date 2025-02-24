import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerStatus { initial, running, paused, finished }

class TimerProvider with ChangeNotifier {
  static const String _settingsKey = 'timer_settings';
  Timer? _timer;
  int _duration = 1800; // 기본 30분
  int _remainingTime = 1800;
  TimerStatus _status = TimerStatus.initial;
  late SharedPreferences _prefs;
  String _title = '무제';

  TimerProvider() {
    _loadSettings();
  }

  int get duration => _duration;
  int get remainingTime => _remainingTime;
  TimerStatus get status => _status;
  double get progress => _remainingTime / _duration;
  String get title => _title;

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
      notifyListeners();
    }
  }

  void pause() {
    _timer?.cancel();
    _status = TimerStatus.paused;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _duration = 1800; // 30분으로 고정
    _remainingTime = _duration;
    _status = TimerStatus.initial;
    _title = '무제'; // 리셋할 때 타이틀도 초기화
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
      notifyListeners();
    }
  }

  void setTitle(String newTitle) {
    _title = newTitle.isEmpty ? '무제' : newTitle;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
