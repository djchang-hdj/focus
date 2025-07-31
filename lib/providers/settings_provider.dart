import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _timerDurationKey = 'timer_duration';

  late SharedPreferences _prefs;
  int _timerDuration = 30;

  int get timerDuration => _timerDuration;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _timerDuration = _prefs.getInt(_timerDurationKey) ?? 30;
    notifyListeners();
  }

  Future<void> setTimerDuration(int duration) async {
    _timerDuration = duration;
    await _prefs.setInt(_timerDurationKey, duration);
    notifyListeners();
  }
}
