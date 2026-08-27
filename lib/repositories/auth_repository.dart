import '../models/dto/user_dto.dart';
import '../models/user.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/token_store.dart';

/// 登录成功结果
class LoginResult {
  const LoginResult({required this.user, required this.isNewUser});

  final AppUser user;
  final bool isNewUser;
}

/// 认证域门面：发码 / 登录 / 登出。登录成功即落凭据并复位客户端缓存。
class AuthRepository {
  AuthRepository(this._client, this._tokens);

  final ApiClient _client;
  final TokenStore _tokens;

  Future<void> sendSmsCode(String phone) async {
    unwrapEnvelope(
        await _client.post('/api/v1/auth/sms-code', body: {'phone': phone}));
  }

  /// 登录：换回 token 三件套并持久化（副作用），返回会话用户。
  Future<LoginResult> login(String phone, String smsCode) async {
    final data = unwrapEnvelope(await _client.post('/api/v1/auth/login',
        body: {'phone': phone, 'smsCode': smsCode}));
    final tokens = SessionTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresAtMs: DateTime.now()
          .add(Duration(seconds: (data['expiresIn'] as int?) ?? 3600))
          .millisecondsSinceEpoch,
    );
    await _tokens.save(tokens);
    _client.resetTokenCache();
    return LoginResult(
      user: UserDto.fromWire(data['user'] as Map<String, dynamic>),
      isNewUser: (data['isNewUser'] as bool?) ?? false,
    );
  }

  /// 登出：无论服务端调用成败，本地凭据一律清空。
  Future<void> logout() async {
    try {
      await _client.post('/api/v1/auth/logout');
    } on ApiException {
      // 网络失败也继续清本地，不让"退出卡住"
    }
    await _tokens.clear();
    _client.resetTokenCache();
  }
}
