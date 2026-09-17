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
  /// 薄荷深端：Hero 渐变的收尾色（mint → mintDeep，营造沉稳收束）
  static const Color mintDeep = Color(0xFF2E7D5F);
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

  /// 中间风险级（症状自查「建议观察」档，2026-09-15 从页面私造色 0xFFFFB74D 收编）
  static const Color amber = Color(0xFFFFB74D);
  static const Color amberLight = Color(0xFFFFF3E0);

  /// 急救渐变：健康/急救页的紧急语义强调（2026-09-15 配方化，
  /// 属「唯一主角」豁免的语义色——急救场景允许第二渐变）
  static const LinearGradient coralGradient = LinearGradient(
    colors: [coral, coralDeep],
  );

  // 海报模板色（2026-09-15 D2-1 从 share_card_page 页面私造色收编）：
  /// 导出海报的模板身份色——属内容生成面的版式语言，非 UI 语义色，
  /// 不参与界面用色；仅分享卡片模板切换处引用（板外禁用）。
  static const Color posterMagazine = Color(0xFF7E57C2);
  static const Color posterData = Color(0xFF26C6DA);
  static const Color posterNight = Color(0xFF37474F);

  /// 海报浅底墨色（2026-09-17 R5 守门员 HOLD 返工收编）：海报三套浅底版式
  /// （mint 可爱 / posterData 数据 / coral 生日）主文字与辅文专用，[text]
  /// 同青灰色相（186°）加深——text(#2E3A3B) 压 mint WCAG 实算仅 4.35:1，
  /// 低于 AA 正文 4.5 红线；其 72% alpha 派生辅文 2.80~3.50:1 更不达标。
  /// posterInk 全色直用、辅文不再 alpha 派生（层级靠字号/字重）。
  /// WCAG 相对亮度实算（mint L=0.3381 / coral L=0.4038 / posterData
  /// L=0.4586 / posterInk L=0.0212）：posterInk 压 mint ≈5.45:1、
  /// 压 coral ≈6.37:1、压 posterData ≈7.14:1，均 ≥4.5:1；压胶囊底
  /// （35% 白罩 mint，L=0.5122）≈7.89:1。App 界面（板外）禁用。
  static const Color posterInk = Color(0xFF1F2A2B);

  // 中性色
  static const Color cream = Color(0xFFFBF9F5);
  static const Color sand = Color(0xFFF5F1EA);
  /// 页面画布：比 cream 深半档，让白色卡片自然浮起（高级感的光影基础）
  static const Color canvas = Color(0xFFF3EFE8);
  static const Color text = Color(0xFF2E3A3B);
  static const Color textSoft = Color(0xFF7A8688);
  static const Color textMute = Color(0xFFA8B0B2);
  static const Color card = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFECEAE5);

  /// 强调面（绿色/珊瑚渐变）之上的文字与图标
  static const Color onAccent = Color(0xFFFFFFFF);

  /// 英雄渐变：五处页头共用的品牌渐变配方
  static const LinearGradient heroGradient = LinearGradient(
    colors: [mint, mintBright],
  );
}
