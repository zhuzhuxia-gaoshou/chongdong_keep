import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:chongdong_keep/utils/coord_convert.dart';

void main() {
  group('wgs84ToGcj02', () {
    test('国内坐标产生正向偏移且量级合理（100~800米）', () {
      // 北京天安门 WGS-84 参考值
      const lat = 39.9087;
      const lng = 116.3975;
      final (gLat, gLng) = wgs84ToGcj02(lat, lng);
      expect(gLat, greaterThan(lat));
      expect(gLat, lessThan(lat + 0.01));
      expect(gLng, greaterThan(lng));
      expect(gLng, lessThan(lng + 0.01));
      // 偏移量换算成米应在百米级（约 300~700m）
      final latMeters = (gLat - lat) * 111000;
      final lngMeters = (gLng - lng) * 111000 * 0.76; // 纬度39°的经度缩放
      final dist = math.sqrt(latMeters * latMeters + lngMeters * lngMeters);
      expect(dist, greaterThan(100));
      expect(dist, lessThan(800));
    });

    test('转换结果稳定（同输入同输出）', () {
      final a = wgs84ToGcj02(31.2304, 121.4737);
      final b = wgs84ToGcj02(31.2304, 121.4737);
      expect(a, equals(b));
    });

    test('境外坐标原样返回', () {
      // 东京
      expect(wgs84ToGcj02(35.6812, 139.7671), equals((35.6812, 139.7671)));
      // 纽约
      expect(wgs84ToGcj02(40.7128, -74.0060), equals((40.7128, -74.0060)));
    });

    test('范围外边界不崩溃', () {
      expect(wgs84ToGcj02(0, 0), equals((0.0, 0.0)));
      expect(wgs84ToGcj02(90, 180), equals((90.0, 180.0)));
    });
  });

  group('outOfChina', () {
    test('国内主要城市在范围内', () {
      expect(outOfChina(39.9, 116.4), isFalse); // 北京
      expect(outOfChina(31.23, 121.47), isFalse); // 上海
      expect(outOfChina(22.55, 114.05), isFalse); // 深圳
    });

    test('境外判定为真', () {
      expect(outOfChina(35.68, 139.77), isTrue); // 东京
      expect(outOfChina(40.71, -74.00), isTrue); // 纽约
      expect(outOfChina(0, 0), isTrue);
      // 注：粗矩形判定框较大，东南亚部分区域（如新加坡）会落在框内，
      // 属业界通用实现的已知取舍，国内主场景不受影响
    });
  });
}
