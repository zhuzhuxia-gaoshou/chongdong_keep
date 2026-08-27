import 'package:shared_preferences/shared_preferences.dart';

/// 会话令牌三件套（对应契约 /auth/login 响应）。
class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtMs,
  });

  final String accessToken;
  final String refreshToken;

  /// accessToken 绝对过期时间戳（毫秒），由登录时 expiresIn 折算而来
  final int expiresAtMs;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= expiresAtMs;
}

/// 登录态凭据持久化。
///
/// Key 归属约定：本类独占 `auth_*` 三键；用户/宠物/记录/天气缓存仍归
/// StorageService；登出时由 AppState 统一调度两侧清理。
/// 做成实例类便于测试注入假 SharedPreferences。
class TokenStore {
  TokenStore({Future<SharedPreferences>? prefs})
      : _prefsFuture = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefsFuture;

  static const String _kAccess = 'auth_access_token';
  static const String _kRefresh = 'auth_refresh_token';
  static const String _kExpires = 'auth_expires_at_ms';

  Future<void> save(SessionTokens t) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_kAccess, t.accessToken);
    await prefs.setString(_kRefresh, t.refreshToken);
    await prefs.setInt(_kExpires, t.expiresAtMs);
  }

  Future<SessionTokens?> read() async {
    final prefs = await _prefsFuture;
    final access = prefs.getString(_kAccess);
    final refresh = prefs.getString(_kRefresh);
    final expires = prefs.getInt(_kExpires);
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty ||
        expires == null) {
      return null;
    }
    return SessionTokens(
        accessToken: access, refreshToken: refresh, expiresAtMs: expires);
  }

  Future<void> clear() async {
    final prefs = await _prefsFuture;
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kExpires);
  }
}
