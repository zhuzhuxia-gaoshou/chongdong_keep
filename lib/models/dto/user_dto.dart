import '../../utils/iso_time.dart';
import '../user.dart';

/// 服务端 UserDTO ↔ 本地 AppUser 转换（契约 §三）。
///
/// 转换只发生在接口边界：本地持久化格式（StorageService）保持
/// AppUser.toJson 原样，互不渗透。
class UserDto {
  const UserDto._();

  /// 服务端结构 → AppUser。
  /// 带时区偏移的时间按 Dart 约定转为同一时刻的 UTC 对象；
  /// 数值字段缺失/类型异常时回退默认值，保证脏数据不打断界面。
  static AppUser fromWire(Map<String, dynamic> j) => AppUser(
        id: (j['id'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        nickname: (j['nickname'] ?? '') as String,
        avatarUrl: j['avatarUrl'] as String?,
        createdAt:
            tryParseIsoWithOffset(j['createdAt'] as String?) ?? DateTime.now(),
        totalExerciseCount: _asInt(j['totalExerciseCount']) ?? 0,
        streakDays: _asInt(j['streakDays']) ?? 0,
        signCardCount: _asInt(j['signCardCount']) ?? 3,
      );

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  /// AppUser → 线上结构。M1 没有上报用户资料的写路径，仅作对称与测试用。
  static Map<String, dynamic> toWire(AppUser u) => {
        'id': u.id,
        'phone': u.phone,
        'nickname': u.nickname,
        'avatarUrl': u.avatarUrl,
        'createdAt': formatIsoWithOffset(u.createdAt),
        'totalExerciseCount': u.totalExerciseCount,
        'streakDays': u.streakDays,
        'signCardCount': u.signCardCount,
      };
}
