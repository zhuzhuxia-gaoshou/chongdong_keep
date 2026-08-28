import 'package:chongdong_keep/models/dto/record_dto.dart';
import 'package:chongdong_keep/models/exercise_record.dart';
import 'package:flutter_test/flutter_test.dart';

GeoPoint _pt(double lat, double lng, int sec) => GeoPoint(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 8, 28, 10, 0).add(Duration(seconds: sec)),
    );

ExerciseRecord _rec({
  ExerciseType type = ExerciseType.walkDog,
  List<GeoPoint> route = const [],
  String? photoPath = '/data/local/tmp/start.jpg',
  bool isManual = false,
}) =>
    ExerciseRecord(
      id: 'r_local',
      clientRecordId: 'crid-1',
      petId: 'p_1',
      userId: 'u_1',
      type: type,
      startTime: DateTime(2026, 8, 28, 10, 0),
      endTime: DateTime(2026, 8, 28, 10, 31),
      duration: const Duration(seconds: 1860),
      distance: 2.35,
      steps: 4700,
      route: route,
      locationName: '武汉市·东湖绿道',
      startPhotoPath: photoPath,
      isManual: isManual,
    );

void main() {
  group('RecordDto.toWire（契约 §4.6 ⑭）', () {
    test('本地图片路径绝不上网：startPhotoPath → startPhotoUrl=null', () {
      final wire = RecordDto.toWire(_rec());
      expect(wire['startPhotoUrl'], isNull);
      expect(wire.containsKey('startPhotoUrl'), isTrue);
    });

    test('已是远端 URL 的 startPhotoPath 按 startPhotoUrl 上送', () {
      final wire =
          RecordDto.toWire(_rec(photoPath: 'https://cdn.x/a.jpg'));
      expect(wire['startPhotoUrl'], 'https://cdn.x/a.jpg');
    });

    test('枚举出网为字符串、时间带时区偏移、不含 id/userId/createdAt', () {
      final wire = RecordDto.toWire(_rec(type: ExerciseType.catPlay));
      expect(wire['type'], 'catPlay');
      expect(wire['startTime'], contains(RegExp(r'[+-]\d{2}:\d{2}$')));
      expect(wire['clientRecordId'], 'crid-1');
      expect(wire.containsKey('id'), isFalse);
      expect(wire.containsKey('userId'), isFalse);
      expect(wire.containsKey('createdAt'), isFalse);
      expect(wire['duration'], 1860);
    });

    test('route 超 5000 点等距抽稀且必留末点', () {
      final big = List<GeoPoint>.generate(6000, (i) => _pt(30, 120, i));
      final wire = RecordDto.toWire(_rec(route: big));
      final route = wire['route'] as List;
      expect(route.length, lessThanOrEqualTo(RecordDto.maxRoutePoints + 1));
      expect(route.length, 3001); // step=2 → 3000 点 + 补末点
      expect((route.last as Map)['longitude'], 120.0);
    });

    test('未超限时轨迹原样透传', () {
      final wire = RecordDto.toWire(_rec(route: [_pt(1, 2, 0), _pt(3, 4, 5)]));
      expect((wire['route'] as List).length, 2);
    });
  });

  group('RecordDto.fromWire（宽容解析，服务端字段增减不崩）', () {
    test('数值字符串/缺失字段全部降级为默认值', () {
      final r = RecordDto.fromWire({
        'id': 'r_9',
        'petId': 'p_9',
        'userId': 'u_9',
        'type': 'catPlay',
        'startTime': '2026-08-28T10:00:00+08:00',
        'endTime': '2026-08-28T10:06:00+08:00',
        'duration': '360', // 字符串（联调 D1 同类问题，须容错）
        'distance': '1.2',
      });
      expect(r.duration, const Duration(seconds: 360));
      expect(r.distance, 1.2);
      expect(r.steps, 0);
      expect(r.route, isEmpty);
      expect(r.clientRecordId, isNull);
    });

    test('CDN 地址不回填 startPhotoPath（本地模型按文件路径消费）', () {
      final r = RecordDto.fromWire({
        'id': 'r_9',
        'petId': 'p',
        'userId': 'u',
        'startTime': '2026-08-28T10:00:00+08:00',
        'endTime': '2026-08-28T10:10:00+08:00',
        'duration': 600,
        'startPhotoUrl': 'https://cdn.x/a.jpg',
      });
      expect(r.startPhotoPath, isNull);
    });

    test('非法时间/非法轨迹点安全丢弃，endTime 早于 startTime 收敛为 start', () {
      final r = RecordDto.fromWire({
        'id': 'r_9',
        'petId': 'p',
        'userId': 'u',
        'startTime': 'not-a-date',
        'endTime': 'also-bad',
        'route': [
          {'latitude': 30.5, 'longitude': 114.3, 'timestamp': '2026-08-28T10:00:00+08:00'},
          {'latitude': null, 'longitude': 114.3}, // 缺纬度 → 丢弃
          'junk', // 非 Map → 丢弃
        ],
      });
      expect(r.endTime, r.startTime);
      expect(r.duration, Duration.zero);
      expect(r.route.length, 1);
    });
  });

  test('round-trip：toWire → fromWire 关键字段无损', () {
    final original = _rec(route: [_pt(30.5, 114.3, 0), _pt(30.6, 114.4, 10)]);
    final back = RecordDto.fromWire({
      ...RecordDto.toWire(original),
      'id': 'r_server',
      'userId': 'u_server',
    });
    expect(back.id, 'r_server');
    expect(back.clientRecordId, 'crid-1');
    expect(back.petId, 'p_1');
    expect(back.type, ExerciseType.walkDog);
    expect(back.duration, original.duration);
    expect(back.distance, original.distance);
    expect(back.steps, original.steps);
    expect(back.route.length, 2);
    expect(back.route.first.latitude, 30.5);
    expect(back.locationName, '武汉市·东湖绿道');
    // 打卡口径与旧 canCheckIn 在"完成且≥5分钟"上等价
    expect(back.countsAsCheckIn, isTrue);
  });
}
