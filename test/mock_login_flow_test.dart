import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chongdong_keep/network/api_client.dart';
import 'package:chongdong_keep/network/api_exception.dart';
import 'package:chongdong_keep/network/token_store.dart';
import 'package:chongdong_keep/services/mock/mock_transport.dart';

/// 走完整链路：ApiClient ↔ MockTransport。
/// 约定：ApiClient 返回的是完整信封；业务码用 [unwrapEnvelope] 解释。
Future<TokenStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return TokenStore(prefs: SharedPreferences.getInstance());
}

/// 发码并登录 [phone]，把会话凭据落进 [store] 并重置客户端缓存。
Future<Map<String, dynamic>> loginAndPersist(
    ApiClient client, TokenStore store, String phone) async {
  await client.post('/api/v1/auth/sms-code', body: {'phone': phone});
  final data = unwrapEnvelope(await client.post('/api/v1/auth/login',
      body: {'phone': phone, 'smsCode': MockTransport.fixedSmsCode}));
  await store.save(SessionTokens(
    accessToken: data['accessToken'] as String,
    refreshToken: data['refreshToken'] as String,
    expiresAtMs: DateTime.now()
        .add(Duration(seconds: data['expiresIn'] as int))
        .millisecondsSinceEpoch,
  ));
  client.resetTokenCache();
  return data;
}

void main() {
  test('60 秒内重发验证码 → 信封 40103，文案含"频繁"', () async {
    final store = await freshStore();
    final client = ApiClient(MockTransport(), store);
    final phone = {'phone': '13800008000'};

    expect((await client.post('/api/v1/auth/sms-code', body: phone))['code'],
        0);
    final again =
        await client.post('/api/v1/auth/sms-code', body: phone);
    expect(again['code'], kCodeSmsTooFrequent);
    expect(ApiException(kCodeSmsTooFrequent, '').friendlyMessage,
        contains('频繁'));
  });

  test('错误验证码登录 → 信封 40102', () async {
    final store = await freshStore();
    final client = ApiClient(MockTransport(), store);
    await client.post('/api/v1/auth/sms-code',
        body: {'phone': '13800008000'});
    final envelope = await client.post('/api/v1/auth/login',
        body: {'phone': '13800008000', 'smsCode': '000000'});
    expect(envelope['code'], kCodeSmsWrong);
  });

  test('种子手机号登录成功 → 脱敏手机号与非零统计字段；可读资料', () async {
    final store = await freshStore();
    final client = ApiClient(MockTransport(), store);

    final data = await loginAndPersist(client, store, '13800008000');
    expect(data['isNewUser'], isFalse);
    expect(data['accessToken'], startsWith('mock-access-'));
    expect(data['user']['phone'], '138****8000');
    expect(data['user']['streakDays'], 5);
    expect(data['user']['signCardCount'], 3);

    final me = unwrapEnvelope(await client.get('/api/v1/users/me'));
    expect(me['nickname'], '铲屎官·测试');
  });

  test('access 过期 → 客户端透明刷新后照常取到 /users/me（token 已轮换）', () async {
    final mock = MockTransport();
    final store = await freshStore();
    final client = ApiClient(mock, store);

    final login =
        await loginAndPersist(client, store, '13900009000');
    final oldRefresh = login['refreshToken'] as String;

    mock.expireAllAccessTokens();
    final me = unwrapEnvelope(await client.get('/api/v1/users/me'));
    expect(me['id'], 'u_1002');

    final saved = await store.read();
    expect(saved?.refreshToken, isNot(equals(oldRefresh)),
        reason: '刷新必须轮换 refreshToken');
    expect(saved?.accessToken, startsWith('mock-access-'));
  });

  test('PATCH /users/me：超长昵称 40002；合法昵称去空格后生效', () async {
    final store = await freshStore();
    final client = ApiClient(MockTransport(), store);
    await loginAndPersist(client, store, '13800008000');

    final bad = await client
        .patch('/api/v1/users/me', body: {'nickname': 'x' * 13});
    expect(() => unwrapEnvelope(bad),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 40002)));

    final good = unwrapEnvelope(
        await client.patch('/api/v1/users/me', body: {'nickname': ' 新名字 '}));
    expect(good['nickname'], '新名字');
  });

  test('上传校验：gif 拒 40006、超大拒 40007、正常返回 mock URL', () async {
    final store = await freshStore();
    final client = ApiClient(MockTransport(), store);

    final wrongType = await client.upload('/api/v1/upload',
        bytes: List.filled(10, 0),
        filename: 'a.gif',
        fields: {'businessType': 'avatar'});
    expect(wrongType['code'], kCodeUploadType);

    final tooBig = await client.upload('/api/v1/upload',
        bytes: List.filled(2 * 1024 * 1024 + 1, 0),
        filename: 'a.png',
        fields: {'businessType': 'avatar'});
    expect(tooBig['code'], kCodeUploadSize);

    final okData = unwrapEnvelope(await client.upload('/api/v1/upload',
        bytes: List.filled(1024, 0),
        filename: 'a.png',
        fields: {'businessType': 'avatar'}));
    expect(okData['url'], startsWith('https://mock.cdn/avatar/'));
    expect(okData['fileSize'], 1024);
  });
}
