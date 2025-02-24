import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus/providers/theme_provider.dart';
import 'package:focus/theme/app_theme.dart';
import 'package:focus/providers/task_provider.dart';
import 'package:focus/widgets/task_list.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:focus/providers/timer_provider.dart';
import 'package:focus/widgets/focus_timer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => TimerProvider(),
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
                      Text('• 유튜브 보지 말기'),
                      Text('• SNS 하지 말기'),
                      Text('• 불필요한 웹서핑 하지 말기'),
                    ],
                  ),
                ),
              ),
            ),

            // 할 일 관리 섹션
            SizedBox(
              height: 400,
              child: const TaskList(),
            ),

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
                    children: const [
                      Text(
                        '"작은 것에 충실하자"',
                        style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '- 오늘의 명언',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
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
