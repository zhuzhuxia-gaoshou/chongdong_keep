/// 排行榜（契约 §4.9 ㉒）：metric = 分钟。
class RankingItem {
  final int rank;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final int value; // 运动分钟数
  final bool isMe;

  const RankingItem({
    required this.rank,
    required this.userId,
    required this.nickname,
    required this.value,
    this.avatarUrl,
    this.isMe = false,
  });

  factory RankingItem.fromWire(Map<String, dynamic> m) => RankingItem(
        rank: (m['rank'] as num?)?.toInt() ?? 0,
        userId: m['userId'] as String? ?? '',
        nickname: m['nickname'] as String? ?? '匿名铲屎官',
        avatarUrl: m['avatarUrl'] as String?,
        value: (m['value'] as num?)?.toInt() ?? 0,
        isMe: m['isMe'] as bool? ?? false,
      );
}

class RankingResult {
  final String type; // weekly | monthly
  final List<RankingItem> list;
  final RankingItem? me; // 不在前 50 也有

  const RankingResult({
    required this.type,
    required this.list,
    this.me,
  });

  factory RankingResult.fromWire(Map<String, dynamic> data) => RankingResult(
        type: data['type'] as String? ?? 'weekly',
        list: ((data['list'] as List?) ?? const [])
            .map((e) => RankingItem.fromWire(Map<String, dynamic>.from(e as Map)))
            .toList(),
        me: data['me'] == null
            ? null
            : RankingItem.fromWire(
                Map<String, dynamic>.from(data['me'] as Map)),
      );
}
