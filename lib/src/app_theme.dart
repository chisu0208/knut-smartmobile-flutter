import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 새 화면용 Material 3 테마(개선판 2차). 2차의 탭 막대·학식·교통·출결·도서관 탭은 2026-10-29에
/// 되돌려 지금 앱에서는 쓰지 않고, 새 화면을 다시 만들 때 쓴다.
///
/// 색은 팀원 Figma 토큰([AppColors]), 글자는 시스템 글꼴이다. 크기·굵기는 Figma 기준
/// (화면 제목 24 Black, 섹션 18 Bold, 카드 제목 15 Bold, 본문 13 Regular, 배지 11 Bold)을
/// 따르고, 목록 한 줄(메뉴·시각)은 읽기 쉽게 15로 둔다. 글자는 휴대폰 글자 크기 설정을 따른다.
///
/// 1차의 원본 모양 위젯(헤더·푸터 버튼, alert·dialog 대화상자)은 앱 테마(`SmartMobileApp.theme`,
/// Material 2)를 그대로 써서 모양이 바뀌지 않는다.
abstract final class AppTheme {
  static const TextTheme _text = TextTheme(
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w900,
      color: AppColors.ink,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
      height: 1.35,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
      height: 1.35,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.ink,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.sub,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.sub,
      height: 1.35,
    ),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
  );

  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.sub,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.primarySoft,
    onSecondaryContainer: AppColors.primaryDark,
    tertiary: AppColors.amber,
    onTertiary: Colors.white,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.sub,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: AppColors.bg,
    surfaceContainerHigh: AppColors.bg,
    surfaceContainerHighest: AppColors.line,
    outline: AppColors.sub,
    outlineVariant: AppColors.line,
  );

  static final ThemeData material3 = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: _text,
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primarySoft,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.sub,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )
            : const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.sub,
              ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.sub,
      indicatorColor: AppColors.primary,
      dividerColor: AppColors.line,
      labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.primarySoft
              : Colors.white,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDark
              : AppColors.ink,
        ),
        side: const WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: AppColors.line),
        ),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.primarySoft,
      checkmarkColor: AppColors.primaryDark,
      side: BorderSide(color: AppColors.line),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
