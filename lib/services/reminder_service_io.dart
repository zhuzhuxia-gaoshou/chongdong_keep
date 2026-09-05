import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_service.dart';

/// 移动端实现：flutter_local_notifications 每日定时本地通知。
/// 用非精确闹钟（inexactAllowWhileIdle）避免精确闹钟的系统授权与上架合规问题，
/// 提醒可能延后几分钟，对遛狗场景可接受。
class ReminderServiceIo implements ReminderService {
  static const int _reminderId = 1001;
  static const String _channelId = 'walk_reminder';

  bool _inited = false;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _ensureInit() async {
    if (_inited) return;
    // 当前只有 Android 出包；iOS 目标加入时补 DarwinInitializationSettings
    await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher')));
    _inited = true;
  }

  @override
  Future<bool> ensurePermission() async {
    await _ensureInit();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await _ensureInit();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      _reminderId,
      '该遛狗啦',
      '和宝贝一起出门走走吧，运动打卡别忘啦',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '运动提醒',
          channelDescription: '每天定时提醒遛狗打卡',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDaily() async {
    await _ensureInit();
    await _plugin.cancel(_reminderId);
  }
}

final ReminderService service = ReminderServiceIo();
