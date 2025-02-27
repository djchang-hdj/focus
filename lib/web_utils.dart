// 웹 환경에서만 컴파일되는 코드
// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:focus/providers/timer_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// 조건부 컴파일을 위한 import
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:convert';

// 웹 스토리지 키
const String _timerStateKey = 'focus_timer_state';

void setupWebVisibilityListener(TimerProvider timerProvider) {
  if (!kIsWeb) return;

  // 페이지 로드 시 타이머 상태 복원
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _restoreTimerStateFromLocalStorage(timerProvider);
  });

  // HTML 문서의 visibilitychange 이벤트 리스너 추가
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(
    'visibility-listener',
    (int viewId) {
      final div = html.DivElement()
        ..style.width = '0'
        ..style.height = '0';

      // 페이지 가시성 변경 이벤트 리스너 설정
      html.document.onVisibilityChange.listen((_) {
        if (html.document.visibilityState == 'visible') {
          // 페이지가 다시 보이게 되면 타이머 상태 업데이트
          debugPrint('Page is now visible, restoring timer');
          if (timerProvider.status == TimerStatus.running) {
            // 타이머가 실행 중인 경우에만 상태 업데이트
            // 타이머 상태를 업데이트하되 새 타이머를 시작하지 않음
            _updateTimerStateOnly(timerProvider);
          }
        } else if (html.document.visibilityState == 'hidden') {
          // 페이지가 숨겨질 때 타이머 상태 저장
          debugPrint('Page is now hidden, saving timer state');
          _saveTimerStateToLocalStorage(timerProvider);
        }
      });

      return div;
    },
  );

  // 페이지 종료 이벤트 리스너
  html.window.onBeforeUnload.listen((_) {
    debugPrint('Page is being unloaded, saving timer state');
    _saveTimerStateToLocalStorage(timerProvider);
  });
}

// localStorage에 타이머 상태 저장
void _saveTimerStateToLocalStorage(TimerProvider timerProvider) {
  if (!kIsWeb) return;

  try {
    // 타이머가 실행 중이거나 일시 정지 상태일 때만 저장
    if (timerProvider.status == TimerStatus.running ||
        timerProvider.status == TimerStatus.paused) {
      final timerState = {
        'status': timerProvider.status.index,
        'title': timerProvider.title,
        'initialDuration': timerProvider.initialDuration,
        'remainingTime': timerProvider.remainingTime,
        'startTimeMillis': timerProvider.startTime?.millisecondsSinceEpoch ?? 0,
        'savedTimeMillis': DateTime.now().millisecondsSinceEpoch,
      };

      final stateJson = jsonEncode(timerState);
      html.window.localStorage[_timerStateKey] = stateJson;
      debugPrint('Timer state saved to localStorage: $stateJson');
    } else if (timerProvider.status == TimerStatus.initial ||
        timerProvider.status == TimerStatus.finished) {
      // 타이머가 초기 상태이거나 완료된 경우 저장된 상태 제거
      html.window.localStorage.remove(_timerStateKey);
      debugPrint('Timer state cleared from localStorage');
    }
  } catch (e) {
    debugPrint('Error saving timer state to localStorage: $e');
  }
}

// localStorage에서 타이머 상태 복원
void _restoreTimerStateFromLocalStorage(TimerProvider timerProvider) {
  if (!kIsWeb) return;

  try {
    final stateJson = html.window.localStorage[_timerStateKey];
    if (stateJson == null || stateJson.isEmpty) {
      debugPrint('No timer state found in localStorage');
      return;
    }

    debugPrint('Found timer state in localStorage: $stateJson');

    final Map<String, dynamic> state = jsonDecode(stateJson);

    // 상태 복원에 필요한 데이터 추출
    final statusIndex = state['status'] as int;
    final status = TimerStatus.values[statusIndex];
    final title = state['title'] as String;
    final initialDuration = state['initialDuration'] as int;
    final remainingTime = state['remainingTime'] as int;
    final startTimeMillis = state['startTimeMillis'] as int;
    final savedTimeMillis = state['savedTimeMillis'] as int?;

    // 타이머가 실행 중이었던 경우 경과 시간 계산
    if (status == TimerStatus.running && savedTimeMillis != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedSinceLastSave = (now - savedTimeMillis) ~/ 1000;

      // 남은 시간 조정
      int adjustedRemainingTime = remainingTime - elapsedSinceLastSave;

      // 타이머가 실행 중이었지만 이미 끝났어야 할 경우
      if (adjustedRemainingTime <= 0) {
        debugPrint('Timer would have finished, marking as completed');
        // 타이머가 완료된 상태로 복원
        timerProvider.setTitle(title);
        timerProvider.setDuration(initialDuration ~/ 60);

        DateTime startTime =
            DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        timerProvider.restoreTimerState(
            startTime: startTime,
            initialDuration: initialDuration,
            remainingTime: 0,
            finished: true);
        timerProvider.addRecord();
      } else {
        // 타이머가 아직 실행 중이어야 하는 경우
        debugPrint(
            'Restoring running timer with $adjustedRemainingTime seconds left');
        timerProvider.setTitle(title);
        timerProvider.setDuration(initialDuration ~/ 60);

        DateTime startTime =
            DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        timerProvider.restoreTimerState(
            startTime: startTime,
            initialDuration: initialDuration,
            remainingTime: adjustedRemainingTime);

        // 웹에서 타이머 중복 실행 방지를 위해 직접 start() 호출하지 않음
        // 대신 상태만 업데이트하고 사용자가 UI에서 시작하도록 함
      }
    } else if (status == TimerStatus.paused) {
      // 일시정지 상태였을 경우 그대로 복원
      debugPrint('Restoring paused timer');
      timerProvider.setTitle(title);
      timerProvider.setDuration(initialDuration ~/ 60);

      DateTime startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
      timerProvider.restoreTimerState(
          startTime: startTime,
          initialDuration: initialDuration,
          remainingTime: remainingTime);
      // 일시 정지 상태로 설정
      timerProvider.pause();
    }

    // 상태를 복원했으므로 localStorage 데이터는 유지 (탭 닫기/열기 전환 시 필요)
    debugPrint('Timer state successfully restored');
  } catch (e) {
    debugPrint('Error restoring timer state from localStorage: $e');
    // 오류 발생 시 localStorage 데이터 삭제
    html.window.localStorage.remove(_timerStateKey);
  }
}

// 타이머 상태만 업데이트하고 새 타이머를 시작하지 않는 함수
void _updateTimerStateOnly(TimerProvider timerProvider) {
  try {
    final stateJson = html.window.localStorage[_timerStateKey];
    if (stateJson == null || stateJson.isEmpty) {
      return;
    }

    final Map<String, dynamic> state = jsonDecode(stateJson);

    // 저장된 시간 정보 추출
    final startTimeMillis = state['startTimeMillis'] as int;
    final savedTimeMillis = state['savedTimeMillis'] as int?;
    final initialDuration = state['initialDuration'] as int;

    if (savedTimeMillis != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedSinceLastSave = (now - savedTimeMillis) ~/ 1000;

      // 남은 시간 계산
      int remainingTime = state['remainingTime'] as int;
      int adjustedRemainingTime = remainingTime - elapsedSinceLastSave;

      // 타이머가 이미 끝났어야 할 경우
      if (adjustedRemainingTime <= 0) {
        timerProvider.restoreTimerState(
            startTime: DateTime.fromMillisecondsSinceEpoch(startTimeMillis),
            initialDuration: initialDuration,
            remainingTime: 0,
            finished: true);
        // 타이머 완료 처리
        timerProvider.pause();
        timerProvider.addRecord();
        html.window.localStorage.remove(_timerStateKey);
      } else {
        // 타이머가 아직 실행 중이어야 하는 경우
        // 타이머 상태만 업데이트하고 새 타이머는 시작하지 않음
        timerProvider.restoreTimerState(
          startTime: DateTime.fromMillisecondsSinceEpoch(startTimeMillis),
          initialDuration: initialDuration,
          remainingTime: adjustedRemainingTime,
        );

        // 새로운 상태 저장
        _saveTimerStateToLocalStorage(timerProvider);
      }
    }
  } catch (e) {
    debugPrint('Error updating timer state: $e');
  }
}

// 웹 환경에서 가시성 리스너 위젯을 추가하는 함수
Widget addWebVisibilityListener(Widget app) {
  if (!kIsWeb) return app;

  // 앱에 리스너 추가
  return Builder(builder: (context) {
    // 이미 Directionality가 있는 경우 (MaterialApp 내부에서 호출된 경우)
    if (Directionality.maybeOf(context) != null) {
      return Stack(
        children: [
          app,
          const SizedBox(
            width: 0,
            height: 0,
            child: HtmlElementView(viewType: 'visibility-listener'),
          ),
        ],
      );
    }

    // Directionality가 없는 경우 (앱 최상위에서 호출된 경우)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          app,
          const SizedBox(
            width: 0,
            height: 0,
            child: HtmlElementView(viewType: 'visibility-listener'),
          ),
        ],
      ),
    );
  });
}
