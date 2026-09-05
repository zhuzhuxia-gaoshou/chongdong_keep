import 'package:flutter/material.dart';
import '../../models/dto/ranking_dto.dart';
import '../../network/api_exception.dart';
import '../../services/app_services.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 排行榜：真实服务端数据（契约 ㉒，metric=分钟）。
/// 本周 = 滚动近 7 天；本月 = 自然月。
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
            return const Center(
                child: CircularProgressIndicator(color: AppColors.mint));
          }
          if (snap.hasError) {
            final msg = snap.error is ApiException
                ? (snap.error as ApiException).friendlyMessage
                : '加载失败，请下拉重试';
            return _errorView(msg);
          }
          final result = snap.data!;
          if (result.list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refetch(),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text('🐾 榜单还空着\n去运动一次，成为第一名！',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSoft)),
                  ),
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

  Widget _errorView(String msg) {
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

  Widget _buildPodium(List<RankingItem> top3) {
    // 展示顺序：第2名、第1名、第3名
    final ordered = [top3[1], top3[0], top3[2]];
    final medals = ['🥈', '👑', '🥉'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: _buildPodiumItem(
                ordered[i],
                medals[i],
                rank: top3[i].rank,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(RankingItem item, String medal, {required int rank}) {
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
          child: Text(medal, style: TextStyle(fontSize: isFirst ? 24 : 20)),
        ),
        const SizedBox(height: 6),
        Text(item.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: item.isMe ? AppColors.mint : AppColors.text)),
        Text('${item.value}分钟',
            style: TextStyle(fontSize: 10, color: AppColors.textSoft)),
        const SizedBox(height: 4),
        Container(
          height: height,
          width: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text('$rank',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _rankRow(RankingItem item, {int? rank}) {
    final displayRank = rank ?? item.rank;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: item.isMe ? AppColors.mintLight : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isMe ? AppColors.mint : AppColors.line,
          width: item.isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$displayRank',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 10),
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.isMe ? '${item.nickname}（我）' : item.nickname,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: item.isMe ? AppColors.mint : AppColors.text,
              ),
            ),
          ),
          Text('${item.value}分钟',
              style: const TextStyle(fontSize: 12, color: AppColors.textSoft)),
        ],
      ),
    );
  }

  Widget _buildMyRank(RankingResult result) {
    final me = result.me;
    if (me == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
          color: AppColors.card,
        ),
        child: const Text('登录后查看我的排行',
            style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
      );
    }
    final period = result.type == 'monthly' ? '本月' : '本周';
    if (_rankOptedOut) {
      // 与服务端口径一致：关闭公开排行榜后不参与排名，后端榜单同样剔除
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
          color: AppColors.card,
        ),
        child: const Text('已开启隐私保护，不参与排行榜（可在设置中开启）',
            style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
        color: AppColors.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(me.rank > 0 ? '第 ${me.rank} 名' : '未上榜',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('我的排行',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSoft)),
                const SizedBox(height: 2),
                Text('$period累计运动 ${me.value} 分钟',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
