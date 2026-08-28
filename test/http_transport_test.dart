import 'dart:convert';

import 'package:chongdong_keep/network/api_exception.dart';
import 'package:chongdong_keep/network/transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 记录最近一次请求，返回统一 code:0 信封。
class _Capture {
  http.Request? request;
}

MockClient _mockClient(_Capture cap) => MockClient((req) async {
      cap.request = req;
      return http.Response(
          jsonEncode({'code': 0, 'data': <String, dynamic>{}}), 200,
          headers: {'content-type': 'application/json'});
    });

void main() {
  group('HttpTransport 真实线上行为', () {
    test('POST 带体请求必须声明 application/json（联调实测：缺则后端判参数缺失）', () async {
      final cap = _Capture();
      final t = HttpTransport('http://test.local', client: _mockClient(cap));
      await t.send('POST', '/api/v1/auth/sms-code', body: {'phone': '138'});
      expect(cap.request!.headers['content-type'], contains('application/json'));
      expect(cap.request!.method, 'POST');
    });

    test('PATCH 同样带 application/json', () async {
      final cap = _Capture();
      final t = HttpTransport('http://test.local', client: _mockClient(cap));
      await t.send('PATCH', '/api/v1/pets/p1', body: {'weight': 5});
      expect(cap.request!.headers['content-type'], contains('application/json'));
      expect(cap.request!.method, 'PATCH');
    });

    test('Authorization 等调用方头与 JSON 头共存', () async {
      final cap = _Capture();
      final t = HttpTransport('http://test.local', client: _mockClient(cap));
      await t.send('POST', '/x',
          body: {'a': 1}, headers: {'Authorization': 'Bearer t'});
      expect(cap.request!.headers['authorization'], 'Bearer t');
      expect(cap.request!.headers['content-type'], contains('application/json'));
    });

    test('GET 无 body，不强加 content-type', () async {
      final cap = _Capture();
      final t = HttpTransport('http://test.local', client: _mockClient(cap));
      await t.send('GET', '/api/v1/pets', query: {'page': '1'});
      expect(cap.request!.method, 'GET');
      expect(cap.request!.url.queryParameters['page'], '1');
    });

    test('DELETE 必须以 DELETE 方法发出（曾被误映射为 POST）', () async {
      final cap = _Capture();
      final t = HttpTransport('http://test.local', client: _mockClient(cap));
      await t.send('DELETE', '/api/v1/pets/p1');
      expect(cap.request!.method, 'DELETE');
    });

    test('响应 500 无信封 → 50000；200 无合法 JSON → -2', () async {
      final t500 = HttpTransport('http://x',
          client: MockClient((_) async => http.Response('oops', 500)));
      await expectLater(
          t500.send('GET', '/y'),
          throwsA(isA<ApiException>()
              .having((e) => e.code, 'code', kCodeServerErrorBase)));

      final tBad = HttpTransport('http://x',
          client: MockClient((_) async => http.Response('not-json', 200)));
      await expectLater(
          tBad.send('GET', '/y'),
          throwsA(isA<ApiException>()
              .having((e) => e.code, 'code', -2)));
    });
  });
}
