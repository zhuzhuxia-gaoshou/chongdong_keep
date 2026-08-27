import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WeeklyReportPage extends StatelessWidget {
  const WeeklyReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('周报'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(),
            const SizedBox(height: 20),
            _buildDataOverview(),
            const SizedBox(height: 20),
            _buildWeeklyChart(),
            const SizedBox(height: 20),
            _buildPetRanking(),
            const SizedBox(height: 20),
            _buildTips(),
            const SizedBox(height: 20),
            _buildShareCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.mint, Color(0xFF6BC89D)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本周健康报告', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('可乐 & 咪咪', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('8.20-8.26', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('A+', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('综合评分', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('优秀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem('7', '打卡天', '✅'),
              _buildScoreItem('425', '总分钟', '⏱️'),
              _buildScoreItem('3.8', '总公里', '📏'),
              _buildScoreItem('12,560', '总步数', '👟'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildDataOverview() {
    return Row(
      children: [
        Expanded(child: _buildOverviewCard('连续打卡', '7天', '🔥', AppColors.coralLight)),
        const SizedBox(width: 10),
        Expanded(child: _buildOverviewCard('目标达成', '100%', '🎯', AppColors.mintLight)),
        const SizedBox(width: 10),
        Expanded(child: _buildOverviewCard('好友排名', '第2', '🏆', AppColors.sand)),
      ],
    );
  }

  Widget _buildOverviewCard(String label, String value, String emoji, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSoft)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    final values = [45, 60, 30, 55, 70, 80, 65];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('每日运动时长', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('单位: 分钟', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.mint)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final height = values[i] / 100 * 100;
                final isMax = values[i] == values.reduce((a, b) => a > b ? a : b);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: isMax ? AppColors.mint : AppColors.sand,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(days[i], style: TextStyle(fontSize: 10, color: AppColors.textSoft)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetRanking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('宠物本周表现', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _buildPetRankItem('🐕', '可乐', '425分钟', '7天打卡', true),
        const SizedBox(height: 8),
        _buildPetRankItem('🐈', '咪咪', '95分钟', '5天玩耍', false),
      ],
    );
  }

  Widget _buildPetRankItem(String emoji, String name, String minutes, String days, bool isTop) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isTop ? AppColors.mint : AppColors.line, width: isTop ? 2 : 1),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (isTop) ...[
                      const SizedBox(width: 6),
                      const Text('👑', style: TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(minutes, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.mint)),
                    const SizedBox(width: 10),
                    Text(days, style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.coralLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0D6)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('AI健康建议', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.coral)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '本周表现非常优秀！可乐的运动达标率100%，建议下周可以尝试增加5-10分钟的轻松跑步。咪咪的玩耍时间偏少，建议每天增加10分钟逗猫时间。',
            style: TextStyle(fontSize: 12, color: AppColors.text, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0E9DC)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('分享本周报告', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mint)),
                SizedBox(height: 4),
                Text('生成精美卡片分享给朋友', style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
            child: const Text('生成卡片'),
          ),
        ],
      ),
    );
  }
}
