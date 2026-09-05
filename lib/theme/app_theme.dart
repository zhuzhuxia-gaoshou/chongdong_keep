import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// 宠动Keep 主题配置
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.mint,
        secondary: AppColors.skyDeep,
        error: AppColors.coral,
        surface: AppColors.card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.text,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.textSoft,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textMute,
        ),
      ),
      // 底部导航为 main_page 自定义实现，不走 BottomNavigationBar，故无对应主题位
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: const TextStyle(
            fontSize: AppDimens.fsBody, color: AppColors.card),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.rMd),
        ),
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.rLg),
        ),
        titleTextStyle: const TextStyle(
          fontSize: AppDimens.fsTitle,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        contentTextStyle: const TextStyle(
          fontSize: AppDimens.fsBodyMid,
          color: AppColors.text,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.mint,
        unselectedLabelColor: AppColors.textMute,
        indicatorColor: AppColors.mint,
        dividerColor: AppColors.line,
        labelStyle:
            TextStyle(fontSize: AppDimens.fsBodyMid, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: AppDimens.fsBodyMid, fontWeight: FontWeight.w500),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states
                .contains(WidgetState.selected)
            ? AppColors.mint
            : const Color(0xFFE0E0E0)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.mintLight
                : AppColors.sand),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        modalBackgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.mint,
        linearTrackColor: AppColors.sand,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text),
        bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSoft),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSoft),
      ),
    );
  }
}
