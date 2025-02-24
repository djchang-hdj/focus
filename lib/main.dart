import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus/providers/theme_provider.dart';
import 'package:focus/theme/app_theme.dart';
import 'package:focus/providers/task_provider.dart';
import 'package:focus/widgets/task_list.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:focus/providers/timer_provider.dart';
import 'package:focus/widgets/focus_timer.dart';
import 'dart:io' show Platform;
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);

  // Windows에서 접근성 에러 로그 비활성화
  if (Platform.isWindows) {
    SemanticsBinding.instance.ensureSemantics();
  }

  // Provider 초기화 및 에러 처리
  final themeProvider = ThemeProvider();
  final taskProvider = TaskProvider();
  final timerProvider = TimerProvider();

  try {
    // Provider들의 초기화 완료 대기
    await Future.wait([
      themeProvider.initialized,
      taskProvider.initialized,
    ]);
  } catch (e) {
    debugPrint('Provider initialization error: $e');
    // 에러가 발생해도 앱은 계속 실행
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: themeProvider,
        ),
        ChangeNotifierProvider.value(
          value: taskProvider,
        ),
        ChangeNotifierProvider.value(
          value: timerProvider,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: '생각하고 말하자',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 400,
                    maxWidth: 800,
                  ),
                  child: child!,
                ),
              ),
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('생각하고 말하자'),
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 금기사항 섹션
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '금기사항',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• 유튜브, 넷플릭스, OTT 안 보기'),
                      Text('• 커뮤니티 들어가지 않기'),
                      Text('• 불필요한 웹서핑 하지 말기'),
                    ],
                  ),
                ),
              ),
            ),

            // 할 일 관리 섹션
            const TaskList(),

            // 포모도로 타이머 섹션
            Container(
              padding: const EdgeInsets.all(16.0),
              child: const FocusTimer(),
            ),

            // 명언 섹션
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      StreamBuilder<int>(
                        stream: Stream.periodic(
                            const Duration(minutes: 1), (i) => i % 4),
                        builder: (context, snapshot) {
                          final quotes = [
                            '"미래의 나에게 기대를 걸지 않는다."',
                            '"한 덩어리로 포장하지 말고, 과정을 분해하고 또 분해한다."',
                            '"막상 해보면 금방 끝나는 일이 많다."',
                            '"하루 물림이 열흘 간다."',
                          ];
                          final index = snapshot.data ?? 0;
                          return Text(
                            quotes[index],
                            style: const TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
