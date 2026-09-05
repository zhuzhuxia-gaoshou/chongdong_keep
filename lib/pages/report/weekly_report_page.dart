import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/pet.dart';
import '../../services/app_state.dart';
import '../../services/weekly_summary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 周报页：本地聚合真实运动数据（M4 过渡方案，后端 ⑳ 就绪后切换）。
class WeeklyReportPage extends StatelessWidget {
  const WeeklyReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final summary = WeeklySummary.compute(state.records, now);
    final petNames = state.pets.isEmpty
        ? '还没有宠物档案'
        : state.pets.map((p) => p.name).join(' & ');
    final weekEnd = summary.weekStart.add(const Duration(days: 6));
    final period =
        '${summary.weekStart.month}.${summary.weekStart.day} - ${weekEnd.month}.${weekEnd.day}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('周报'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '分享周报',
            onPressed: () => _shareSummary(context, summary, petNames),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.sp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(summary, petNames, period),
            const SizedBox(height: AppDimens.sp20),
            _buildDataOverview(state, summary),
            const SizedBox(height: AppDimens.sp20),
            _buildWeeklyChart(summary),
            const SizedBox(height: AppDimens.sp20),
            _buildPetRanking(state, summary, now),
            const SizedBox(height: AppDimens.sp20),
            _buildTips(summary),
            const SizedBox(height: AppDimens.sp20),
            _buildShareCard(context, summary, petNames),
          ],
        ),
      ),
    );
  }

  void _shareSummary(BuildContext context, WeeklySummary summary,
      String petNames) {
    final text = summary.totalMinutes <= 0
        ? '我在宠动Keep关注宠物健康，这周一起动起来吧！'
        : '我这周在宠动Keep陪$petNames运动了 ${summary.totalMinutes} 分钟，'
            '打卡 ${summary.checkedDays} 天、合计 ${summary.totalKm.toStringAsFixed(1)} 公里，一起坚持吧！';
    Share.share(text);
  }

  Widget _buildScoreCard(WeeklySummary s, String petNames, String period) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppDimens.rLg),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('本周健康报告',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onAccent,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(petNames,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onAccent)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(period,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onAccent)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s.grade,
                  style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onAccent)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本周完成率 ${s.completionRate}%',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(s.gradeLabel,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onAccent)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem('${s.checkedDays}', '打卡天',
                  Icons.event_available_rounded),
              _buildScoreItem('${s.totalMinutes}', '总分钟',
                  Icons.timer_rounded),
              _buildScoreItem(s.totalKm.toStringAsFixed(1), '总公里',
                  Icons.route_rounded),
              _buildScoreItem('${s.totalSteps}', '总步数',
                  Icons.directions_walk_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onAccent)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildDataOverview(AppState state, WeeklySummary s) {
    return Row(
      children: [
        Expanded(
            child: _buildOverviewCard('连续打卡', '${state.user?.streakDays ?? 0}天',
                Icons.local_fire_department_rounded, AppColors.coral)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildOverviewCard('目标达成', '${s.completionRate}%',
                Icons.track_changes_rounded, AppColors.mint)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildOverviewCard('本周次数', '${s.recordCount}',
                Icons.list_alt_rounded, AppColors.skyDeep)),
      ],
    );
  }

  Widget _buildOverviewCard(
      String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: AppColors.textSoft)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(WeeklySummary s) {
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    final values = s.dailyMinutes;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final todayIdx = s.daysElapsed - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('每日运动时长',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(AppDimens.rSm),
                ),
                child: const Text('单位: 分钟',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mint)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                // 高度按本周峰值归一（封顶 90px），避免一天爆量压扁其余柱
                final height =
                    maxVal <= 0 ? 0.0 : values[i] / maxVal * 90.0;
                final isToday = i == todayIdx;
                final isMax = maxVal > 0 && values[i] == maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (values[i] > 0)
                          Text('${values[i]}',
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.textSoft)),
                        const SizedBox(height: 2),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: values[i] <= 0
                                ? AppColors.sand
                                : isMax
                                    ? AppColors.mint
                                    : AppColors.mint.withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppDimens.rSm)),
                            border: isToday && values[i] <= 0
                                ? Border.all(color: AppColors.line)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(days[i],
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isToday
                                    ? AppColors.mint
                                    : AppColors.textSoft)),
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

  Widget _buildPetRanking(AppState state, WeeklySummary s, DateTime now) {
    final minutes = WeeklySummary.minutesByPet(state.records, now);
    final counts = WeeklySummary.countByPet(state.records, now);
    final rows = state.pets
        .map((p) => (
              pet: p,
              mins: minutes[p.id] ?? 0,
              count: counts[p.id] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.mins.compareTo(a.mins));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('宠物本周表现',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: AppDimens.cardBox(borderColor: AppColors.line),
            child: const Text('添加宠物后，这里会展示每只宝贝的本周表现',
                style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
          )
        else
          for (var i = 0; i < rows.length; i++) ...[
            _buildPetRankItem(
                pet: rows[i].pet,
                mins: rows[i].mins,
                count: rows[i].count,
                isTop: i == 0 && rows[i].mins > 0),
            if (i != rows.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildPetRankItem(
      {required Pet pet, required int mins, required int count, required bool isTop}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isTop ? AppColors.mint : AppColors.line,
            width: isTop ? 2 : 1),
      ),
      child: Row(
        children: [
          Text(pet.speciesEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(pet.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    if (isTop) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.emoji_events_rounded,
                          size: 15, color: AppColors.coral),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$mins分钟',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: mins > 0
                                ? AppColors.mint
                                : AppColors.textMute)),
                    const SizedBox(width: 10),
                    Text('本周 $count 次',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textSoft)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips(WeeklySummary s) {
    final advice = s.recordCount == 0
        ? '本周还没有运动记录哦。哪怕陪宝贝玩 5 分钟也算打卡，现在出发也不晚呀🌸'
        : s.completionRate >= 80
            ? '本周打卡 ${s.checkedDays} 天、共 ${s.totalMinutes} 分钟，表现非常棒！下周保持节奏，可以试着增加 5-10 分钟轻松活动哦💗'
            : s.completionRate >= 50
                ? '本周完成率 ${s.completionRate}%，稳扎稳打！挑一两个状态好的日子多遛 10 分钟，很快就能突破啦🐾'
                : '本周有点忙吧？别有压力，每天陪宝贝玩 5 分钟就能保住打卡，慢慢来就好🥺';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.coralLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coralLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates_rounded,
                  size: 16, color: AppColors.coral),
              SizedBox(width: 6),
              Text('本周小结',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.coral)),
            ],
          ),
          const SizedBox(height: 10),
          Text(advice,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.text, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildShareCard(
      BuildContext context, WeeklySummary s, String petNames) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mintLine),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('分享本周报告',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mint)),
                SizedBox(height: 4),
                Text('把这份坚持分享给朋友吧',
                    style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _shareSummary(context, s, petNames),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
            icon: const Icon(Icons.ios_share_rounded, size: 15),
            label: const Text('分享周报'),
          ),
        ],
      ),
    );
  }
}
