import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  final Completer<void> _initializationCompleter = Completer<void>();

  Future<void> get initialized => _initializationCompleter.future;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedTheme = _prefs.getString(_themeKey);
      if (savedTheme != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.system,
        );
        notifyListeners();
      }
      _initializationCompleter.complete();
    } catch (e) {
      debugPrint('Theme initialization failed: $e');
      // 기본값으로 복구
      _themeMode = ThemeMode.system;
      notifyListeners();
      _initializationCompleter.complete(); // 에러가 있어도 초기화 완료로 처리
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.toString());
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final isLightMode = _themeMode == ThemeMode.light;
    await setThemeMode(isLightMode ? ThemeMode.dark : ThemeMode.light);
  }
}
