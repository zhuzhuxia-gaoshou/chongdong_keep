import 'reminder_service_io.dart'
    if (dart.library.html) 'reminder_service_stub.dart' as impl;

/// 运动提醒（本地通知）统一入口：
/// - 移动端 → 系统本地通知（flutter_local_notifications + timezone 定时）
/// - Web → 空实现（浏览器构建无本地通知能力）
abstract class ReminderService {
  static ReminderService get instance => impl.service;

  /// 请求通知权限（Android 13+ 运行时授权）。返回是否已获授权。
  Future<bool> ensurePermission();

  /// 调度每天 [hour]:[minute] 的遛狗提醒（当日时刻已过则从明天开始）。
  Future<void> scheduleDaily({required int hour, required int minute});

  /// 取消每日提醒。
  Future<void> cancelDaily();
}
