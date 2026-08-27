import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chongdong_keep/network/api_client.dart';
import 'package:chongdong_keep/network/api_exception.dart';
import 'package:chongdong_keep/network/token_store.dart';
import 'package:chongdong_keep/network/transport.dart';

/// 可脚本化的假传输层：按 (method,path) 消费响应队列；记录全部请求。
class FakeTransport implements Transport {
  final _queue = <String, List<Object>>{}; // 响应：Map=信封 / ApiException=故障
  final requests = <({String method, String path, Map<String, String>? headers})>[];

  void enqueue(String key, Object response) =>
      (_queue[key] ??= []).add(response);

  int count(String path) =>
      requests.where((r) => r.path == path).length;

  @override
  Future<Map<String, dynamic>?> send(String method, String path,
      {Object? body, Map<String, String>? query, Map<String, String>? headers}) async {
    requests.add((method: method, path: path, headers: headers));
    final next = (_queue['$method $path'] ?? []).isEmpty
        ? null
        : _queue['$method $path']!.removeAt(0);
    if (next is ApiException) throw next;
    return next as Map<String, dynamic>?;
  }

  @override
  Future<Map<String, dynamic>?> sendMultipart(String path,
      {required List<int> bytes,
      required String filename,
      String fileField = 'file',
      Map<String, String> fields = const {},
      Map<String, String>? headers}) async {
    throw UnimplementedError();
  }
}

const ok = {'code': 0, 'data': {}};
const expired = {'code': 40101};
Map<String, dynamic> refreshed({String access = 'v2', String refresh = 'r2'}) =>
    {
      'code': 0,
      'data': {
        'accessToken': access,
        'refreshToken': refresh,
        'expiresIn': 3600,
      },
    };

Future<TokenStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return TokenStore(prefs: SharedPreferences.getInstance());
}

Future<void> seedAccess(TokenStore store,
    {String access = 'v1', String refresh = 'r1'}) {
  return store.save(SessionTokens(
      accessToken: access, refreshToken: refresh, expiresAtMs: 9999999999999));
}

void main() {
  test('40101 → 刷新 → 用新 token 重放恰好一次', () async {
    final t = FakeTransport()
      ..enqueue('GET /x', expired)
      ..enqueue('POST /api/v1/auth/refresh', refreshed())
      ..enqueue('GET /x', ok);
    final store = await freshStore();
    await seedAccess(store);
    final client = ApiClient(t, store);

    final data = unwrapEnvelope(await client.get('/x'));

    expect(data, isEmpty); // code=0 空 data
    expect(t.count('/api/v1/auth/refresh'), 1);
    expect(t.count('/x'), 2);
    expect(t.requests.last.headers?['Authorization'], 'Bearer v2');
    // 新 token 已持久化
    final saved = await store.read();
    expect(saved?.accessToken, 'v2');
    expect(saved?.refreshToken, 'r2');
  });

  test('并发两个 40101 只触发一次刷新（单飞）', () async {
    final t = FakeTransport()
      ..enqueue('GET /a', expired)
      ..enqueue('GET /b', expired)
      ..enqueue('POST /api/v1/auth/refresh', refreshed(access: 'v2b'))
      ..enqueue('GET /a', ok)
      ..enqueue('GET /b', ok);
    final store = await freshStore();
    await seedAccess(store);
    final client = ApiClient(t, store);

    await Future.wait([client.get('/a'), client.get('/b')]);

    expect(t.count('/api/v1/auth/refresh'), 1, reason: '并发必须合并为一次刷新');
    expect(t.requests.last.headers?['Authorization'], 'Bearer v2b');
  });

  test('刷新返回 40104 → 清 token、触发 onSessionExpired、上抛登录过期', () async {
    final t = FakeTransport()
      ..enqueue('GET /x', expired)
      ..enqueue('POST /api/v1/auth/refresh',
          {'code': 40104, 'message': 'refresh invalid'});
    final store = await freshStore();
    await seedAccess(store);
    var signOuts = 0;
    final client = ApiClient(t, store)
      ..onSessionExpired = () => signOuts++;

    await expectLater(
      client.get('/x'),
      throwsA(isA<ApiException>()
          .having((e) => e.isRefreshInvalid, 'isRefreshInvalid', isTrue)),
    );
    expect(await store.read(), isNull, reason: '失效后本地 token 必须清空');
    expect(signOuts, 1);
  });

  test('刷新期间网络故障 → 不清登录态、不登出、原样上抛', () async {
    final t = FakeTransport()
      ..enqueue('GET /x', expired)
      ..enqueue(
          'POST /api/v1/auth/refresh', ApiException(-1, 'network down'));
    final store = await freshStore();
    await seedAccess(store);
    var signOuts = 0;
    final client = ApiClient(t, store)
      ..onSessionExpired = () => signOuts++;

    await expectLater(client.get('/x'), throwsA(isA<ApiException>()));
    final kept = await store.read();
    expect(kept?.refreshToken, 'r1', reason: '网络抖动不得清空凭据');
    expect(signOuts, 0, reason: '网络抖动不得强制登出');
  });
}
