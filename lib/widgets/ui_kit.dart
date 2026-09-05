import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

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
                fontWeight: FontWeight.w800,
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
            border: Border.all(color: AppColors.line),
            boxShadow: [
              // 极淡的环境投影：让白卡从米白底上"浮"起来（高级感关键）
              BoxShadow(
                color: AppColors.text.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
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
                      size: 20, color: AppColors.textMute),
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
              style: TextStyle(
                  fontSize: AppDimens.fsStat,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mint)),
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
