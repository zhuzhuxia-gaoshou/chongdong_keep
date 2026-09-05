import 'reminder_service.dart';

/// Web 空实现：浏览器构建无本地通知能力，保持设置页逻辑统一。
class ReminderServiceStub implements ReminderService {
  @override
  Future<bool> ensurePermission() async => false;

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {}

  @override
  Future<void> cancelDaily() async {}
}

final ReminderService service = ReminderServiceStub();
