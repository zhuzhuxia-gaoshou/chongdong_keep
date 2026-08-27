import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          tabs: const [
            Tab(text: '本周'),
            Tab(text: '本月'),
            Tab(text: '总榜'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPodium(),
          Expanded(child: _buildRankingList()),
          _buildMyRank(),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumItem(2, '🥈', 'lisa', 125)),
          Expanded(child: _buildPodiumItem(1, '👑', '你', 180)),
          Expanded(child: _buildPodiumItem(3, '🥉', '小明', 98)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(int rank, String emoji, String name, int minutes) {
    final height = rank == 1 ? 90.0 : 70.0;
    final color = rank == 1 ? AppColors.mint : rank == 2 ? AppColors.sand : AppColors.coralLight;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: rank == 1 ? 28 : 22,
          backgroundColor: color,
          child: Text(emoji, style: TextStyle(fontSize: rank == 1 ? 24 : 20)),
        ),
        const SizedBox(height: 6),
        Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text('${minutes}分钟', style: TextStyle(fontSize: 10, color: AppColors.textSoft)),
        const SizedBox(height: 4),
        Container(
          height: height,
          width: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text('$rank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList() {
    final list = List.generate(8, (i) {
      final names = ['小王', '阿花', '大毛', '毛毛妈', '旺财爸', '糖糖', '豆包', '可乐妈'];
      final minutes = [76, 65, 54, 48, 42, 35, 28, 20];
      return {'name': names[i], 'minutes': minutes[i], 'isMe': i == 2};
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: item['isMe'] as bool ? AppColors.mintLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item['isMe'] as bool ? AppColors.mint : AppColors.line,
              width: item['isMe'] as bool ? 2 : 1,
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
                  child: Text('${index + 4}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.mintLight,
                child: Text('🐕', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['name'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: item['isMe'] as bool ? AppColors.mint : AppColors.text,
                  ),
                ),
              ),
              Text('${item['minutes']}分钟', style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyRank() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('第 2 名', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('我的排行', style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
                const SizedBox(height: 2),
                Text('本周累计运动 180 分钟', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppColors.coral),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
