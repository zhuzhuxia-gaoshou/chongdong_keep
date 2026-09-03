import 'package:flutter_test/flutter_test.dart';
import 'package:chongdong_keep/services/upload_retry_schedule.dart';

void main() {
  group('UploadRetrySchedule', () {
    test('退避序列：30s → 1m → 2m → 5m', () {
      expect(UploadRetrySchedule.nextDelay(1), const Duration(seconds: 30));
      expect(UploadRetrySchedule.nextDelay(2), const Duration(minutes: 1));
      expect(UploadRetrySchedule.nextDelay(3), const Duration(minutes: 2));
      expect(UploadRetrySchedule.nextDelay(4), const Duration(minutes: 5));
    });

    test('超出序列后封顶循环使用最后一级 5 分钟', () {
      expect(UploadRetrySchedule.nextDelay(5), const Duration(minutes: 5));
      expect(UploadRetrySchedule.nextDelay(6), const Duration(minutes: 5));
      expect(UploadRetrySchedule.nextDelay(100), const Duration(minutes: 5));
    });

    test('防御：非正数失败次数按首次处理', () {
      expect(UploadRetrySchedule.nextDelay(0), const Duration(seconds: 30));
      expect(UploadRetrySchedule.nextDelay(-3), const Duration(seconds: 30));
    });

    test('间隔单调不减且永不超过 5 分钟', () {
      for (var i = 1; i <= 20; i++) {
        final d = UploadRetrySchedule.nextDelay(i);
        expect(d, lessThanOrEqualTo(const Duration(minutes: 5)));
        expect(d, greaterThanOrEqualTo(UploadRetrySchedule.nextDelay(i - 1 < 1 ? 1 : i - 1)));
      }
    });
  });
}
