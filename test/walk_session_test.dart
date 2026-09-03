import 'package:flutter_test/flutter_test.dart';
import 'package:chongdong_keep/models/walk_session.dart';
import 'package:chongdong_keep/models/exercise_record.dart';

WalkSession _sample({int routePoints = 3}) => WalkSession(
      selectedPetIds: ['p_1', 'p_2'],
      startTime: DateTime.parse('2026-09-03T10:00:00+08:00'),
      elapsedSeconds: 754,
      route: List.generate(
        routePoints,
        (i) => GeoPoint(
          latitude: 31.2 + i * 0.001,
          longitude: 121.4 + i * 0.001,
          timestamp: DateTime.parse('2026-09-03T10:00:00+08:00')
              .add(Duration(minutes: i)),
          accuracy: 8.0 + i,
        ),
      ),
      distance: 1.23,
      steps: 2460,
      locationName: '上海市浦东新区',
      startPhotoPath: '/data/img.jpg',
      currentLat: 31.203,
      currentLng: 121.403,
    );

void main() {
  group('WalkSession', () {
    test('toJson/fromJson 往返一致', () {
      final s = _sample();
      final restored = WalkSession.fromJson(s.toJson());
      expect(restored.selectedPetIds, ['p_1', 'p_2']);
      expect(restored.startTime, s.startTime);
      expect(restored.elapsedSeconds, 754);
      expect(restored.route.length, 3);
      expect(restored.route[1].latitude, closeTo(31.201, 1e-9));
      expect(restored.route[1].longitude, closeTo(121.401, 1e-9));
      expect(restored.distance, 1.23);
      expect(restored.steps, 2460);
      expect(restored.locationName, '上海市浦东新区');
      expect(restored.startPhotoPath, '/data/img.jpg');
      expect(restored.currentLat, 31.203);
      expect(restored.currentLng, 121.403);
    });

    test('route 超限裁头：保留最近 maxRoutePoints 个点', () {
      final s = _sample(routePoints: WalkSession.maxRoutePoints + 500);
      expect(s.route.length, WalkSession.maxRoutePoints + 500);
      expect(s.routeCapped.length, WalkSession.maxRoutePoints);
      // 裁掉的是头部
      expect(s.routeCapped.first.latitude,
          closeTo(s.route[s.route.length - WalkSession.maxRoutePoints].latitude,
              1e-9));
      // 序列化输出也是裁剪后的
      final json = s.toJson();
      expect((json['route'] as List).length, WalkSession.maxRoutePoints);
    });

    test('route 未超限原样保留', () {
      final s = _sample(routePoints: 10);
      expect(s.routeCapped.length, 10);
    });

    test('fromJson 容忍缺字段', () {
      final s = WalkSession.fromJson({
        'selectedPetIds': ['p_1'],
        'startTime': '2026-09-03T10:00:00+08:00',
      });
      expect(s.elapsedSeconds, 0);
      expect(s.route, isEmpty);
      expect(s.distance, 0.0);
      expect(s.locationName, '');
      expect(s.startPhotoPath, isNull);
      expect(s.currentLat, 39.9); // 默认北京
    });
  });
}
