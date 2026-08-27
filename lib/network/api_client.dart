import 'token_store.dart';
import 'transport.dart';
import 'api_exception.dart';

/// 统一 API 客户端：Bearer 注入、40101 单飞刷新并重放一次、会话失效回调。
///
/// 业务错误码不做解释（交给各 Repository 调 [unwrapEnvelope]）；
/// 仅 40101 触发刷新链路，且同一时刻并发多个失败请求只会触发一次刷新
/// （单飞保证）；刷新后重放**至多一次**。刷新请求直连 transport，
/// 不经过本类鉴权管道，天然避免递归。
class ApiClient {
  ApiClient(this._transport, this._tokens);

  final Transport _transport;
  final TokenStore _tokens;

  /// 刷新彻底失效(40104/无凭据)时由本类调用——AppState 注册它执行强制登出
  void Function()? onSessionExpired;

  SessionTokens? _cached;
  Future<bool>? _refreshInFlight;
  bool _lastRefreshHardInvalid = false;

  void resetTokenCache() => _cached = null;

  // ---- 便捷入口 ----

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) =>
      _send('GET', path, query: query, auth: auth);

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> upload(
    String path, {
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) =>
      _send('POST', path,
          bytes: bytes, filename: filename, fields: fields, fileField: 'file');

  /// 连通性探测（免鉴权）。拿到任何信封都视为存活；仅网络层故障返回 false。
  Future<bool> ping() async {
    try {
      await _send('GET', '/api/v1/ping', auth: false);
      return true;
    } on ApiException {
      return false;
    }
  }

  // ---- 内部 ----

  Future<SessionTokens?> get _session async {
    return _cached ??= await _tokens.read();
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
    List<int>? bytes,
    String? filename,
    String fileField = 'file',
    Map<String, String> fields = const {},
  }) async {
    for (var attempt = 0;; attempt++) {
      Map<String, String>? headers;
      var carriedToken = false;
      if (auth) {
        final session = await _session;
        if (session != null) {
          headers = {'Authorization': 'Bearer ${session.accessToken}'};
          carriedToken = true;
        }
      }

      final Map<String, dynamic>? envelope;
      try {
        envelope = bytes != null
            ? await _transport.sendMultipart(path,
                bytes: bytes, filename: filename ?? 'file.bin',
                fields: fields, headers: headers)
            : await _transport.send(method, path,
                body: body, query: query, headers: headers);
      } on ApiException {
        // 网络故障/无信封401在传输层已定型，统一原样上抛，不在本层重试
        rethrow;
      }

      final rawCode = envelope?['code'];
      final code =
          rawCode is int ? rawCode : int.tryParse('${rawCode ?? ''}');
      final expired = code == kCodeAccessExpired;

      // 仅"本就携带凭据的请求"才进入刷新链路；匿名请求的 40101
      // （如未登录调受保护接口）原样上抛，由上层按业务错误处理。
      if (expired && carriedToken && attempt == 0) {
        final ok = await _refreshOnce();
        if (ok) continue; // 用新 token 重放恰好一次
        if (_lastRefreshHardInvalid) {
          await _forceSignOut();
          throw ApiException(kCodeRefreshInvalid, '登录已过期');
        }
        // 刷新期间网络抖动：保留 token、原样上抛首个异常，不清登录态
        throw ApiException(kCodeAccessExpired, '请检查网络后重试');
      }
      return envelope!;
    }
  }

  /// 单飞刷新：并发场景只发起一次真实刷新请求。
  Future<bool> _refreshOnce() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final session = await _session;
    if (session == null || session.refreshToken.isEmpty) {
      _lastRefreshHardInvalid = true;
      return false;
    }
    try {
      // 刷新请求刻意不走本类的鉴权管道，避免递归
      final envelope = await _transport.send(
        'POST',
        '/api/v1/auth/refresh',
        body: {'refreshToken': session.refreshToken},
      );
      final data = unwrapEnvelope(envelope);
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      final expiresIn = data['expiresIn'] as int? ?? 3600;
      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        _lastRefreshHardInvalid = true;
        return false;
      }
      final next = SessionTokens(
        accessToken: access,
        refreshToken: refresh,
        expiresAtMs:
            DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch,
      );
      _cached = next;
      await _tokens.save(next);
      _lastRefreshHardInvalid = false;
      return true;
    } on ApiException catch (e) {
      if (e.code == kCodeRefreshInvalid) {
        _lastRefreshHardInvalid = true;
        return false;
      }
      _lastRefreshHardInvalid = false; // 网络/服务端抖动：不清登录态
      return false;
    }
  }

  Future<void> _forceSignOut() async {
    await _tokens.clear();
    _cached = null;
    onSessionExpired?.call();
  }
}
