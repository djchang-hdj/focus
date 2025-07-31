import 'package:focus/pages/settings_page.dart';
import 'package:focus/providers/settings_provider.dart';
import 'package:focus/services/notification_service.dart';
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

  final NotificationService notificationService = NotificationService();
  await notificationService.init();

  // Windows에서 접근성 에러 로그 비활성화
  if (Platform.isWindows) {
    SemanticsBinding.instance.ensureSemantics();
  }

  // Provider 초기화 및 에러 처리
  final themeProvider = ThemeProvider();
  final taskProvider = TaskProvider();
  final settingsProvider = SettingsProvider();
  final timerProvider = TimerProvider(notificationService: notificationService, settingsProvider: settingsProvider);

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
        ChangeNotifierProvider.value(
          value: settingsProvider,
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _timerKey = GlobalKey();

  void scrollToTimer() {
    final context = _timerKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더 위젯
                  const AppHeader(),

                  // 메인 콘텐츠 영역
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),

                        // 할 일 관리 섹션 - 구별되는 색상 배경
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer.withOpacity(0.6),
                                colorScheme.primaryContainer.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  colorScheme.outlineVariant.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.all(2),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TaskList(onTimerStart: scrollToTimer),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 타이머 섹션 - 구별되는 색상 배경
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.secondary.withOpacity(0.3),
                                colorScheme.tertiary.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  colorScheme.outlineVariant.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.all(2),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: FocusTimer(key: _timerKey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 금기사항 섹션 - 구별되는 색상 배경
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.errorContainer.withOpacity(0.6),
                                colorScheme.errorContainer.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  colorScheme.outlineVariant.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.all(2),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: colorScheme.error,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '집중을 유지하기 위해',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildProhibitedItem(
                                    context,
                                    Icons.play_circle_outline,
                                    '유튜브, 넷플릭스, OTT 안 보기',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildProhibitedItem(
                                    context,
                                    Icons.forum_outlined,
                                    '커뮤니티 들어가지 않기',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildProhibitedItem(
                                    context,
                                    Icons.public_outlined,
                                    '불필요한 웹서핑 하지 말기',
                                  ),
                                ],
                              ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPlatformDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 상단 영역 (타이틀 및 버튼)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 로고 및 타이틀
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '생각하고 말하자',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 데이터 삭제 버튼
                  _buildHeaderButton(
                    context: context,
                    icon: Icons.delete_forever_rounded,
                    label: '',
                    color: colorScheme.error,
                    onTap: () => _showClearDataDialog(context),
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
                  const SizedBox(width: 8),
                  // 설정 버튼
                  _buildHeaderButton(
                    context: context,
                    icon: Icons.settings_outlined,
                    label: '',
                    color: colorScheme.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 동기부여 문구 섹션
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: StreamBuilder<int>(
                      stream: Stream.periodic(
                          const Duration(seconds: 10), (i) => i % 4),
                      builder: (context, snapshot) {
                        final icons = [
                          Icons.update_disabled_outlined,
                          Icons.format_list_numbered_outlined,
                          Icons.bolt_outlined,
                          Icons.calendar_today_outlined,
                        ];

                        return Icon(
                          icons[snapshot.data ?? 0],
                          color: colorScheme.secondary,
                          size: 22,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: Stream.periodic(
                          const Duration(seconds: 10), (i) => i % 4),
                      builder: (context, snapshot) {
                        final quotes = [
                          "미래의 나에게 기대를 걸지 않는다",
                          "덩어리로 하지 말고 과정을 분해하라",
                          "막상 해보면 금방 끝나는 일이 많다",
                          "하루 물림이 열흘 간다",
                        ];

                        return Text(
                          quotes[snapshot.data ?? 0],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.3,
                            letterSpacing: -0.3,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 오늘의 통계
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '오늘의 통계',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Consumer<TaskProvider>(
                  builder: (context, taskProvider, _) {
                    final completionRate =
                        (taskProvider.completionRate * 100).toStringAsFixed(1);
                    final totalTasks = taskProvider.currentTasks.length;
                    final completedTasks = taskProvider.currentTasks
                        .where((task) => task.isCompleted)
                        .length;

                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    colorScheme.outlineVariant.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.tertiary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: colorScheme.tertiary
                                              .withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.analytics_outlined,
                                        size: 14,
                                        color: colorScheme.tertiary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '오늘의 달성률',
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '$completionRate%',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    colorScheme.outlineVariant.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.tertiary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: colorScheme.tertiary
                                              .withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.task_alt_outlined,
                                        size: 14,
                                        color: colorScheme.tertiary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '완료한 일',
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '$completedTasks / $totalTasks',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: themeProvider.toggleTheme,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
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
              color: colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_rounded,
          color: colorScheme.error,
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
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
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