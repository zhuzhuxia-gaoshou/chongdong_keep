import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';

/// 页面英雄头（2026-09-15 质感 v2）：品牌渐变 + 装饰圆 + 爪印水印 +
/// 白字标题/副标题 + 头像/动作插槽。给主要页面统一的「开头仪式感」。
/// 高度由内容决定（不写死），底部大圆角压在画布上。
class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.child,
    this.gradient = AppColors.heroGradient,
    this.watermark = '🐾',
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// 头部下沿的扩展内容（如统计行），会获得完整宽度。
  final Widget? child;
  final LinearGradient gradient;

  /// 右下角装饰水印（内容性 emoji，属品牌元素而非功能图标）
  final String watermark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimens.rXxl),
        ),
      ),
      child: Stack(
        children: [
          // 装饰层：静态低透明度图形（非动画，无入场依赖）
          Positioned(
            right: -28,
            top: -34,
            child: _decorCircle(96, 0.10),
          ),
          Positioned(
            left: -20,
            bottom: 18,
            child: _decorCircle(64, 0.08),
          ),
          Positioned(
            right: 18,
            bottom: 6,
            child: Transform.rotate(
              angle: -0.35,
              child: Text(watermark,
                  style: TextStyle(
                    fontSize: 64,
                    color: Colors.white.withValues(alpha: 0.14),
                  )),
            ),
          ),
          // 内容层
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.sp20, AppDimens.sp8, AppDimens.sp20, AppDimens.sp20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: AppDimens.sp12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppDimens.fsHeadline,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onAccent,
                              height: 1.2,
                            ),
                          ),
                          if (subtitle != null &&
                              subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppDimens.fsBody,
                                color:
                                    Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                if (child != null) ...[
                  const SizedBox(height: AppDimens.sp16),
                  child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

/// 品牌空态（2026-09-15）：爪印圆 + 标题 + 温柔文案 + 可选 CTA。
/// mainAxisSize.min——放进 Center/ListView 任意有界环境都安全。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.sp32, vertical: AppDimens.sp40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mintLight,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: AppDimens.sp16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppDimens.fsSub,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: AppDimens.sp8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppDimens.fsBody,
                height: 1.5,
                color: AppColors.textSoft,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDimens.sp20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// 图标章（2026-09-15）：着色圆角方块图标底，设置/菜单行的统一前导。
/// 取代散落各页的 emoji 前导与裸图标，配色走 tonal（浅底+深图标）。
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    this.background = AppColors.mintLight,
    this.color = AppColors.mint,
    this.size = 36,
  });

  final IconData icon;
  final Color background;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimens.rMd),
      ),
      child: Icon(icon, size: size * 0.56, color: color),
    );
  }
}

/// 分区容器：白底描边卡片 + 可选软标题。
/// 统一 settings/profile 各自克隆的分区壳写法。
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
                left: AppDimens.sp4, bottom: AppDimens.sp8),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: AppDimens.fsFoot,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.textSoft,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimens.rLg),
            // 描边淡化半档，主深度交给双层投影（P1 质感底座）
            border: Border.all(color: AppColors.line.withValues(alpha: 0.55)),
            boxShadow: AppDimens.shadowCard,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// 统一胶囊 chip（2026-09-15 D1-3）：一处组件承载三种形态——
/// ① 选中/未选中双态胶囊（宠物切换条）② tonal 静态标签（商城分类）
/// ③ 带副文案的说明条（日历补签票点）。视觉语言统一为：胶囊圆角 +
/// 1px 描边（选中态加重 1.5px）+ 前导小件 + fsFoot 加粗主文案。
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.leading,
    this.message,
    this.selected = false,
    this.onTap,
    this.background,
    this.borderColor,
    this.textColor,
    this.radius = AppDimens.rFull,
    this.padding,
  });

  /// 主文案
  final String label;

  /// 前导小件：功能图标（iconSm 档、着 textColor 同色）或 emoji 字形
  final Widget? leading;

  /// 副文案：传入即说明条形态（主文案着色加粗 + 副文案微字灰），
  /// 整卡占满可用宽度；不传则是 hug 内容的紧凑胶囊
  final String? message;

  /// 选中态：mintLight 底 + mint 加重描边 + mint 字
  final bool selected;

  /// 点击回调（传入即自带 InkWell 波纹；缩放物理交给外层 PressableScale 叠加）
  final VoidCallback? onTap;

  /// 显式 tonal 配色（珊瑚票点/薄荷标签等），未传则走选中双态默认色
  final Color? background;
  final Color? borderColor;
  final Color? textColor;

  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final Color bg =
        background ?? (selected ? AppColors.mintLight : AppColors.card);
    final Color border =
        borderColor ?? (selected ? AppColors.mint : AppColors.line);
    final Color fg = textColor ?? (selected ? AppColors.mint : AppColors.text);
    final EdgeInsetsGeometry insets = padding ??
        (message != null
            ? const EdgeInsets.symmetric(
                horizontal: AppDimens.sp16, vertical: AppDimens.sp12)
            : const EdgeInsets.symmetric(
                horizontal: AppDimens.sp12, vertical: AppDimens.sp8));

    final Widget content = Container(
      padding: insets,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: selected ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: message != null ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppDimens.sp8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: AppDimens.fsFoot,
                        fontWeight: FontWeight.w700,
                        color: fg)),
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(message!,
                      style: TextStyle(
                          fontSize: AppDimens.fsMicro,
                          height: 1.4,
                          color: AppColors.textSoft)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// 菜单行：前导图标/emoji + 标题 + 副标题 + 尾部控件（默认右箭头）。
/// 自带 InkWell 波纹——设置页"运行环境"行借此获得可点击反馈。
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.rMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.sp16, vertical: AppDimens.sp12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppDimens.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppDimens.fsBodyMid,
                        fontWeight: FontWeight.w600,
                        color: danger ? AppColors.coral : AppColors.text,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppDimens.fsCaption,
                          color: AppColors.textMute,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right,
                      size: AppDimens.iconMd, color: AppColors.textMute),
            ],
          ),
        ),
      ),
    );
  }
}

/// 统计单元：白底描边小卡，大数值 mint 色 + 微标签（单行防溢出）。
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sp12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rMd),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: AppText.numericStat(color: AppColors.mint)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: AppDimens.fsMicro, color: AppColors.textSoft)),
        ],
      ),
    );
  }
}

/// 徽章圆：解锁/未解锁双态。合并个人中心条(40)与徽章页格子(56+投影)两套克隆。
class BadgeCircle extends StatelessWidget {
  const BadgeCircle({
    super.key,
    required this.emoji,
    required this.label,
    required this.unlocked,
    this.size = 56,
    this.showShadow = false,
  });

  final String emoji;
  final String label;
  final bool unlocked;
  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? AppColors.mintLight : AppColors.sand,
            border: Border.all(
              color: unlocked ? AppColors.mint : AppColors.line,
              width: unlocked ? 2 : 1,
            ),
            boxShadow: showShadow && unlocked
                ? [
                    // 与既有品牌一致的柔和薄荷投影（30%）
                    const BoxShadow(
                      color: Color(0x4D4CAF82),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child:
              Text(emoji, style: TextStyle(fontSize: size * 0.5)),
        ),
        const SizedBox(height: AppDimens.sp4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppDimens.fsMicro,
            color: unlocked ? AppColors.mint : AppColors.textMute,
          ),
        ),
      ],
    );
  }
}

/// MOCK 开发环境角标：仅调试态可见的语义徽标。
class MockDevBadge extends StatelessWidget {
  const MockDevBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.sp8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(AppDimens.rXs),
      ),
      child: Text('MOCK',
          style: TextStyle(
              fontSize: AppDimens.fsMicro,
              fontWeight: FontWeight.w800,
              color: AppColors.warningText)),
    );
  }
}
