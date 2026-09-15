/// 品牌温柔文案库（品牌守护者 D2-4，2026-09-15）。
///
/// EmptyState / 打卡成功 / 补签成功 / 连胜里程碑 四类文案变体的**唯一代码出口**；
/// 人读镜像在 `docs/copy_library.md`——改一处必须同步另一处。
///
/// 纪律（DESIGN_SYSTEM.md §6.2 / §8.1）：
/// - 每条 ≤ 1 个语气符，且只用品牌集 🐾 💗 🥺 🌸（🎉 仅限成就/庆典）；
/// - 不命令（请/必须/不要）、不指责；
/// - 轮换用**确定性种子**（默认日序），同一天稳定、隔天换新——彩蛋感且可测试。
class BrandCopy {
  BrandCopy._();

  /// 日序种子：同一天取值恒定，隔天自然换新。
  static int daySeed([DateTime? now]) {
    final d = now ?? DateTime.now();
    return d.difference(DateTime(d.year)).inDays;
  }

  /// 从池中确定性取一条；[seed] 缺省用日序。
  static String pick(List<String> pool, {int? seed}) {
    assert(pool.isNotEmpty, 'BrandCopy 池不能为空');
    return pool[(seed ?? daySeed()).abs() % pool.length];
  }

  // ---------------------------------------------------------------- 打卡成功

  /// 满 5 分钟打卡成功（SnackBar / 结果横幅）。
  static const List<String> checkinSuccessPool = [
    '今日打卡成功啦，宝贝的尾巴都摇起来了 🐾',
    '打卡成功！今天也是被宝贝爱着的一天 💗',
    '完成今日打卡～和宝贝一起又赢了一天 🎉',
    '打卡成功哦，坚持的样子真好看 🌸',
    '今日份运动达成，宝贝说谢谢你 🥺',
  ];

  static String checkinSuccess({int? seed}) =>
      pick(checkinSuccessPool, seed: seed);

  /// 记录已保存但未达 5 分钟打卡门槛——鼓励而非提醒不足。
  static const List<String> recordSavedShortPool = [
    '记录好啦，陪玩 {min} 分钟；满 5 分钟就能算打卡哦',
    '{min} 分钟的陪伴也很珍贵，下次凑到 5 分钟就打卡啦 🐾',
    '已经记下 {min} 分钟啦，再多陪一会儿就能打卡哦',
  ];

  static String recordSavedShort(int minutes, {int? seed}) =>
      pick(recordSavedShortPool, seed: seed).replaceAll('{min}', '$minutes');

  // ---------------------------------------------------------------- 补签成功

  static const List<String> makeupSuccessPool = [
    '补签成功啦，连胜续上了 🐾 还剩 {n} 张补签卡',
    '补上啦！那天的陪伴也被记住了 💗 剩余补签卡 {n} 张',
    '补签完成～坚持没有断哦，还有 {n} 张补签卡',
    '补签成功哦，宝贝的日历又圆满了 🌸 剩余 {n} 张',
  ];

  static String makeupSuccess(int remaining, {int? seed}) =>
      pick(makeupSuccessPool, seed: seed).replaceAll('{n}', '$remaining');

  // ---------------------------------------------------------------- 连胜

  /// 里程碑专属句（命中天数即用，不轮换）。
  static const Map<int, String> streakMilestones = {
    3: '连续 3 天啦，好习惯正在悄悄长大 🌸',
    7: '连续一周！宝贝都记得你每天的陪伴 💗',
    14: '连续两周啦，你们已经是默契搭档了 🐾',
    30: '连续 30 天！一个月的坚持，宝贝为你骄傲 🎉',
    100: '连续 100 天！这份爱值得被所有人看见 🎉',
    365: '连续一整年！你们的故事已经写满 365 页 💗',
  };

  /// 非里程碑天数的通用句。
  static const List<String> streakGenericPool = [
    '已经连续打卡 {days} 天啦，宝贝为你骄傲',
    '连续 {days} 天的陪伴，宝贝都记在心里 💗',
    '第 {days} 天啦，今天也一起动一动吧 🐾',
  ];

  /// 连胜为 0：鼓励开始，不施压。
  static const List<String> streakZeroPool = [
    '今天也要记得陪宝贝动一动哦',
    '新的一天，从陪宝贝 5 分钟开始吧 🐾',
    '还没开始也没关系，现在出发刚刚好 🌸',
  ];

  static String streakLine(int days, {int? seed}) {
    if (days <= 0) return pick(streakZeroPool, seed: seed);
    final milestone = streakMilestones[days];
    if (milestone != null) return milestone;
    return pick(streakGenericPool, seed: seed).replaceAll('{days}', '$days');
  }

  // ---------------------------------------------------------------- 空态

  /// 运动记录空态副文案（EmptyState.message）。
  static const List<String> emptyRecordsPool = [
    '完成一次遛狗/陪玩后，就会出现在这里',
    '第一条记录还在路上呢，带宝贝出门走走吧 🐾',
    '这里空空的，正好留给今天的第一次陪伴 🌸',
  ];

  static String emptyRecords({int? seed}) => pick(emptyRecordsPool, seed: seed);

  /// 全部池（供品牌守护测试遍历：密度 / 语气 / 禁用符号）。
  static List<String> get allLines => [
        ...checkinSuccessPool,
        ...recordSavedShortPool,
        ...makeupSuccessPool,
        ...streakMilestones.values,
        ...streakGenericPool,
        ...streakZeroPool,
        ...emptyRecordsPool,
      ];
}
