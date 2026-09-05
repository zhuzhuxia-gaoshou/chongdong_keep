import 'package:flutter/material.dart';
import '../../models/dto/badge_dto.dart';
import '../../network/api_exception.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 徽章成就：服务端真实解锁状态（契约 ㉓，GET 时惰性评估解锁事件）。
class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  late Future<BadgeResult> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.badges.fetchBadges();
  }

  void _refetch() {
    setState(() {
      _future = AppServices.instance.badges.fetchBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('徽章成就')),
      body: FutureBuilder<BadgeResult>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.mint));
          }
          if (snap.hasError) {
            final msg = snap.error is ApiException
                ? (snap.error as ApiException).friendlyMessage
                : '加载失败，请重试';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 40, color: AppColors.textMute),
                  const SizedBox(height: AppDimens.sp12),
                  Text(msg, style: const TextStyle(color: AppColors.textSoft)),
                  const SizedBox(height: AppDimens.sp12),
                  OutlinedButton(onPressed: _refetch, child: const Text('重试')),
                ],
              ),
            );
          }
          final result = snap.data!;
          final total = result.list.length;
          final locked = total - result.unlockedCount;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressHeader(result.unlockedCount, total),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        size: 18, color: AppColors.mint),
                    const SizedBox(width: 8),
                    const Text('我的徽章墙',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('已解锁 ${result.unlockedCount} / $total',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSoft)),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.8,
                  children: [
                    for (final b in result.list)
                      _buildBadge(
                        b.name,
                        b.emoji,
                        b.isUnlocked,
                        b.isUnlocked ? null : b.description,
                      ),
                  ],
                ),
                if (total == 0) ...[
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('🐾 徽章体系准备中，先去运动打卡吧',
                        style: TextStyle(color: AppColors.textSoft)),
                  ),
                ],
                if (locked > 0) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text('还有 $locked 枚徽章等待解锁，继续加油！',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSoft)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(int unlocked, int total) {
    final progress = total <= 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已解锁 $unlocked / $total 个徽章',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.onAccent)),
                    const SizedBox(height: 6),
                    Text(
                      unlocked == total ? '全部解锁，太厉害了！' : '继续加油！',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onAccent),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    size: 30, color: AppColors.onAccent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('$unlocked', '已解锁'),
              _buildHeaderStat('$total', '全部徽章'),
              _buildHeaderStat(
                  total <= 0 ? '0' : '${(progress * 100).round()}%', '完成度'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onAccent)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildBadge(
      String name, String emoji, bool isUnlocked, String? note) {
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
        if (note != null && note.isNotEmpty)
          Text(
            isUnlocked ? '已解锁' : note,
            style: TextStyle(
                fontSize: 9, color: isUnlocked ? AppColors.mint : AppColors.coral),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
