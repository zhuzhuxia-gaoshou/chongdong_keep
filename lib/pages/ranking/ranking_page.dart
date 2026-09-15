import 'package:flutter/material.dart';
import '../../models/dto/ranking_dto.dart';
import '../../network/api_exception.dart';
import '../../services/app_services.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

/// 排行榜（2026-09-15 质感 v2）：真实服务端数据（契约 ㉒，metric=分钟）。
/// 奖台 emoji→Material 奖牌图标、名次数字 w900/w800→展示体、榜单行白卡浮起、
/// 我的排名浮条升级 IconChip+展示体。本周=滚动近 7 天；本月=自然月。
class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<RankingResult> _future;
  bool _rankOptedOut = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _refetch();
    });
    _future = AppServices.instance.ranking.fetchRanking(type: 'weekly');
    _loadPrivacy();
  }

  /// 隐私设置（设置页）：关闭「公开排行榜」时，我的排名区显示隐私提示。
  Future<void> _loadPrivacy() async {
    final s = await StorageService.loadAppSettings();
    if (!mounted) return;
    setState(() => _rankOptedOut = (s['publicRanking'] as bool?) == false);
  }

  void _refetch() {
    final type = _tabController.index == 0 ? 'weekly' : 'monthly';
    setState(() {
      _future = AppServices.instance.ranking.fetchRanking(type: type);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '本周'), Tab(text: '本月')],
        ),
      ),
      body: FutureBuilder<RankingResult>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            // Scaffold body 有界，Center 安全
            return const Center(child: LoadingView());
          }
          if (snap.hasError) {
            final msg = snap.error is ApiException
                ? (snap.error as ApiException).friendlyMessage
                : '没加载出来呢，下拉再试试呀';
            return Center(child: ErrorRetry(message: msg, onRetry: _refetch));
          }
          final result = snap.data!;
          if (result.list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refetch(),
              child: ListView(
                children: [
                  const SizedBox(height: 60),
                  const Center(
                    child: EmptyState(
                      emoji: '🐾',
                      title: '榜单还空着',
                      message: '去运动一次，成为第一名！',
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refetch(),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: AppDimens.sp12),
                    children: [
                      if (result.list.length >= 3)
                        _buildPodium(result.list.take(3).toList())
                      else ...[
                        for (final item in result.list) _rankRow(item),
                      ],
                      if (result.list.length > 3)
                        for (var i = 3; i < result.list.length; i++)
                          _rankRow(result.list[i], rank: result.list[i].rank),
                    ],
                  ),
                ),
                _buildMyRank(result),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<RankingItem> top3) {
    // 展示顺序：第2名、第1名、第3名
    final ordered = [top3[1], top3[0], top3[2]];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.sp16, AppDimens.sp20, AppDimens.sp16, AppDimens.sp16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: _buildPodiumItem(
                ordered[i],
                rank: top3[i].rank,
              ),
            ),
        ],
      ),
    );
  }

  /// 奖台名次图标：冠=桂冠、亚=军章、季=奖牌（Material 图标替代 emoji）
  IconData _medalIcon(int rank) => rank == 1
      ? Icons.workspace_premium_rounded
      : rank == 2
          ? Icons.military_tech_rounded
          : Icons.emoji_events_rounded;

  Widget _buildPodiumItem(RankingItem item, {required int rank}) {
    final isFirst = rank == 1;
    final height = isFirst ? 90.0 : 70.0;
    final color = isFirst
        ? AppColors.mint
        : rank == 2
            ? AppColors.sand
            : AppColors.coralLight;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: isFirst ? 28 : 22,
          backgroundColor: color,
          child: Icon(_medalIcon(rank),
              size: isFirst ? 26 : 22,
              color: isFirst
                  ? AppColors.onAccent
                  : rank == 2
                      ? AppColors.textSoft
                      : AppColors.coral),
        ),
        const SizedBox(height: AppDimens.sp8),
        Text(item.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: AppDimens.fsFoot,
                fontWeight: FontWeight.w700,
                color: item.isMe ? AppColors.mint : AppColors.text)),
        Text('${item.value}分钟',
            style: TextStyle(
                fontSize: AppDimens.fsMicro, color: AppColors.textSoft)),
        const SizedBox(height: AppDimens.sp4),
        Container(
          height: height,
          width: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppDimens.rSm)),
            boxShadow: isFirst ? AppDimens.shadowCard : null,
          ),
          child: Center(
            // 名次数字走展示体（w900 全库清零）
            child: Text('$rank',
                style: AppText.numericSection(
                    color: isFirst
                        ? AppColors.onAccent
                        : rank == 2
                            ? AppColors.textSoft
                            : AppColors.coral)),
          ),
        ),
      ],
    );
  }

  Widget _rankRow(RankingItem item, {int? rank}) {
    final displayRank = rank ?? item.rank;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sp8),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.sp16, vertical: AppDimens.sp12),
      // 我=tonal 平面+薄荷描边；他人=白卡浮起
      decoration: item.isMe
          ? BoxDecoration(
              color: AppColors.mintLight,
              borderRadius: BorderRadius.circular(AppDimens.rMd),
              border: Border.all(color: AppColors.mint, width: 1.5),
            )
          : AppDimens.cardBox(),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(AppDimens.rSm),
            ),
            child: Center(
              // 名次小数字：展示体行内档（替代 w800）
              child: Text('$displayRank',
                  style: const TextStyle(
                      fontSize: AppDimens.fsBody,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
            ),
          ),
          const SizedBox(width: AppDimens.sp12),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.mintLight,
            child: item.avatarUrl != null
                ? ClipOval(
                    child: Image.network(item.avatarUrl!,
                        width: 32, height: 32, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Text('🐾', style: TextStyle(fontSize: 14))))
                : const Text('🐾', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: AppDimens.sp12),
          Expanded(
            child: Text(
              item.isMe ? '${item.nickname}（我）' : item.nickname,
              style: TextStyle(
                fontSize: AppDimens.fsBody,
                fontWeight: FontWeight.w700,
                color: item.isMe ? AppColors.mint : AppColors.text,
              ),
            ),
          ),
          Text('${item.value}分钟',
              style: TextStyle(
                  fontSize: AppDimens.fsFoot, color: AppColors.textSoft)),
        ],
      ),
    );
  }

  /// 底部「我的排名」浮条
  Widget _myRankShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sp12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
        color: AppColors.card,
      ),
      child: child,
    );
  }

  Widget _buildMyRank(RankingResult result) {
    final me = result.me;
    if (me == null) {
      return _myRankShell(
        child: const Text('登录后查看我的排行',
            style: TextStyle(
                fontSize: AppDimens.fsFoot, color: AppColors.textSoft)),
      );
    }
    final period = result.type == 'monthly' ? '本月' : '本周';
    if (_rankOptedOut) {
      // 与服务端口径一致：关闭公开排行榜后不参与排名，后端榜单同样剔除
      return _myRankShell(
        child: const Text('已开启隐私保护，不参与排行榜（可在设置中开启）',
            style: TextStyle(
                fontSize: AppDimens.fsFoot, color: AppColors.textSoft)),
      );
    }
    return _myRankShell(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.sp12, vertical: AppDimens.sp8),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(AppDimens.rSm),
            ),
            child: Text(me.rank > 0 ? '第 ${me.rank} 名' : '未上榜',
                style: const TextStyle(
                    fontSize: AppDimens.fsBody,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: AppDimens.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('我的排行',
                    style: TextStyle(
                        fontSize: AppDimens.fsCaption,
                        color: AppColors.textSoft)),
                const SizedBox(height: 2),
                // 累计分钟数字走展示体
                Text.rich(TextSpan(
                  text: '$period累计运动 ',
                  style: const TextStyle(
                      fontSize: AppDimens.fsFoot, color: AppColors.text),
                  children: [
                    TextSpan(
                        text: '${me.value}',
                        style: AppText.numericInline(color: AppColors.mint)),
                    const TextSpan(text: ' 分钟'),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
