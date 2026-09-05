/// 徽章（契约 §4.10 ㉓）：解锁由服务端事件判定，前端只展示。
class BadgeItem {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool isUnlocked;
  final String? unlockedAt; // ISO 时间，新解锁可能为空

  const BadgeItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory BadgeItem.fromWire(Map<String, dynamic> m) => BadgeItem(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '🏅',
        description: m['description'] as String? ?? '',
        isUnlocked: m['isUnlocked'] as bool? ?? false,
        unlockedAt: m['unlockedAt'] as String?,
      );
}

class BadgeResult {
  final List<BadgeItem> list;
  final int unlockedCount;

  const BadgeResult({required this.list, required this.unlockedCount});

  factory BadgeResult.fromWire(Map<String, dynamic> data) => BadgeResult(
        list: ((data['list'] as List?) ?? const [])
            .map((e) => BadgeItem.fromWire(Map<String, dynamic>.from(e as Map)))
            .toList(),
        unlockedCount: (data['unlockedCount'] as num?)?.toInt() ?? 0,
      );
}
