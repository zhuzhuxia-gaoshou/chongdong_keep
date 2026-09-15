import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// 宠动Keep 主题配置
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      // 画布比卡片深半档（AppColors.canvas），白卡凭投影自然浮起
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.mint,
        secondary: AppColors.skyDeep,
        error: AppColors.coral,
        surface: AppColors.card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.text,
      ),
      // 波纹柔化：极淡薄荷水纹，按压主反馈交给 PressableScale 缩放
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.mint.withValues(alpha: 0.08),
      highlightColor: AppColors.mint.withValues(alpha: 0.04),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.rLg),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
          // 竖向 14 为按钮专用偏格值（历史定稿，非 4 级制），保留
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: AppDimens.sp24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.rFull),
          ),
          textStyle: const TextStyle(
            fontSize: AppDimens.fsSub,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(
              vertical: 13, horizontal: AppDimens.sp24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.rFull),
          ),
          textStyle: const TextStyle(
            fontSize: AppDimens.fsBodyMid,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.rMd),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.rMd),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.rMd),
          borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: const TextStyle(
          fontSize: AppDimens.fsFoot,
          color: AppColors.textSoft,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          fontSize: AppDimens.fsBodyMid,
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
        insetPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.sp16, vertical: AppDimens.sp12),
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
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppDimens.rXl)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
      // 时间选择器：ColorScheme 未覆盖的槽位（primaryContainer 等）会走
      // Material 基线蓝，这里把 AM/PM 选择块、表盘指针等全部统一成薄荷绿
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.card,
        hourMinuteTextColor: AppColors.text,
        hourMinuteColor: AppColors.sand,
        dialHandColor: AppColors.mint,
        dialBackgroundColor: AppColors.sand,
        dialTextColor: AppColors.text,
        dayPeriodColor: AppColors.mintLight,
        dayPeriodTextColor: AppColors.text,
        dayPeriodBorderSide: const BorderSide(color: AppColors.line),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.rMd),
        ),
        helpTextStyle: const TextStyle(
            fontSize: AppDimens.fsBody, color: AppColors.textSoft),
        cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: AppColors.textSoft),
        confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: AppColors.mint,
            textStyle: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.mint,
        linearTrackColor: AppColors.sand,
      ),
      // 字号全部走 AppDimens 档位（D1-6 等值归档，视觉零变化）
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: AppDimens.fsDisplay, fontWeight: FontWeight.w700, color: AppColors.text),
        headlineMedium: TextStyle(fontSize: AppDimens.fsHeadline, fontWeight: FontWeight.w700, color: AppColors.text),
        titleLarge: TextStyle(fontSize: AppDimens.fsTitle, fontWeight: FontWeight.w600, color: AppColors.text),
        titleMedium: TextStyle(fontSize: AppDimens.fsSub, fontWeight: FontWeight.w600, color: AppColors.text),
        bodyLarge: TextStyle(fontSize: AppDimens.fsBodyMid, fontWeight: FontWeight.w500, color: AppColors.text),
        bodyMedium: TextStyle(fontSize: AppDimens.fsBody, fontWeight: FontWeight.w500, color: AppColors.text),
        bodySmall: TextStyle(fontSize: AppDimens.fsCaption, fontWeight: FontWeight.w500, color: AppColors.textSoft),
        labelLarge: TextStyle(fontSize: AppDimens.fsBody, fontWeight: FontWeight.w600, color: AppColors.text),
        labelSmall: TextStyle(fontSize: AppDimens.fsMicro, fontWeight: FontWeight.w600, color: AppColors.textSoft),
      ),
    );
  }
}

/// 数字展示体（2026-09 字重交响）：
/// 高级感核心=「大号细体数字 + 紧字距」，与全局 w500/w600 正文形成大小对比。
/// 原则：数据数字永远走这里，禁止再用 w800 粗体堆数字。
///
/// 豁免清单（2026-09-15 生产就绪验证员裁定留档，下轮审计以此为准，勿误报）：
/// share_card_page（海报版式，文件头有声明）、login_page 品牌字标、
/// pet_detail/profile 宠物名昵称标题、walk_page 头像首字、各页空态标题。
class AppText {
  AppText._();

  /// Hero 级：首页今日目标的大数字（浅底用 text 色，深底用 white）
  static TextStyle numericHero({Color color = AppColors.text}) => TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
        height: 1.0,
        color: color,
      );

  /// 区块级：周报完成率、连胜天数等（28-32px 观感）
  static TextStyle numericSection({Color color = AppColors.text}) => TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.8,
        height: 1.05,
        color: color,
      );

  /// 行内级：列表行的距离/时长（16-18px 观感）
  static TextStyle numericInline({Color color = AppColors.text}) => TextStyle(
        fontSize: AppDimens.fsTitle,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        height: 1.1,
        color: color,
      );

  /// 统计数值级：StatTile 等小空间数字（20px 中粗+紧字距；
  /// 2026-09-15 起 w800 数据数字全面退役，统一走本档）
  static TextStyle numericStat({Color color = AppColors.text}) => TextStyle(
        fontSize: AppDimens.fsStat,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.1,
        color: color,
      );
}
