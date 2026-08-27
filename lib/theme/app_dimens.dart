import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 宠动Keep 非颜色设计令牌：圆角 / 间距 / 字号 / 共享表面配方。
///
/// 约定：
/// - 圆角只允许 {rXs,rSm,rMd,rLg,rXl,rFull} 六档；
/// - 间距走严格 4 级制（sp4..sp60），禁止 6/10/13/14 这类偏格值；
/// - 字号九档，emoji 与登录大标题等展示字形豁免；
/// - 表面一律优先复用 [cardBox]，不要再手写 decoration。
class AppDimens {
  AppDimens._();

  // ---- 圆角 ----
  static const double rXs = 4;
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 20;
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

  /// 共享表面配方：填充色 + 可选描边 + 统一大圆角。
  /// 白卡：cardBox()；粉彩卡：cardBox(color: AppColors.sky, borderColor: AppColors.skyLine)。
  static BoxDecoration cardBox({Color color = AppColors.card, Color? borderColor}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(rLg),
      border:
          borderColor == null ? null : Border.all(color: borderColor),
    );
  }
}
