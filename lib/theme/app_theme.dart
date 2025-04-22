import 'package:flutter/material.dart';

class AppTheme {
  // 기본 색상 정의
  static const Color primaryColorLight = Color(0xFF6366F1); // Indigo
  static const Color primaryColorDark = Color(0xFF818CF8); // Light Indigo
  static const Color accentColorLight = Color(0xFFF59E0B); // Amber
  static const Color accentColorDark = Color(0xFFFBBF24); // Light Amber

  // 공통 테마 데이터
  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final textTheme = TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 16,
        height: 1.5,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      fontFamily: 'NotoSans',

      // Card 테마
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),

      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // FAB 테마
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // 스낵바 테마
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // 다이얼로그 테마
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: primaryColorLight,
      secondary: accentColorLight,
      surface: Color(0xFFF8FAFC),
      surfaceContainer: Colors.white,
      error: Color(0xFFDC2626),
    );

    return _baseTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: primaryColorDark,
      secondary: accentColorDark,
      surface: Color(0xFF1E293B),
      surfaceContainer: Color(0xFF0F172A),
      error: Color(0xFFFCA5A5),
    );

    return _baseTheme(colorScheme);
  }
}
