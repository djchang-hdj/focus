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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 새로운 헤더 위젯
                  const AppHeader(),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // 할 일 관리 섹션
                        const TaskList(),

                        const SizedBox(height: 16),
                        // 포모도로 타이머 섹션
                        const FocusTimer(),

                        const SizedBox(height: 16),
                        // 금기사항 섹션
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '집중을 유지하기 위해',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildProhibitedItem(
                                  context,
                                  Icons.play_circle_outline,
                                  '유튜브, 넷플릭스, OTT 안 보기',
                                ),
                                const SizedBox(height: 8),
                                _buildProhibitedItem(
                                  context,
                                  Icons.forum_outlined,
                                  '커뮤니티 들어가지 않기',
                                ),
                                const SizedBox(height: 8),
                                _buildProhibitedItem(
                                  context,
                                  Icons.public_outlined,
                                  '불필요한 웹서핑 하지 말기',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProhibitedItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlatformDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 상단 영역
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 로고 및 타이틀
                Expanded(
                  child: Text(
                    '생각하고 말하자',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // 테마 토글 버튼
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => _buildThemeToggle(
                    context,
                    isPlatformDark,
                    themeProvider,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 동기부여 문구 섹션
            _buildMotivationalQuote(context),

            const SizedBox(height: 24),

            // 오늘의 통계
            _buildTodayStats(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: themeProvider.toggleTheme,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return RotationTransition(
                turns: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              key: ValueKey<bool>(isDark),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalQuote(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 10), (i) => i % 4),
      builder: (context, snapshot) {
        final quotes = [
          QuoteData(
            text: "미래의 나에게 기대를 걸지 않는다",
            icon: Icons.update_disabled_outlined,
          ),
          QuoteData(
            text: "덩어리로 하지 말고 과정을 분해하라",
            icon: Icons.format_list_numbered_outlined,
          ),
          QuoteData(
            text: "막상 해보면 금방 끝나는 일이 많다",
            icon: Icons.bolt_outlined,
          ),
          QuoteData(
            text: "하루 물림이 열흘 간다",
            icon: Icons.calendar_today_outlined,
          ),
        ];

        final currentQuote = quotes[snapshot.data ?? 0];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                currentQuote.icon,
                color: Theme.of(context).colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  currentQuote.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayStats(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final completionRate =
            (taskProvider.completionRate * 100).toStringAsFixed(1);
        final totalTasks = taskProvider.currentTasks.length;
        final completedTasks =
            taskProvider.currentTasks.where((task) => task.isCompleted).length;

        return Row(
          children: [
            _buildStatCard(
              context,
              '오늘의 달성률',
              '$completionRate%',
              Icons.analytics_outlined,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              context,
              '완료한 일',
              '$completedTasks / $totalTasks',
              Icons.task_alt_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuoteData {
  final String text;
  final IconData icon;

  QuoteData({required this.text, required this.icon});
}
