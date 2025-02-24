import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerStatus { initial, running, paused, finished }

class TimerProvider with ChangeNotifier {
  static const String _settingsKey = 'timer_settings';
  Timer? _timer;
  int _duration = 25 * 60; // 기본 25분
  int _remainingTime = 25 * 60;
  TimerStatus _status = TimerStatus.initial;
  late SharedPreferences _prefs;

  TimerProvider() {
    _loadSettings();
  }

  int get duration => _duration;
  int get remainingTime => _remainingTime;
  TimerStatus get status => _status;
  double get progress => _remainingTime / _duration;

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _duration = _prefs.getInt(_settingsKey) ?? 25 * 60;
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
    _remainingTime = _duration;
    _status = TimerStatus.initial;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
