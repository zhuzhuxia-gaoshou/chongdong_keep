import 'package:flutter_test/flutter_test.dart';
import 'package:chongdong_keep/models/exercise_record.dart';
import 'package:chongdong_keep/services/weekly_summary.dart';

ExerciseRecord _rec({
  required String crid,
  required String petId,
  required DateTime start,
  int durationSec = 600,
  double km = 1.0,
  int steps = 100,
  bool completed = true,
  ExerciseType type = ExerciseType.walkDog,
}) {
  return ExerciseRecord(
    id: 'r_$crid',
    clientRecordId: crid,
    petId: petId,
    userId: 'u_1',
    type: type,
    startTime: start,
    endTime: start.add(Duration(seconds: durationSec)),
    duration: Duration(seconds: durationSec),
    distance: km,
    steps: steps,
    isCompleted: completed,
  );
}

/// 以 2026-09-05（周六）为"今天"的固定测试基准：本周一 = 2026-08-31
DateTime get _now => DateTime(2026, 9, 5, 15, 0);
DateTime _mon(int hour) => DateTime(2026, 8, 31, hour); // 周一
DateTime _sat(int hour) => DateTime(2026, 9, 5, hour); // 周六(今天)
DateTime _lastSat(int hour) => DateTime(2026, 8, 29, hour); // 上周六(上周)

void main() {
  group('WeeklySummary', () {
    test('weekStartOf：周六回退到本周一', () {
      final s = WeeklySummary.weekStartOf(_now);
      expect(s, DateTime(2026, 8, 31));
      // 周一当天即本周一
      expect(WeeklySummary.weekStartOf(DateTime(2026, 8, 31, 7)),
          DateTime(2026, 8, 31));
      // 周日属于本周
      expect(WeeklySummary.weekStartOf(DateTime(2026, 9, 6, 20)),
          DateTime(2026, 8, 31));
    });

    test('compute：周内统计正确、上周记录被排除', () {
      final records = [
        _rec(crid: 'a', petId: 'p1', start: _mon(8), durationSec: 600), // 周一 10 分钟达标
        _rec(crid: 'b', petId: 'p1', start: _sat(9), durationSec: 300, km: 0.5), // 今天 5 分钟达标
        _rec(crid: 'c', petId: 'p2', start: _sat(10), durationSec: 120), // 今天不达标
        _rec(crid: 'old', petId: 'p1', start: _lastSat(9), durationSec: 600), // 上周，排除
      ];
      final s = WeeklySummary.compute(records, _now);

      expect(s.weekStart, DateTime(2026, 8, 31));
      expect(s.recordCount, 3);
      expect(s.totalMinutes, 10 + 5 + 2);
      expect(s.checkedDays, 2); // 周一 + 今天（周六不达标不计）
      expect(s.dailyMinutes[0], 10); // 周一
      expect(s.dailyMinutes[5], 7); // 周六 = 5 + 2
      expect(s.dailyMinutes[1], 0);
      expect(s.daysElapsed, 6); // 周一..周六
    });

    test('completionRate 与评级分档', () {
      // 6 天已过，2 天打卡 → 33%
      final records = [
        _rec(crid: 'a', petId: 'p1', start: _mon(8)),
        _rec(crid: 'b', petId: 'p1', start: DateTime(2026, 9, 1, 8)),
      ];
      final s = WeeklySummary.compute(records, _now);
      expect(s.completionRate, 33);
      expect(s.grade, 'D');

      // 达到 80% → A
      final rich = [
        for (var d = 0; d < 5; d++)
          _rec(
              crid: 'r$d',
              petId: 'p1',
              start: DateTime(2026, 8, 31 + d, 8)),
      ];
      final s2 = WeeklySummary.compute(rich, _now);
      expect(s2.completionRate, 83); // 5/6
      expect(s2.grade, 'A');
      expect(s2.gradeLabel, '优秀');
    });

    test('零记录：显示"本周还没开始"', () {
      final s = WeeklySummary.compute([], _now);
      expect(s.totalMinutes, 0);
      expect(s.grade, '-');
      expect(s.gradeLabel, '本周还没开始');
      expect(s.completionRate, 0);
    });

    test('minutesByPet / countByPet：按宠物分组', () {
      final records = [
        _rec(crid: 'a', petId: 'p1', start: _mon(8), durationSec: 600),
        _rec(crid: 'b', petId: 'p1', start: _sat(9), durationSec: 300),
        _rec(crid: 'c', petId: 'p2', start: _sat(10), durationSec: 120),
      ];
      final minutes = WeeklySummary.minutesByPet(records, _now);
      final counts = WeeklySummary.countByPet(records, _now);
      expect(minutes['p1'], 15);
      expect(minutes['p2'], 2);
      expect(counts['p1'], 2);
      expect(counts['p2'], 1);
    });
  });
}
