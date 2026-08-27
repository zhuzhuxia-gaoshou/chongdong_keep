import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chongdong_keep/network/api_client.dart';
import 'package:chongdong_keep/network/api_exception.dart';
import 'package:chongdong_keep/network/token_store.dart';
import 'package:chongdong_keep/repositories/auth_repository.dart';
import 'package:chongdong_keep/repositories/user_repository.dart';
import 'package:chongdong_keep/services/mock/mock_transport.dart';

Future<TokenStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return TokenStore(prefs: SharedPreferences.getInstance());
}

void main() {
  test('login 新老用户分流 + patchMe 服务端权威回包 + 登出闭环', () async {
    final store = await _freshStore();
    final client = ApiClient(MockTransport(), store);
    final auth = AuthRepository(client, store);
    final users = UserRepository(client);

    // 老用户：命中种子数据
    await auth.sendSmsCode('13800008000');
    final old = await auth.login('13800008000', MockTransport.fixedSmsCode);
    expect(old.isNewUser, isFalse);
    expect(old.user.nickname, '铲屎官·测试');
    expect(old.user.streakDays, 5);

    // 服务端统计字段不被资料编辑覆盖
    final patched = await users.patchMe(nickname: ' 新昵称 ');
    expect(patched.nickname, '新昵称');
    expect(patched.streakDays, 5);

    // 登出：本地凭据清空，后续请求抛登录过期
    await auth.logout();
    expect(await store.read(), isNull);
    await expectLater(
        users.fetchMe(),
        throwsA(
            isA<ApiException>().having((e) => e.code, 'code', 40101)));

    // 新用户：任意手机号首次登录 isNewUser=true
    await auth.sendSmsCode('13711112222');
    final fresh = await auth.login('13711112222', MockTransport.fixedSmsCode);
    expect(fresh.isNewUser, isTrue);
    expect(fresh.user.nickname, '铲屎官');
    expect(fresh.user.id, startsWith('u_'));
  });

  test('uploadAvatar：png 通过返回 URL；gif 客户端即拒', () async {
    final store = await _freshStore();
    final client = ApiClient(MockTransport(), store);
    final auth = AuthRepository(client, store);
    final users = UserRepository(client);

    await auth.sendSmsCode('13800008000');
    await auth.login('13800008000', MockTransport.fixedSmsCode);

    final png = XFile.fromData(Uint8List.fromList(List.filled(2048, 1)),
        name: 'avatar.png', mimeType: 'image/png');
    final ok = await users.uploadAvatar(png);
    expect(ok.url, startsWith('https://mock.cdn/avatar/'));

    // 仅带路径的构造（模拟部分平台拿不到 name 的情形）
    final gifByPath = XFile(r'C:\tmp\x.GIF');
    await expectLater(
      users.uploadAvatar(gifByPath),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', kCodeUploadType)),
    );

    // 名称路径全空 → 按 mimeType 判定
    final gifByMime = XFile.fromData(
        Uint8List(0),
        mimeType: 'image/gif');
    await expectLater(
      users.uploadAvatar(gifByMime),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', kCodeUploadType)),
    );
  });
}
