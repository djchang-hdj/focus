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
    // 타임아웃을 추가하여 무한 대기 방지
    await Future.wait([
      themeProvider.initialized.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Theme initialization timed out');
          return null;
        },
      ),
      taskProvider.initialized.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Task initialization timed out');
          return null;
        },
      ),
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Focus',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const MacosScaffold(), // 새로운 macOS 스타일 스캐폴드
          );
        },
      ),
    );
  }
}

class MacosScaffold extends StatefulWidget {
  const MacosScaffold({super.key});

  @override
  State<MacosScaffold> createState() => _MacosScaffoldState();
}

class _MacosScaffoldState extends State<MacosScaffold> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _timerKey = GlobalKey();

  void scrollToTimer() {
    final context = _timerKey.currentContext;
    if (context != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!context.mounted) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 450,
          maxWidth: 800,
        ),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              // macOS 스타일 타이틀바
              Container(
                height: 28,
                color: Colors.transparent,
                child: Row(
                  children: [
                    const Spacer(),
                    // 테마 토글 버튼
                    MacosIconButton(
                      context: context,
                      icon: Icons.dark_mode,
                      onPressed: () {
                        context.read<ThemeProvider>().toggleTheme();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              // 메인 컨텐츠
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const AppHeader(),
                        const SizedBox(height: 20),
                        TaskList(onTimerStart: scrollToTimer),
                        const SizedBox(height: 32),
                        FocusTimer(key: _timerKey),
                        const SizedBox(height: 32),
                        // 금기사항 섹션
                        _buildProhibitedSection(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProhibitedSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '집중을 유지하기 위해',
                  style: Theme.of(context).textTheme.titleLarge,
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

// macOS 스타일 아이콘 버튼
class MacosIconButton extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final VoidCallback onPressed;

  const MacosIconButton({
    super.key,
    required this.context,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
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
                // 데이터 삭제 버튼
                IconButton(
                  onPressed: () => _showClearDataDialog(context),
                  icon: Icon(
                    Icons.delete_forever_rounded,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: '모든 데이터 삭제',
                ),
                const SizedBox(width: 8),
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
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withAlpha(38),
                colorScheme.secondary.withAlpha(38),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withAlpha(51),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  currentQuote.icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  currentQuote.text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.3,
                        letterSpacing: 0.3,
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

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
          size: 32,
        ),
        title: const Text('모든 데이터 삭제'),
        content: const Text(
          '정말로 모든 데이터를 삭제하시겠습니까?\n'
          '이 작업은 되돌릴 수 없으며, 모든 할 일과 타이머 기록이 영구적으로 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
              final navigator = Navigator.of(dialogContext);
              final taskProvider = dialogContext.read<TaskProvider>();
              final timerProvider = dialogContext.read<TimerProvider>();

              // 모든 데이터 삭제
              await taskProvider.clearAllTasks();
              await timerProvider.clearAllRecords();

              navigator.pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('모든 데이터가 삭제되었습니다.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class QuoteData {
  final String text;
  final IconData icon;

  QuoteData({required this.text, required this.icon});
}
