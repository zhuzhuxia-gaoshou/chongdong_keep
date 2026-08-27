import 'package:flutter_test/flutter_test.dart';
import 'package:chongdong_keep/models/dto/user_dto.dart';
import 'package:chongdong_keep/models/user.dart';

void main() {
  const wire = <String, dynamic>{
    'id': 'u_1001',
    'phone': '138****8000',
    'nickname': '铲屎官·测试',
    'avatarUrl': null,
    'createdAt': '2026-08-01T09:00:00+08:00',
    'totalExerciseCount': 12,
    'streakDays': 5,
    'signCardCount': 3,
  };

  test('fromWire：脱敏手机号直传、统计字段保真', () {
    final u = UserDto.fromWire(wire);
    expect(u.id, 'u_1001');
    expect(u.phone, '138****8000');
    expect(u.streakDays, 5);
    expect(u.signCardCount, 3);
  });

  test('fromWire：带时区时间解析为同一时刻', () {
    final u = UserDto.fromWire(wire);
    // Dart 约定：带偏移的输入转为同一时刻的 UTC 对象
    expect(u.createdAt.toUtc(), DateTime.utc(2026, 8, 1, 1, 0));
  });

  test('fromWire：字段缺失/类型异常时回退默认值', () {
    final u = UserDto.fromWire({
      'id': 'u_x',
      'phone': 'p',
      'nickname': 'n',
      'createdAt': null,
      'streakDays': 'bad',
    });
    expect(u.streakDays, 0);
    expect(u.signCardCount, 3);
    expect(u.avatarUrl, isNull);
  });

  test('toWire/fromWire 往返一致（同一时刻）', () {
    final u = AppUser(
      id: 'u_9',
      phone: '138****0000',
      nickname: '往返',
      createdAt: DateTime.utc(2026, 8, 27, 2, 30),
      streakDays: 7,
      signCardCount: 2,
      totalExerciseCount: 99,
    );
    final back = UserDto.fromWire(UserDto.toWire(u));
    expect(back.id, u.id);
    expect(back.streakDays, 7);
    expect(back.signCardCount, 2);
    expect(back.createdAt.toUtc(), u.createdAt.toUtc());
  });
}
