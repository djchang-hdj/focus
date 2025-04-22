import 'package:flutter/material.dart';

class AppTheme {
  // 기본 색상 정의 - 더 세련된 색상으로 업데이트
  static const Color primaryColorLight = Color(0xFF6366F1); // Indigo
  static const Color primaryColorDark = Color(0xFF818CF8); // Light Indigo
  static const Color accentColorLight = Color(0xFFFF9500); // 더 선명한 Amber
  static const Color accentColorDark = Color(0xFFFFB340); // 더 선명한 Light Amber

  // 추가 색상 정의
  static const Color successColor = Color(0xFF34C759);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color infoColor = Color(0xFF5AC8FA);

  // 공통 테마 데이터
  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final textTheme = TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0.15,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 14,
        height: 1.5,
        letterSpacing: 0.15,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      fontFamily: 'NotoSans',

      // 앱바 테마
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // Card 테마
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.1),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        color: colorScheme.surface,
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),

      // Text 버튼 테마
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),

      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Checkbox 테마
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        splashRadius: 0,
      ),

      // 스위치 테마
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.3);
          }
          return colorScheme.outlineVariant.withOpacity(0.3);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // FAB 테마
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // 스낵바 테마
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.surfaceContainerHigh,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // 다이얼로그 테마
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // 리스트타일 테마
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),

      // 진행상태 표시자 테마
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // 구분선 테마
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: primaryColorLight,
      secondary: accentColorLight,
      surface: Color(0xFFF8FAFC),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF9FAFB),
      surfaceContainer: Color(0xFFF3F4F6),
      surfaceContainerHigh: Color(0xFFE5E7EB),
      surfaceContainerHighest: Color(0xFFD1D5DB),
      onSurface: Color(0xFF1F2937),
      onSurfaceVariant: Color(0xFF4B5563),
      outline: Color(0xFF9CA3AF),
      outlineVariant: Color(0xFFE5E7EB),
      error: errorColor,
      onError: Colors.white,
    );

    return _baseTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: primaryColorDark,
      secondary: accentColorDark,
      surface: Color(0xFF1E293B),
      surfaceContainerLowest: Color(0xFF0F172A),
      surfaceContainerLow: Color(0xFF1E293B),
      surfaceContainer: Color(0xFF334155),
      surfaceContainerHigh: Color(0xFF475569),
      surfaceContainerHighest: Color(0xFF64748B),
      onSurface: Color(0xFFF1F5F9),
      onSurfaceVariant: Color(0xFFCBD5E1),
      outline: Color(0xFF94A3B8),
      outlineVariant: Color(0xFF334155),
      error: Color(0xFFFCA5A5),
      onError: Color(0xFF7F1D1D),
    );

    return _baseTheme(colorScheme);
  }
}
