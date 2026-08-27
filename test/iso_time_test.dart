import 'package:flutter_test/flutter_test.dart';
import 'package:chongdong_keep/utils/iso_time.dart';

void main() {
  group('tryParseIsoWithOffset', () {
    test('解析带 +08:00 偏移的契约时间', () {
      final dt = tryParseIsoWithOffset('2026-08-27T14:30:00+08:00');
      expect(dt, isNotNull);
      // Dart 约定：带偏移量的输入会被转为同一时刻的 UTC 对象存储
      expect(dt!.isUtc, isTrue);
      expect(dt.toUtc(), DateTime.utc(2026, 8, 27, 6, 30));
    });

    test('非法/空输入返回 null 而非抛异常', () {
      expect(tryParseIsoWithOffset(null), isNull);
      expect(tryParseIsoWithOffset(''), isNull);
      expect(tryParseIsoWithOffset('not-a-date'), isNull);
    });
  });

  group('formatIsoWithOffset', () {
    test('输出恒带 ±HH:mm 后缀且不含 Z', () {
      final out = formatIsoWithOffset(DateTime.parse('2026-08-27T14:30:00'));
      expect(out, matches(RegExp(r'[+-]\d{2}:\d{2}$')));
      expect(out.endsWith('Z'), isFalse);
    });

    test('UTC 输入转本地后保持同一时刻（往返一致）', () {
      const wire = '2026-08-27T06:30:00Z';
      final roundTrip = formatIsoWithOffset(DateTime.parse(wire));
      expect(
        DateTime.parse(roundTrip).toUtc(),
        DateTime.parse(wire).toUtc(),
      );
    });

    test('本地时间往返无损', () {
      final now = DateTime.now();
      final out = formatIsoWithOffset(now);
      final back = DateTime.parse(out);
      expect(back.isAtSameMomentAs(now), isTrue);
    });
  });
}
