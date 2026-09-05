import 'package:flutter/material.dart';

/// 宠动Keep 设计规范 v2 — 暗色运动风（Spotify 式「内容优先的暗」）
/// 底色：近黑绿调  卡面：炭绿阶  主色：荧光薄荷（仅功能性使用）
/// 点缀：珊瑚橙  数据：天蓝
/// 尺寸/字号等非颜色令牌见 [AppDimens]（app_dimens.dart）。
///
/// 层级规则（Spotify §6）：bg(cream) → card(sand) → 卡片内嵌(card 高一阶)
/// → 弹层用重阴影。绿只在「可交互/进行中/成功」语义出现，不做大面积底色。
class AppColors {
  AppColors._();

  // 主色系 - 荧光薄荷（暗底下提亮，仅用于交互态/进度/主按钮）
  static const Color mint = Color(0xFF2BD973);
  /// 卡面/输入底上的绿色微调面（替代旧"淡绿底"角色）
  static const Color mintLight = Color(0xFF17251D);
  /// 渐变头图的终止绿（与 [mint] 组成品牌英雄渐变：亮→深）
  static const Color mintBright = Color(0xFF0E9F5C);
  /// 绿色淡描边（mintLight 填充的卡片边框伴侣色）
  static const Color mintLine = Color(0xFF1F3A2E);

  // 辅色系 - 天蓝（数据/信息）
  static const Color sky = Color(0xFF14232F);
  static const Color skyDeep = Color(0xFF4AA3E8);
  /// 天蓝淡描边
  static const Color skyLine = Color(0xFF1E3A4D);

  // 点缀色 - 珊瑚橙（警示/能量）
  static const Color coral = Color(0xFFFF7A5C);
  static const Color coralLight = Color(0xFF2A1A15);
  /// 珊瑚渐变终止色（健康页头图）
  static const Color coralDeep = Color(0xFFE85A35);
  /// 珊瑚淡描边
  static const Color coralLine = Color(0xFF46271D);

  // 语义色 - 提示/警告（开发标识、预警文案底）
  static const Color warning = Color(0xFF2B2413);
  static const Color warningText = Color(0xFFF5C36B);

  // 中性色（近黑绿阶：cream 是页面底，sand 高一阶，card 再高一阶）
  static const Color cream = Color(0xFF0D1210);
  static const Color sand = Color(0xFF151C18);
  static const Color text = Color(0xFFEDF2EF);
  static const Color textSoft = Color(0xFF9AA8A1);
  static const Color textMute = Color(0xFF5F6E67);
  static const Color card = Color(0xFF1A231F);
  static const Color line = Color(0xFF26302B);

  /// 强调面（绿色渐变/珊瑚渐变）之上的文字与图标
  static const Color onAccent = Color(0xFFFFFFFF);

  /// 英雄渐变：五处页头共用的品牌渐变配方
  static const LinearGradient heroGradient = LinearGradient(
    colors: [mint, mintBright],
  );
}
