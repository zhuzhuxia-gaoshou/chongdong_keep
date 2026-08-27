import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('徽章成就')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressHeader(),
            const SizedBox(height: 20),
            _buildCategoryTab('打卡成就', Icons.calendar_month_rounded, [
              _buildBadge('连续7天', '🔥', true, null),
              _buildBadge('连续30天', '🏆', true, null),
              _buildBadge('连续100天', '💎', false, '还差73天'),
              _buildBadge('连续365天', '👑', false, '还差338天'),
            ]),
            const SizedBox(height: 20),
            _buildCategoryTab('运动成就', Icons.directions_run, [
              _buildBadge('首次打卡', '🎉', true, null),
              _buildBadge('运动100公里', '🚀', true, null),
              _buildBadge('运动500公里', '🌍', false, '还差462公里'),
              _buildBadge('单日10公里', '⚡', false, '尚未解锁'),
            ]),
            const SizedBox(height: 20),
            _buildCategoryTab('猫咪专属', Icons.pets, [
              _buildBadge('首次陪玩', '🎮', true, null),
              _buildBadge('陪猫100次', '🐱', false, '还差92次'),
              _buildBadge('猫粮专家', '🥣', false, '尚未解锁'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.mint, Color(0xFF6BC89D)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已解锁 6 / 16 个徽章', style: TextStyle(fontSize: 14, color: Colors.white)),
                    SizedBox(height: 6),
                    Text('继续加油！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🏅', style: TextStyle(fontSize: 28)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 6 / 16,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('6', '已解锁'),
              _buildHeaderStat('10', '进行中'),
              _buildHeaderStat('6', '未解锁'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildCategoryTab(String title, IconData icon, List<Widget> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.mint),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
          childAspectRatio: 0.85,
          children: badges,
        ),
      ],
    );
  }

  Widget _buildBadge(String name, String emoji, bool isUnlocked, String? progress) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isUnlocked ? AppColors.mintLight : AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked ? AppColors.mint : AppColors.line,
              width: isUnlocked ? 2 : 1,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: AppColors.mint.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: 26,
                color: isUnlocked ? null : AppColors.textMute,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isUnlocked ? AppColors.text : AppColors.textMute,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (progress != null)
          Text(
            progress,
            style: const TextStyle(fontSize: 9, color: AppColors.coral),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
