import '../../network/api_exception.dart';
import '../../network/transport.dart';
import '../../utils/iso_time.dart';

/// 内置假后端：按《API 接口契约》的信封与错误码行为实现，
/// 供 Live 环境就绪前的开发调试与自动化测试使用。
///
/// 行为要点：
/// - 固定验证码 [fixedSmsCode]；同号 60 秒内重发返回 40103；
/// - access token TTL 刻意调短（[accessTtl]），逼开发过程走完真实刷新链路；
/// - 业务错误以**信封透传**方式返回（{code:40101} 等），与真实后端一致。
class MockTransport implements Transport {
  MockTransport({
    this.delay = const Duration(milliseconds: 350),
    this.acceptAny6DigitCode = false,
  });

  static const String fixedSmsCode = '123456';

  /// access token 存活时长
  static const Duration accessTtl = Duration(seconds: 120);

  final Duration delay;

  /// true 时任意 6 位数字验证码均可登录（联调方便，默认关闭）
  final bool acceptAny6DigitCode;

  // ---- 内存态 ----
  final Map<String, Map<String, dynamic>> _usersByPhone = {
    '13800008000': _seedUser(
        id: 'u_1001',
        phoneMasked: '138****8000',
        nickname: '铲屎官·测试',
        streakDays: 5,
        signCardCount: 3,
        totalExerciseCount: 12),
    '13900009000': _seedUser(
        id: 'u_1002',
        phoneMasked: '139****9000',
        nickname: '奶茶不加糖',
        avatarUrl: 'https://mock.cdn/avatar/seed2.png',
        streakDays: 12,
        signCardCount: 1,
        totalExerciseCount: 30,
        createdAt: '2025-03-15T10:00:00+08:00'),
  };

  String? _issuedPhone;
  String? _issuedCode;
  DateTime? _lastSmsAt;

  /// accessToken -> (过期时刻, 归属用户id)
  final Map<String, ({DateTime expiresAt, String userId})> _accessTokens = {};
  /// refreshToken -> 归属用户id（一次性轮换：用后即换新）
  final Map<String, String> _refreshTokens = {};

  static Map<String, dynamic> _seedUser({
    required String id,
    required String phoneMasked,
    required String nickname,
    required int streakDays,
    required int signCardCount,
    required int totalExerciseCount,
    String? avatarUrl,
    String? createdAt,
  }) =>
      {
        'id': id,
        'phone': phoneMasked,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt ?? '2026-08-01T09:00:00+08:00',
        'totalExerciseCount': totalExerciseCount,
        'streakDays': streakDays,
        'signCardCount': signCardCount,
      };

  static String _maskPhone(String phone) =>
      '${phone.substring(0, 3)}****${phone.substring(7)}';

  Future<Map<String, dynamic>?> _respond(Map<String, dynamic>? envelope) async {
    await Future<void>.delayed(delay);
    return envelope;
  }

  @override
  Future<Map<String, dynamic>?> send(String method, String path,
      {Object? body, Map<String, String>? query, Map<String, String>? headers}) async {
    await Future<void>.delayed(delay);
    switch ('$method $path') {
      case 'GET /api/v1/ping':
        return {
          'code': 0,
          'data': {
            'service': 'chongdong-mock',
            'time': formatIsoWithOffset(DateTime.now()),
          },
        };
      case 'POST /api/v1/auth/sms-code':
        return _smsCode(body);
      case 'POST /api/v1/auth/login':
        return _login(body);
      case 'POST /api/v1/auth/refresh':
        return _refresh(body);
      default:
        if (path == '/api/v1/users/me') {
          return method == 'PATCH'
              ? _patchMe(body, headers)
              : _me(headers);
        }
        throw ApiException(kCodeServerErrorBase, 'Mock 未实现该接口: $path');
    }
  }

  @override
  Future<Map<String, dynamic>?> sendMultipart(String path,
      {required List<int> bytes,
      required String filename,
      String fileField = 'file',
      Map<String, String> fields = const {},
      Map<String, String>? headers}) async {
    if (path != '/api/v1/upload') {
      throw ApiException(kCodeServerErrorBase, 'Mock 未实现该上传: $path');
    }
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(ext)) return _respond({'code': kCodeUploadType});
    final type = fields['businessType'] ?? 'avatar';
    final limit = type == 'walkPhoto' ? 1024 * 1024 : 2 * 1024 * 1024;
    if (bytes.length > limit) return _respond({'code': kCodeUploadSize});
    return _respond({
      'code': 0,
      'data': {
        'url': 'https://mock.cdn/$type/${DateTime.now().millisecondsSinceEpoch}.$ext',
        'fileSize': bytes.length,
      },
    });
  }

  // ---- 认证相关 ----

  Map<String, dynamic> _smsCode(Object? body) {
    final phone = (body as Map?)?['phone'] as String?;
    if (phone == null || !RegExp(r'^1\d{10}$').hasMatch(phone)) {
      return {'code': kCodeParamInvalid, 'message': '手机号格式不正确'};
    }
    final now = DateTime.now();
    final last = _lastSmsAt;
    if (_issuedPhone == phone &&
        last != null &&
        now.difference(last) < const Duration(seconds: 60)) {
      return {'code': kCodeSmsTooFrequent, 'message': '发送过于频繁'};
    }
    _issuedPhone = phone;
    _issuedCode = fixedSmsCode; // 固定码便于真机手测；自动化测试同样依赖该值
    _lastSmsAt = now;
    return {'code': 0};
  }

  Map<String, dynamic> _login(Object? body) {
    final map = body as Map?;
    final phone = map?['phone'] as String?;
    final code = map?['smsCode'] as String?;
    final codeOk = acceptAny6DigitCode
        ? RegExp(r'^\d{6}$').hasMatch(code ?? '')
        : code == _issuedCode;
    if (_issuedPhone != phone || !codeOk) {
      return {'code': kCodeSmsWrong, 'message': '验证码错误或已过期'};
    }
    var isNewUser = false;
    if (!_usersByPhone.containsKey(phone)) {
      isNewUser = true;
      _usersByPhone[phone!] = _seedUser(
          id: 'u_${nowMs()}',
          phoneMasked: _maskPhone(phone),
          nickname: '铲屎官',
          streakDays: 0,
          signCardCount: 3,
          totalExerciseCount: 0,
          createdAt: formatIsoWithOffset(now()));
    }
    final user = _usersByPhone[phone]!;
    final access = 'mock-access-${nowMs()}-$phone';
    final refresh = 'mock-refresh-${nowMs()}-$phone';
    _accessTokens[access] = (expiresAt: now().add(accessTtl), userId: user['id'] as String);
    _refreshTokens[refresh] = user['id'] as String;
    return {
      'code': 0,
      'data': {
        'accessToken': access,
        'refreshToken': refresh,
        'expiresIn': accessTtl.inSeconds,
        'isNewUser': isNewUser,
        'user': Map<String, dynamic>.of(user),
      },
    };
  }

  Map<String, dynamic> _refresh(Object? body) {
    final token = (body as Map?)?['refreshToken'] as String?;
    final userId = token == null ? null : _refreshTokens[token];
    if (userId == null) {
      return {'code': kCodeRefreshInvalid, 'message': 'refreshToken 无效或过期'};
    }
    // 轮换：旧的作废，签发新的一对
    _refreshTokens.remove(token);
    final access = 'mock-access-${nowMs()}-rotated';
    final refresh = 'mock-refresh-${nowMs()}-rotated';
    _accessTokens[access] = (expiresAt: now().add(accessTtl), userId: userId);
    _refreshTokens[refresh] = userId;
    return {
      'code': 0,
      'data': {
        'accessToken': access,
        'refreshToken': refresh,
        'expiresIn': accessTtl.inSeconds,
      },
    };
  }

  String? _userIdFromAuth(Map<String, String>? headers) {
    final auth = headers?['Authorization'];
    if (auth == null || !auth.startsWith('Bearer mock-access-')) return null;
    final entry = _accessTokens[auth.substring('Bearer '.length)];
    if (entry == null) return null;
    if (now().isAfter(entry.expiresAt)) return null; // 已过期 → 视同无凭据
    return entry.userId;
  }

  Map<String, dynamic> _me(Map<String, String>? headers) {
    final userId = _userIdFromAuth(headers);
    if (userId == null) return {'code': kCodeAccessExpired, 'message': '登录已过期'};
    final user =
        _usersByPhone.values.firstWhere((u) => u['id'] == userId);
    return {'code': 0, 'data': Map<String, dynamic>.of(user)};
  }

  Map<String, dynamic> _patchMe(Object? body, Map<String, String>? headers) {
    final userId = _userIdFromAuth(headers);
    if (userId == null) return {'code': kCodeAccessExpired, 'message': '登录已过期'};
    final user = _usersByPhone.values.firstWhere((u) => u['id'] == userId);
    final map = (body as Map?) ?? const {};
    final nickname = map['nickname'] as String?;
    if (nickname != null) {
      final trimmed = nickname.trim();
      if (trimmed.isEmpty || trimmed.length > 12) {
        return {'code': kCodeNicknameInvalid, 'message': '昵称需为1~12个字符'};
      }
      user['nickname'] = trimmed;
    }
    if (map.containsKey('avatarUrl')) {
      user['avatarUrl'] = map['avatarUrl'] as String?;
    }
    return {'code': 0, 'data': Map<String, dynamic>.of(user)};
  }

  // ---- 测试辅助 ----

  /// 让全部 access token 立即过期（模拟时间流逝；仅供测试调用）
  void expireAllAccessTokens() {
    final past = now().subtract(const Duration(hours: 1));
    _accessTokens.updateAll((_, e) => (expiresAt: past, userId: e.userId));
  }

  static DateTime now() => DateTime.now();
  static int nowMs() => DateTime.now().millisecondsSinceEpoch;
}
