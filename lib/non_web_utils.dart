import 'package:flutter/material.dart';
import 'package:focus/providers/timer_provider.dart';

void setupWebVisibilityListener(TimerProvider timerProvider) {
  // 비웹 환경에서는 아무 작업도 수행하지 않음
}

// 비웹 환경에서는 원래 앱을 그대로 반환
Widget addWebVisibilityListener(Widget app) {
  return app;
}
