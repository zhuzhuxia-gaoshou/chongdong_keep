import 'package:flutter_test/flutter_test.dart';
import 'package:chongdong_keep/network/api_exception.dart';

void main() {
  group('unwrapEnvelope', () {
    test('code=0 返回 data 且保留字段', () {
      final data = unwrapEnvelope({
        'code': 0,
        'message': 'ok',
        'data': {'nickname': '旺财主人'},
      });
      expect(data['nickname'], '旺财主人');
    });

    test('data 缺失时返回空 Map', () {
      expect(unwrapEnvelope({'code': 0, 'message': 'ok'}), isEmpty);
    });

    test('data 为列表时包装为 {list}', () {
      final data = unwrapEnvelope({
        'code': 0,
        'data': [1, 2],
      });
      expect(data['list'], [1, 2]);
    });

    test('业务错误码抛出 ApiException 并保留原 message', () {
      expect(
        () => unwrapEnvelope({
          'code': 40102,
          'message': '验证码错误',
          'httpStatus': 200,
        }),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 40102)
              .having((e) => e.message, 'message', '验证码错误'),
        ),
      );
    });

    test('信封为 null / 缺 code 时按服务端异常处理(50000)', () {
      for (final bad in [null, {'foo': 1}]) {
        expect(() => unwrapEnvelope(bad),
            throwsA(isA<ApiException>().having((e) => e.code, 'code', 50000)));
      }
    });
  });

  group('ApiException.friendlyMessage', () {
    test('传输层故障给出网络文案', () {
      expect(ApiException(-1, 'timeout').friendlyMessage, contains('网络'));
    });

    test('已知码命中专属文案（不展示裸数字）', () {
      expect(ApiException(kCodeSmsTooFrequent, '').friendlyMessage,
          contains('频繁'));
      expect(ApiException(kCodeNicknameInvalid, '').friendlyMessage,
          contains('昵称'));
      expect(ApiException(kCodeUploadType, '').friendlyMessage, contains('图片'));
    });

    test('分段兜底：限流段/服务端段/未知段', () {
      expect(ApiException(42909, '').friendlyMessage, contains('太频繁'));
      expect(ApiException(50001, '').friendlyMessage, contains('服务器'));
      expect(ApiException(40999, '').friendlyMessage, contains('请求失败'));
    });

    test('任何文案都不暴露裸错误码数字', () {
      const samples = [
        40001, 40006, 40101, 40301, 40401, 42901, 50000, -1, -2,
      ];
      for (final c in samples) {
        final msg = ApiException(c, 'x').friendlyMessage;
        expect(msg.contains('$c'), isFalse, reason: 'code=$c 泄漏进了文案');
      }
    });
  });
}
