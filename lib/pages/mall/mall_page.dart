import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MallPage extends StatelessWidget {
  const MallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🛒', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                Text('宠物商城即将上线',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mint)),
                const SizedBox(height: 8),
                Text(
                  '精选宠物粮、零食、用品\n按你家宝贝的档案智能推荐\n运动打卡还能换优惠券 🎁',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSoft, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _featTag('🍖 主食'),
                    _featTag('🦴 零食'),
                    _featTag('🎾 用品'),
                    _featTag('⌚ 智能硬件'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        border: Border.all(color: AppColors.mintLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.mint)),
    );
  }
}
