import '../models/exercise_record.dart';

/// 周报本地聚合（M4 过渡方案——契约 §4.8 ⑳ 允许：后端 /stats 就绪前
/// 由前端用本地记录聚合渲染，后端就绪后切换服务端口径）。
///
/// 统计口径与契约 §一/§4.7 一致：东八区自然日切分，周一为一周起点；
/// 打卡判定 = isCompleted && duration ≥ 300 秒（不限运动类型）。
class WeeklySummary {
  final DateTime weekStart; // 本周一 0 点（本地时区）
  final int totalMinutes;
  final double totalKm;
  final int totalSteps;
  final int checkedDays; // 有达标记录的自然日数
  final int recordCount;
  final List<int> dailyMinutes; // 周一..周日共 7 项
  final int daysElapsed; // 本周已过天数（含今天，1..7）

  const WeeklySummary({
    required this.weekStart,
    required this.totalMinutes,
    required this.totalKm,
    required this.totalSteps,
    required this.checkedDays,
    required this.recordCount,
    required this.dailyMinutes,
    required this.daysElapsed,
  });

  /// 目标达成率：打卡天 / 本周已过天（百分数 0-100）
  int get completionRate =>
      daysElapsed <= 0 ? 0 : (checkedDays * 100 / daysElapsed).round();

  /// 综合评级（数据驱动的展示文案，非真实评分）
  String get grade {
    if (totalMinutes <= 0) return '-';
    final rate = completionRate;
    if (rate >= 80) return 'A';
    if (rate >= 60) return 'B';
    if (rate >= 40) return 'C';
    return 'D';
  }

  String get gradeLabel {
    if (totalMinutes <= 0) return '本周还没开始';
    final rate = completionRate;
    if (rate >= 80) return '优秀';
    if (rate >= 60) return '良好';
    if (rate >= 40) return '继续加油';
    return '慢慢来';
  }

  /// 本周一 0 点
  static DateTime weekStartOf(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    // Dart weekday: 周一=1 .. 周日=7
    return local.subtract(Duration(days: local.weekday - 1));
  }

  /// 从运动记录聚合本周概览（records 为全量记录，内部按周过滤）
  static WeeklySummary compute(List<ExerciseRecord> records, DateTime now) {
    final start = weekStartOf(now);
    final end = start.add(const Duration(days: 7)); // 不含下周一
    final daily = List<int>.filled(7, 0);
    final checked = <int>{};
    int minutes = 0;
    int steps = 0;
    int count = 0;
    double km = 0;

    for (final r in records) {
      if (r.startTime.isBefore(start) || !r.startTime.isBefore(end)) continue;
      count++;
      minutes += r.duration.inMinutes;
      km += r.distance;
      steps += r.steps;
      final idx = r.startTime.difference(start).inDays;
      if (idx >= 0 && idx < 7) {
        daily[idx] += r.duration.inMinutes;
        if (r.countsAsCheckIn) checked.add(idx);
      }
    }

    final elapsed = (now.difference(start).inDays + 1).clamp(1, 7);
    return WeeklySummary(
      weekStart: start,
      totalMinutes: minutes,
      totalKm: km,
      totalSteps: steps,
      checkedDays: checked.length,
      recordCount: count,
      dailyMinutes: daily,
      daysElapsed: elapsed,
    );
  }

  /// 本周各宠物运动分钟数（petId → 分钟）
  static Map<String, int> minutesByPet(
      List<ExerciseRecord> records, DateTime now) {
    return _sumByPet(records, now, (r) => r.duration.inMinutes);
  }

  /// 本周各宠物运动次数（petId → 次数）
  static Map<String, int> countByPet(
      List<ExerciseRecord> records, DateTime now) {
    return _sumByPet(records, now, (_) => 1);
  }

  static Map<String, int> _sumByPet(List<ExerciseRecord> records,
      DateTime now, int Function(ExerciseRecord) pick) {
    final start = weekStartOf(now);
    final end = start.add(const Duration(days: 7));
    final result = <String, int>{};
    for (final r in records) {
      if (r.startTime.isBefore(start) || !r.startTime.isBefore(end)) continue;
      result[r.petId] = (result[r.petId] ?? 0) + pick(r);
    }
    return result;
  }
}
