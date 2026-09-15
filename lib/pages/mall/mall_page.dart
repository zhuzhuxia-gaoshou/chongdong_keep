import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/ui_kit.dart';

/// 商城 Tab（三期占位，质感 v2）：品牌化「即将上线」页。
/// 居中占位位于 Scaffold body（有界），无 Dock 预留问题；
/// 底部预留 104 与 walk Tab 对齐，extendBody 回归时不出遮挡事故。
class MallPage extends StatelessWidget {
  const MallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 装饰圆：静态低透明度（非动画，无入场依赖）
            Positioned(
              right: -40,
              top: 60,
              child: _decorCircle(140, 0.35),
            ),
            Positioned(
              left: -30,
              bottom: 140,
              child: _decorCircle(100, 0.25),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.sp20, 0, AppDimens.sp20, 104),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 品牌图章：渐变圆 + 辉光（与登录页同族）
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.heroGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mint.withValues(alpha: 0.3),
                            offset: const Offset(0, 8),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child:
                          const Text('🛒', style: TextStyle(fontSize: 44)),
                    ),
                    const SizedBox(height: AppDimens.sp20),
                    Text('宠物商城即将上线',
                        style: TextStyle(
                            fontSize: AppDimens.fsStat,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    const SizedBox(height: AppDimens.sp8),
                    Text(
                      '精选宠物粮、零食、用品\n按你家宝贝的档案智能推荐\n运动打卡还能换优惠券 🎁',
                      style: TextStyle(
                          fontSize: AppDimens.fsBody,
                          color: AppColors.textSoft,
                          height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.sp24),
                    Wrap(
                      spacing: AppDimens.sp8,
                      runSpacing: AppDimens.sp8,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FeatTag(Icons.restaurant_rounded, '主食'),
                        _FeatTag(Icons.pets_rounded, '零食'),
                        _FeatTag(Icons.toys_rounded, '用品'),
                        _FeatTag(Icons.watch_rounded, '智能硬件'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.mintLight.withValues(alpha: alpha),
        ),
      );
}

/// 分类标签：AppChip 薄荷 tonal 静态形态（Material 图标 + 文案，功能图标不再用 emoji）
class _FeatTag extends StatelessWidget {
  const _FeatTag(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      leading: Icon(icon, size: AppDimens.iconSm, color: AppColors.mint),
      background: AppColors.mintLight,
      borderColor: AppColors.mintLine,
      textColor: AppColors.mint,
    );
  }
}
