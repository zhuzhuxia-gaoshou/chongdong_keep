import 'package:flutter/material.dart';

/// 宠动Keep 设计规范 - 清爽专业风
/// 主色：薄荷绿  底色：米白  点缀：珊瑚橙
/// 尺寸/字号等非颜色令牌见 [AppDimens]（app_dimens.dart）。
class AppColors {
  AppColors._();

  // 主色系 - 薄荷绿
  static const Color mint = Color(0xFF4CAF82);
  static const Color mintLight = Color(0xFFE8F5EF);
  /// 渐变头图的终止绿（与 [mint] 组成品牌英雄渐变）
  static const Color mintBright = Color(0xFF6BC89D);
  /// 薄荷淡描边（mintLight 填充的卡片边框伴侣色）
  static const Color mintLine = Color(0xFFD0E9DC);

  // 辅色系 - 天蓝
  static const Color sky = Color(0xFFE4F2FC);
  static const Color skyDeep = Color(0xFF4A9FD9);
  /// 天蓝淡描边
  static const Color skyLine = Color(0xFFD4E8F7);

  // 点缀色 - 珊瑚橙
  static const Color coral = Color(0xFFFF8A65);
  static const Color coralLight = Color(0xFFFFE8DF);
  /// 珊瑚渐变终止色（健康页头图）
  static const Color coralDeep = Color(0xFFEE6D45);
  /// 珊瑚淡描边
  static const Color coralLine = Color(0xFFFFD9C8);

  // 语义色 - 提示/警告（开发标识、预警文案底）
  static const Color warning = Color(0xFFFFF3CD);
  static const Color warningText = Color(0xFF8A6D3B);

  // 中性色
  static const Color cream = Color(0xFFFBF9F5);
  static const Color sand = Color(0xFFF5F1EA);
  static const Color text = Color(0xFF2E3A3B);
  static const Color textSoft = Color(0xFF7A8688);
  static const Color textMute = Color(0xFFA8B0B2);
  static const Color card = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFECEAE5);

  /// 英雄渐变：五处页头共用的品牌渐变配方
  static const LinearGradient heroGradient = LinearGradient(
    colors: [mint, mintBright],
  );
}
