import 'package:flutter/material.dart';

class AppTheme {
  // macOS 스타일 색상 정의
  static const Color primaryColorLight = Color(0xFF007AFF); // Apple Blue
  static const Color primaryColorDark = Color(0xFF0A84FF); // Apple Blue (Dark)
  static const Color accentColorLight = Color(0xFF34C759); // Apple Green
  static const Color accentColorDark = Color(0xFF30D158); // Apple Green (Dark)

  // 공통 테마 데이터
  static ThemeData _baseTheme(ColorScheme colorScheme) {
    const sfProDisplay = '.SF Pro Display'; // macOS 시스템 폰트
    const sfProText = '.SF Pro Text';

    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: sfProDisplay,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: sfProDisplay,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontFamily: sfProDisplay,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: sfProText,
        fontSize: 16,
        height: 1.5,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,

      // macOS 스타일 카드 테마
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: colorScheme.outline.withAlpha(25),
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),

      // macOS 스타일 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),

      // macOS 스타일 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: colorScheme.outline.withAlpha(76),
          ),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
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
