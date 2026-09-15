import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 宠动Keep 非颜色设计令牌：圆角 / 间距 / 字号 / 共享表面配方。
///
/// 约定：
/// - 圆角只允许 {rXs,rSm,rMd,rLg,rXl,rXxl,rFull} 七档（rXxl 限悬浮 Dock/大面积容器）；
/// - 间距走严格 4 级制（sp4..sp60），禁止 6/10/13/14 这类偏格值；
/// - 字号十档（fsDisplay 为 2026-09-15 D1-6 补档），emoji 与登录大标题等展示字形豁免；
/// - 表面一律优先复用 [cardBox]，不要再手写 decoration。
/// 人读版契约见 docs/DESIGN_SYSTEM.md（v3）。
class AppDimens {
  AppDimens._();

  // ---- 圆角 ----
  static const double rXs = 4;
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 20;
  static const double rXxl = 28; // 悬浮 Dock / 大面积容器
  static const double rFull = 999;

  // ---- 间距（严格 4 级制）----
  static const double sp4 = 4;
  static const double sp8 = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp32 = 32;
  static const double sp40 = 40;
  static const double sp60 = 60;

  // ---- 字号（≤10 档）----
  static const double fsMicro = 10; // 微标签（统计/徽章说明）
  static const double fsCaption = 11; // 注脚、协议小字
  static const double fsFoot = 12; // 分区标题、字段 label
  static const double fsBody = 13; // 正文-小
  static const double fsBodyMid = 14; // 正文（PRD 规范正文）
  static const double fsSub = 15; // 强调正文/弹窗标题
  static const double fsTitle = 17; // 页面级标题
  static const double fsHeadline = 18; // 区块大字
  static const double fsStat = 20; // 统计数值
  static const double fsDisplay = 24; // 展示级标题（textTheme.headlineLarge，2026-09-15 D1-6 补档）

  // ---- 图标尺寸（2026-09-15 D1-2）----
  // 功能 Icon 的 size 一律走这三档，禁止字面量；
  // 装饰性大字号（PageHero 爪印水印/EmptyState emoji 等 Text 字形）不在其列。
  static const double iconSm = 16; // 行内小图标（按钮内联/紧凑行尾）
  static const double iconMd = 20; // 常规功能图标（菜单尾箭头/列表行）
  static const double iconLg = 24; // 大号功能图标（宫格/空态引导）

  /// 共享表面配方：填充色 + 可选描边 + 统一大圆角 + 分层投影。
  ///
  /// 投影规则（2026-09 质感升级）：白色卡片且未显式描边时默认携带
  /// [shadowCard]（接触影+环境影双层），浮起于画布之上；
  /// 粉彩 tonal 卡（sky/coral 等）与描边卡保持平面，避免脏影。
  ///
  /// 密集宫格禁令（2026-09-15 D1-4）：格间距 ≤ sp8 的宫格不得用默认双层影
  /// （环境影 offset 6 / blur 16 外扩约 22px，必压邻格），改传 borderColor
  /// 走描边平面；[radius] 用于与同格位选中态的圆角对齐，避免切换跳变。
  static BoxDecoration cardBox({
    Color color = AppColors.card,
    Color? borderColor,
    List<BoxShadow>? shadow,
    double radius = rLg,
  }) {
    final effectiveShadow = shadow ??
        (color == AppColors.card && borderColor == null ? shadowCard : null);
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border:
          borderColor == null ? null : Border.all(color: borderColor),
      boxShadow: effectiveShadow,
    );
  }

  /// 描边浮起卡（2026-09-15 D1-1）：白底 + line 描边 + 轻接触影。
  /// 用于「带描边但仍需与画布分离」的表面——典型如选中/未选中双态卡的
  /// 未选中面（tonal 选中面保持平面）。影基色同 [shadowCard] 族。
  static BoxDecoration cardElevatedOutline({
    Color color = AppColors.card,
    Color borderColor = AppColors.line,
    double borderWidth = 1,
    double radius = rLg,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: shadowCardLight,
    );
  }

  // ---- 投影刻度（2026-09 质感底座）----
  // 以 text 色相为影基色，双层结构：一层紧贴接触影定边缘、一层大范围环境影造深度。
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x0A2E3A3B), // 4% text
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x102E3A3B), // 6% text
      offset: Offset(0, 6),
      blurRadius: 16,
    ),
  ];

  /// 悬浮元素（Dock/浮层）：更收拢、更高一档
  static const List<BoxShadow> shadowFloat = [
    BoxShadow(
      color: Color(0x1A2E3A3B), // 10% text
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  /// 轻接触影：描边卡的浮起伴侣（2026-09-15 D1-1 收编 add_pet_page
  /// 手写的 Colors.black 4% 单层影——影基色统一走 text 色相 2E3A3B 族，
  /// 禁止裸黑，与 [shadowCard] 同族但更轻更近，不与描边打架）。
  static const List<BoxShadow> shadowCardLight = [
    BoxShadow(
      color: Color(0x0A2E3A3B), // 4% text
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  /// 显式无影
  static const List<BoxShadow> shadowNone = [];
}
