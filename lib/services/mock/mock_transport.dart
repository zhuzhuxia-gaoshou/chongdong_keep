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

  /// userId -> 宠物行（契约 §4.4；行内存 userId 便于跨用户归属校验）
  final Map<String, List<Map<String, dynamic>>> _petsByUser = {
    'u_1001': [
      _seedPet(
          id: 'p_1001',
          userId: 'u_1001',
          name: '可乐',
          species: 'dog',
          breed: '金毛',
          gender: 'male',
          ageYears: 3,
          birthDate: '2023-05-01',
          weight: 28.5),
      _seedPet(
          id: 'p_1002',
          userId: 'u_1001',
          name: '咪咪',
          species: 'cat',
          breed: '布偶猫',
          gender: 'female',
          ageYears: 2,
          birthDate: '2024-06-15',
          weight: 4.2,
          allergies: const ['鸡肉']),
    ],
    'u_1002': [
      _seedPet(
          id: 'p_1003',
          userId: 'u_1002',
          name: '豆豆',
          species: 'dog',
          breed: '柯基',
          gender: 'female',
          ageYears: 5,
          birthDate: '2021-03-08',
          weight: 11.0,
          isNeutered: true),
    ],
  };

  /// userId -> 运动记录行（契约 §4.6，行为 wire 格式；
  /// clientRecordId 为幂等索引，重复提交返回既有行+duplicated 标记）
  final Map<String, List<Map<String, dynamic>>> _recordsByUser = {};

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

  static Map<String, dynamic> _seedPet({
    required String id,
    required String userId,
    required String name,
    required String species,
    required String breed,
    required String gender,
    required int ageYears,
    required String birthDate,
    required double weight,
    List<String> allergies = const [],
    bool isNeutered = false,
    bool isVaccinated = false,
  }) =>
      {
        'id': id,
        'userId': userId,
        'name': name,
        'species': species,
        'breed': breed,
        'gender': gender,
        'ageYears': ageYears,
        'birthDate': birthDate,
        'weight': weight,
        'avatarUrl': null,
        'allergies': allergies,
        'chronicConditions': <String>[],
        'isNeutered': isNeutered,
        'isVaccinated': isVaccinated,
        'emergencyContact': null,
        'recommendedExerciseMinutes': _recMinutes(species, breed, ageYears),
        'createdAt': '2026-08-01T09:00:00+08:00',
      };

  /// 推荐运动分钟数——与契约 §3 公式严格一致（两侧不可各自私改）。
  static int _recMinutes(String species, String breed, int ageYears) {
    if (species == 'cat') {
      return 15 + (ageYears < 2 ? 15 : (ageYears > 7 ? -5 : 0));
    }
    if (breed.contains('柯基') || breed.contains('法斗') || breed.contains('吉娃娃')) {
      return ageYears < 1 ? 20 : (ageYears > 8 ? 15 : 30);
    }
    if (breed.contains('金毛') ||
        breed.contains('拉布拉多') ||
        breed.contains('边牧')) {
      return ageYears < 1 ? 40 : (ageYears > 8 ? 30 : 60);
    }
    return ageYears < 1 ? 25 : (ageYears > 8 ? 20 : 40);
  }

  Future<Map<String, dynamic>?> _respond(Map<String, dynamic>? envelope) async {
    await Future<void>.delayed(delay);
    return envelope;
  }

  @override
  Future<Map<String, dynamic>?> send(String method, String path,
      {Object? body,
      Map<String, String>? query,
      Map<String, String>? headers}) async {
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
          return method == 'PATCH' ? _patchMe(body, headers) : _me(headers);
        }
        if (path == '/api/v1/pets' || path.startsWith('/api/v1/pets/')) {
          final petId = path.length > '/api/v1/pets'.length
              ? Uri.decodeComponent(path.substring('/api/v1/pets'.length + 1))
              : null;
          switch (method) {
            case 'GET':
              return petId == null
                  ? _listPets(headers)
                  : _getPet(petId, headers);
            case 'POST':
              return _createPet(body, headers);
            case 'PATCH':
              return petId == null
                  ? {'code': kCodePetNotFound, 'message': '缺少宠物 id'}
                  : _patchPet(petId, body, headers);
            case 'DELETE':
              return petId == null
                  ? {'code': kCodePetNotFound, 'message': '缺少宠物 id'}
                  : _deletePet(petId, headers);
          }
        }
        if (path == '/api/v1/exercise-records') {
          return method == 'POST'
              ? _createRecord(body, headers)
              : _listRecords(query, headers);
        }
        if (path == '/api/v1/checkins/calendar' && method == 'GET') {
          return _calendar(query, headers);
        }
        if (path == '/api/v1/checkins/today' && method == 'GET') {
          return _todayStatus(headers);
        }
        if (path == '/api/v1/checkins/makeup' && method == 'POST') {
          return _makeup(body, headers);
        }
        if (path == '/api/v1/ranking' && method == 'GET') {
          return _ranking(query, headers);
        }
        if (path == '/api/v1/badges' && method == 'GET') {
          return _badges(headers);
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
    final ext =
        filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(ext)) return _respond({'code': kCodeUploadType});
    final type = fields['businessType'] ?? 'avatar';
    final limit = type == 'walkPhoto' ? 1024 * 1024 : 2 * 1024 * 1024;
    if (bytes.length > limit) return _respond({'code': kCodeUploadSize});
    return _respond({
      'code': 0,
      'data': {
        'url':
            'https://mock.cdn/$type/${DateTime.now().millisecondsSinceEpoch}.$ext',
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
    _accessTokens[access] =
        (expiresAt: now().add(accessTtl), userId: user['id'] as String);
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
    final user = _usersByPhone.values.firstWhere((u) => u['id'] == userId);
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

  // ---- 宠物（契约 ⑧–⑫）----

  Map<String, dynamic> _requirePets(Map<String, String>? headers,
      Map<String, dynamic> Function(String userId) handle) {
    final userId = _userIdFromAuth(headers);
    if (userId == null) {
      return {'code': kCodeAccessExpired, 'message': '登录已过期'};
    }
    return handle(userId);
  }

  Map<String, dynamic>? _validatePetBody(Map? map, {required bool partial}) {
    if (map == null) {
      return {'code': kCodeParamInvalid, 'message': '请求体不能为空'};
    }
    if (!partial || map.containsKey('name')) {
      final name = map['name'] as String?;
      if (name == null || name.trim().isEmpty) {
        return {'code': kCodeParamInvalid, 'message': '宠物名称不能为空'};
      }
    }
    if (!partial || map.containsKey('species')) {
      if (!const {'dog', 'cat'}.contains(map['species'])) {
        return {'code': kCodeParamInvalid, 'message': '物种不合法'};
      }
    }
    if (!partial || map.containsKey('gender')) {
      if (!const {'male', 'female'}.contains(map['gender'])) {
        return {'code': kCodeParamInvalid, 'message': '性别不合法'};
      }
    }
    if (!partial || map.containsKey('weight')) {
      final w = (map['weight'] as num?)?.toDouble();
      if (w == null || w <= 0) {
        return {'code': kCodeParamInvalid, 'message': '体重需大于 0'};
      }
    }
    if (!partial || map.containsKey('birthDate')) {
      if (DateTime.tryParse('${map['birthDate'] ?? ''}') == null) {
        return {'code': kCodeParamInvalid, 'message': '出生日期格式不正确'};
      }
    }
    if (!partial) {
      final breed = map['breed'] as String?;
      if (breed == null || breed.trim().isEmpty) {
        return {'code': kCodeParamInvalid, 'message': '品种不能为空'};
      }
    }
    return null;
  }

  Map<String, dynamic>? _findPetAny(String petId) {
    for (final rows in _petsByUser.values) {
      for (final row in rows) {
        if (row['id'] == petId) return row;
      }
    }
    return null;
  }

  /// 契约 §4.4：不存在 → 40401；存在但非本人 → 40301。
  /// 返回 null 表示归属校验通过。
  Map<String, dynamic>? _ownershipError(
      Map<String, dynamic>? row, String userId) {
    if (row == null) {
      return {'code': kCodePetNotFound, 'message': '宠物不存在或已删除'};
    }
    if (row['userId'] != userId) {
      return {'code': kCodeNotOwner, 'message': '无权操作该宠物'};
    }
    return null;
  }

  Map<String, dynamic> _listPets(Map<String, String>? headers) =>
      _requirePets(headers, (userId) {
        final rows = _petsByUser[userId] ?? const [];
        return {
          'code': 0,
          'data': {
            'list': rows.map(Map<String, dynamic>.of).toList(),
            'total': rows.length,
            'page': 1,
            'pageSize': 100,
          },
        };
      });

  Map<String, dynamic> _getPet(String petId, Map<String, String>? headers) =>
      _requirePets(headers, (userId) {
        final row = _findPetAny(petId);
        final denied = _ownershipError(row, userId);
        if (denied != null) return denied;
        return {'code': 0, 'data': Map<String, dynamic>.of(row!)};
      });

  Map<String, dynamic> _createPet(Object? body, Map<String, String>? headers) =>
      _requirePets(headers, (userId) {
        final map = (body as Map?)?.cast<String, dynamic>();
        final invalid = _validatePetBody(map, partial: false);
        if (invalid != null) return invalid;
        final mine = _petsByUser.putIfAbsent(userId, () => []);
        if (mine.length >= 20) {
          return {'code': kCodePetLimit, 'message': '宠物数量已达上限（20）'};
        }
        final row = _seedPet(
          id: 'p_${nowMs()}',
          userId: userId,
          name: map!['name'].toString().trim(),
          species: map['species'] as String,
          breed: (map['breed'] as String?)?.toString().trim() ?? '',
          gender: map['gender'] as String,
          ageYears: _asInt(map['ageYears']) ?? 0,
          birthDate: map['birthDate'] as String,
          weight: (map['weight'] as num).toDouble(),
          allergies: _strList(map['allergies']),
          isNeutered: map['isNeutered'] as bool? ?? false,
          isVaccinated: map['isVaccinated'] as bool? ?? false,
        );
        mine.add(row);
        return {'code': 0, 'data': Map<String, dynamic>.of(row)};
      });

  Map<String, dynamic> _patchPet(
          String petId, Object? body, Map<String, String>? headers) =>
      _requirePets(headers, (userId) {
        final map = (body as Map?)?.cast<String, dynamic>();
        final invalid = _validatePetBody(map, partial: true);
        if (invalid != null) return invalid;
        final maybeRow = _findPetAny(petId);
        final denied = _ownershipError(maybeRow, userId);
        if (denied != null) return denied;
        final row = maybeRow!;
        if (map!['name'] != null) row['name'] = (map['name'] as String).trim();
        if (map['species'] != null) row['species'] = map['species'];
        if (map['breed'] != null) {
          row['breed'] = (map['breed'] as String).trim();
        }
        if (map['gender'] != null) row['gender'] = map['gender'];
        if (map['weight'] != null) {
          row['weight'] = (map['weight'] as num).toDouble();
        }
        if (map['birthDate'] != null) row['birthDate'] = map['birthDate'];
        if (map.containsKey('ageYears')) {
          row['ageYears'] = _asInt(map['ageYears']) ?? row['ageYears'];
        }
        if (map.containsKey('avatarUrl')) {
          row['avatarUrl'] = map['avatarUrl'];
        }
        if (map.containsKey('allergies')) {
          row['allergies'] = _strList(map['allergies']);
        }
        if (map.containsKey('chronicConditions')) {
          row['chronicConditions'] = _strList(map['chronicConditions']);
        }
        if (map.containsKey('isNeutered')) {
          row['isNeutered'] = map['isNeutered'] as bool? ?? false;
        }
        if (map.containsKey('isVaccinated')) {
          row['isVaccinated'] = map['isVaccinated'] as bool? ?? false;
        }
        if (map.containsKey('emergencyContact')) {
          row['emergencyContact'] = map['emergencyContact'];
        }
        row['recommendedExerciseMinutes'] = _recMinutes(
            row['species'] as String,
            row['breed'] as String,
            row['ageYears'] as int);
        return {'code': 0, 'data': Map<String, dynamic>.of(row)};
      });

  Map<String, dynamic> _deletePet(String petId, Map<String, String>? headers) =>
      _requirePets(headers, (userId) {
        final row = _findPetAny(petId);
        final denied = _ownershipError(row, userId);
        if (denied != null) return denied;
        for (final rows in _petsByUser.values) {
          if (rows.remove(row)) break;
        }
        return {'code': 0, 'data': <String, dynamic>{}}; // 软删：列表不再出现
      });

  // ---- 运动记录（契约 ⑭⑮，幂等）----

  Map<String, dynamic> _requireRecords(Map<String, String>? headers,
      Map<String, dynamic> Function(String userId) handle) {
    final userId = _userIdFromAuth(headers);
    if (userId == null) {
      return {'code': kCodeAccessExpired, 'message': '登录已过期'};
    }
    return handle(userId);
  }

  Map<String, dynamic> _createRecord(
          Object? body, Map<String, String>? headers) =>
      _requireRecords(headers, (userId) {
        final map = (body as Map?)?.cast<String, dynamic>();
        if (map == null) {
          return {'code': kCodeParamInvalid, 'message': '请求体不能为空'};
        }
        final clientRecordId = map['clientRecordId'] as String?;
        if (clientRecordId == null || clientRecordId.trim().isEmpty) {
          return {'code': kCodeParamInvalid, 'message': '缺少幂等键 clientRecordId'};
        }
        final mine = _recordsByUser.putIfAbsent(userId, () => []);
        // 幂等：同 clientRecordId 已入库 → 直接回既有行（附 duplicated 标记）
        for (final row in mine) {
          if (row['clientRecordId'] == clientRecordId) {
            return {
              'code': 0,
              'data': {...Map<String, dynamic>.of(row), 'duplicated': true},
            };
          }
        }
        // 归属校验
        final petId = map['petId'] as String?;
        final denied =
            _ownershipError(petId == null ? null : _findPetAny(petId), userId);
        if (denied != null) return denied;
        // 起止校验
        final start = DateTime.tryParse('${map['startTime'] ?? ''}');
        final end = DateTime.tryParse('${map['endTime'] ?? ''}');
        if (start == null || end == null || !end.isAfter(start)) {
          return {'code': kCodeParamInvalid, 'message': '结束时间须晚于开始时间'};
        }
        final type = (map['type'] as String?) ?? 'walkDog';
        final isManual = map['isManual'] as bool? ?? false;
        final rawRoute = (map['route'] as List?) ?? const [];
        if (rawRoute.isEmpty && type != 'catPlay' && !isManual) {
          return {
            'code': kCodeParamInvalid,
            'message': '遛狗记录必须携带轨迹点'
          };
        }
        final distance = (map['distance'] as num?)?.toDouble() ?? 0.0;
        final duration = _asInt(map['duration']) ??
            end.difference(start).inSeconds;
        final row = <String, dynamic>{
          'id': 'r_${nowMs()}',
          'clientRecordId': clientRecordId,
          'petId': petId,
          'userId': userId,
          'type': type,
          'startTime': map['startTime'],
          'endTime': map['endTime'],
          'duration': duration,
          'distance': distance,
          'steps': _asInt(map['steps']) ?? (distance * 1000 / 0.5).round(),
          'route': rawRoute,
          'locationName': map['locationName'],
          'startPhotoUrl': map['startPhotoUrl'],
          'isCompleted': map['isCompleted'] as bool? ?? true,
          'isManual': isManual,
          'createdAt': formatIsoWithOffset(now()),
        };
        mine.add(row);
        return {'code': 0, 'data': Map<String, dynamic>.of(row)};
      });

  Map<String, dynamic> _listRecords(
          Map<String, String>? query, Map<String, String>? headers) =>
      _requireRecords(headers, (userId) {
        final mine = _recordsByUser[userId] ?? const [];
        final petId = query?['petId'];
        final type = query?['type'];
        final startDate = _dateOnlyOf(query?['startDate']);
        final endDate = _dateOnlyOf(query?['endDate']);
        final page = int.tryParse(query?['page'] ?? '') ?? 1;
        final pageSize = (int.tryParse(query?['pageSize'] ?? '') ?? 20)
            .clamp(1, 100);

        var filtered = mine.where((row) {
          if (petId != null && row['petId'] != petId) return false;
          if (type != null && row['type'] != type) return false;
          final d = _dateOnlyOf(_isoDate(row['startTime']));
          if (d == null) return true;
          if (startDate != null && d.isBefore(startDate)) return false;
          if (endDate != null && d.isAfter(endDate)) return false;
          return true;
        }).toList()
          ..sort((a, b) =>
              _compareIso(b['startTime'], a['startTime'])); // startTime 倒序

        final total = filtered.length;
        final lo = ((page - 1) * pageSize).clamp(0, total);
        final hi = (lo + pageSize).clamp(0, total);
        final pageRows = filtered.sublist(lo, hi)
            .map(_thinRouteForList)
            .toList();
        return {
          'code': 0,
          'data': {
            'list': pageRows,
            'total': total,
            'page': page,
            'pageSize': pageSize,
          },
        };
      });

  /// 列表接口抽稀轨迹（契约 ⑮：仅回部分点控流量，全量走 ⑯ 详情）。
  Map<String, dynamic> _thinRouteForList(Map<String, dynamic> row) {
    final route = row['route'] as List? ?? const [];
    if (route.length <= 50) return Map<String, dynamic>.of(row);
    final out = <Object?>[];
    for (var i = 0; i < route.length; i += 50) {
      out.add(route[i]);
    }
    return {...Map<String, dynamic>.of(row), 'route': out};
  }

  static String? _isoDate(Object? v) => v is String ? v : null;

  static int _compareIso(Object? a, Object? b) {
    final da = DateTime.tryParse('${a ?? ''}');
    final db = DateTime.tryParse('${b ?? ''}');
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  static DateTime? _dateOnlyOf(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return null;
    // ⚠️ DateTime.parse 对带时区偏移的字符串（如 +08:00）返回的是 UTC 时刻，
    // 直接取 .day 会让东八区凌晨~上午的记录落到"前一天"（打卡日按东八区切分，
    // 契约 §一）。先转回本地时区再取日期分量。
    final local = d.isUtc ? d.toLocal() : d;
    return DateTime(local.year, local.month, local.day);
  }

  // ---- 打卡日历（契约 ⑰；判定同 §4.7：完成且≥300秒，不限类型）----

  /// 补签日（Mock 内存态）：userId -> 已补签日期集合
  final Map<String, Set<String>> _makeupDays = {};

  /// 用户单条记录是否达标（isCompleted && duration≥300 秒）
  bool _rowQualifies(Map<String, dynamic> row) {
    if ((row['isCompleted'] as bool? ?? false) != true) return false;
    return (_asInt(row['duration']) ?? 0) >= 300;
  }

  /// 某日期（yyyy-MM-dd）是否已打卡：自然达标 或 已补签
  bool _checkedOn(String userId, String date) {
    if ((_makeupDays[userId] ?? const {}).contains(date)) return true;
    for (final row in _recordsByUser[userId] ?? const []) {
      if (!_rowQualifies(row)) continue;
      final d = _dateOnlyOf(_isoDate(row['startTime']));
      if (d != null && _dateKey(d) == date) return true;
    }
    return false;
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// 连续打卡天数（从今天或昨天起往回数）
  int _mockStreak(String userId) {
    final dates = <String>{};
    for (final row in _recordsByUser[userId] ?? const []) {
      if (!_rowQualifies(row)) continue;
      final d = _dateOnlyOf(_isoDate(row['startTime']));
      if (d != null) dates.add(_dateKey(d));
    }
    if (dates.isEmpty) return 0;
    var cursor = DateTime(now().year, now().month, now().day);
    var key = _dateKey(cursor);
    if (!dates.contains(key)) {
      cursor = cursor.subtract(const Duration(days: 1));
      key = _dateKey(cursor);
    }
    var streak = 0;
    while (dates.contains(key)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
      key = _dateKey(cursor);
    }
    return streak;
  }

  // ⑱ GET /checkins/today
  Map<String, dynamic> _todayStatus(Map<String, String>? headers) {
    final userId = _userIdFromAuth(headers);
    if (userId == null) {
      return {'code': kCodeAccessExpired, 'message': '登录已过期'};
    }
    final todayKey = _dateKey(now());
    int minutes = 0;
    var checked = false;
    for (final row in _recordsByUser[userId] ?? const []) {
      final d = _dateOnlyOf(_isoDate(row['startTime']));
      if (d == null || _dateKey(d) != todayKey) continue;
      minutes += ((_asInt(row['duration']) ?? 0) / 60).round();
      if (_rowQualifies(row)) checked = true;
    }
    if ((_makeupDays[userId] ?? const {}).contains(todayKey)) {
      checked = true;
    }
    return {
      'code': 0,
      'data': {'isChecked': checked, 'todayMinutes': minutes},
    };
  }

  // ⑲ POST /checkins/makeup
  Map<String, dynamic> _makeup(
      Object? body, Map<String, String>? headers) {
    final userId = _userIdFromAuth(headers);
    if (userId == null) {
      return {'code': kCodeAccessExpired, 'message': '登录已过期'};
    }
    final map = (body as Map?) ?? const {};
    final date = (map['date'] as String?) ?? '';
    final today = _dateKey(now());
    if (date.isEmpty || date.compareTo(today) >= 0) {
      return {'code': kCodeParamInvalid, 'message': '只能补签过去的日期'};
    }
    if (_checkedOn(userId, date)) {
      return {'code': kCodeNoNeedMakeup, 'message': '该日无需补签'};
    }
    final user = _usersByPhone.values
        .firstWhere((u) => u['id'] == userId, orElse: () => {});
    final cards = _asInt(user['signCardCount']) ?? 0;
    if (cards <= 0) {
      return {'code': kCodeMakeupCardInsufficient, 'message': '补签卡不足'};
    }
    user['signCardCount'] = cards - 1;
    (_makeupDays[userId] ??= {}).add(date);
    return {
      'code': 0,
      'data': {
        'date': date,
        'isChecked': true,
        'signCardCount': cards - 1,
      },
    };
  }

  // ㉒ GET /ranking
  Map<String, dynamic> _ranking(
      Map<String, String>? query, Map<String, String>? headers) {
    final meId = _userIdFromAuth(headers);
    if (meId == null) {
      return {'code': kCodeAccessExpired, 'message': '登录已过期'};
    }
    final type = query?['type'] ?? 'weekly';
    final since = type == 'monthly'
        ? DateTime(now().year, now().month, 1) // 自然月
        : now().subtract(const Duration(days: 6)); // 滚动近 7 天
    final agg = <String, int>{};
    _recordsByUser.forEach((uid, rows) {
      for (final row in rows) {
        final iso = row['startTime'] as String?;
        if (iso == null) continue;
        final start = DateTime.tryParse(iso);
        if (start == null || start.isBefore(since)) continue;
        agg[uid] = (agg[uid] ?? 0) + ((_asInt(row['duration']) ?? 0) / 60).round();
      }
    });
    final entries = agg.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final list = <Map<String, dynamic>>[];
    String? nicknameOf(String uid) {
      for (final u in _usersByPhone.values) {
        if (u['id'] == uid) return u['nickname'] as String?;
      }
      return '匿名铲屎官';
    }

    for (var i = 0; i < entries.length && list.length < 50; i++) {
      final uid = entries[i].key;
      list.add({
        'rank': i + 1,
        'userId': uid,
        'nickname': nicknameOf(uid),
        'avatarUrl': null,
        'value': entries[i].value,
        'isMe': uid == meId,
      });
    }
    final myMinutes = agg[meId] ?? 0;
    final myRank =
        myMinutes <= 0 ? 0 : entries.indexWhere((e) => e.key == meId) + 1;
    return {
      'code': 0,
      'data': {
        'type': type,
        'metric': 'minutes',
        'updatedAt': _isoDate(now()),
        'list': list,
        'me': {
          'rank': myRank,
          'userId': meId,
          'nickname': nicknameOf(meId),
          'avatarUrl': null,
          'value': myMinutes,
          'isMe': true,
        },
      },
    };
  }

  // ㉓ GET /badges（规则与真实服务端对齐的简化版）
  Map<String, dynamic> _badges(Map<String, String>? headers) {
    final userId = _userIdFromAuth(headers);
    if (userId == null) {
      return {'code': kCodeAccessExpired, 'message': '登录已过期'};
    }
    final rows = _recordsByUser[userId] ?? const [];
    final completed = rows.where(_rowQualifies).toList();
    final totalKm =
        completed.fold<double>(0, (s, r) => s + ((_asDouble(r['distance']) ?? 0)));
    final streak = _mockStreak(userId);
    final rules = <(String, String, String, String, bool)>{
      ('first_move', '初次出发', '🐾', '完成第一次运动', completed.isNotEmpty),
      ('streak_7', '七日坚持', '🔥', '连续打卡 7 天', streak >= 7),
      ('streak_30', '月度之星', '🏆', '连续打卡 30 天', streak >= 30),
      ('km_50', '五十公里', '🚀', '累计运动 50 公里', totalKm >= 50),
      ('count_25', '运动达人', '⚡', '累计完成 25 次运动', completed.length >= 25),
    };
    var unlocked = 0;
    final list = rules.map((r) {
      final (id, name, emoji, description, ok) = r;
      if (ok) unlocked++;
      return {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'isUnlocked': ok,
        'unlockedAt': ok ? _isoDate(now()) : null,
      };
    }).toList();
    return {
      'code': 0,
      'data': {'list': list, 'unlockedCount': unlocked},
    };
  }

  static double? _asDouble(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  // ---- 打卡日历（契约 ⑰；判定同 §4.7：完成且≥300秒，不限类型）----

  Map<String, dynamic> _calendar(
          Map<String, String>? query, Map<String, String>? headers) =>
      _requireRecords(headers, (userId) {
        final year = int.tryParse(query?['year'] ?? '') ?? now().year;
        final month = int.tryParse(query?['month'] ?? '') ?? now().month;
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final checked = <int>{};
        for (final row in _recordsByUser[userId] ?? const []) {
          if (row['isCompleted'] != true) continue;
          if ((_asInt(row['duration']) ?? 0) < 300) continue;
          final d = _dateOnlyOf('${row['startTime'] ?? ''}');
          if (d != null && d.year == year && d.month == month) {
            checked.add(d.day);
          }
        }
        final days = List.generate(daysInMonth, (i) {
          final dom = i + 1;
          return {
            'date': '${year.toString().padLeft(4, '0')}-'
                '${month.toString().padLeft(2, '0')}-'
                '${dom.toString().padLeft(2, '0')}',
            'isChecked': checked.contains(dom),
          };
        });
        return {
          'code': 0,
          'data': {
            'days': days,
            'monthCheckedCount': checked.length,
            'streakDays': _streak(userId),
          },
        };
      });

  /// 截至最近的连续打卡天数（从昨天或今天往前数连续命中）。
  int _streak(String userId) {
    final rows = _recordsByUser[userId] ?? const [];
    final dates = <DateTime>{};
    for (final row in rows) {
      if (row['isCompleted'] != true) continue;
      if ((_asInt(row['duration']) ?? 0) < 300) continue;
      final d = _dateOnlyOf('${row['startTime'] ?? ''}');
      if (d != null) dates.add(d);
    }
    if (dates.isEmpty) return 0;
    DateTime prev(DateTime d) => DateTime(d.year, d.month, d.day - 1);
    var cursor = DateTime(now().year, now().month, now().day);
    // 今天尚未打卡则从昨天起算
    if (!dates.contains(cursor)) {
      cursor = prev(cursor);
    }
    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = prev(cursor);
    }
    return streak;
  }

  // ---- 测试辅助 ----

  /// 让全部 access token 立即过期（模拟时间流逝；仅供测试调用）
  void expireAllAccessTokens() {
    final past = now().subtract(const Duration(hours: 1));
    _accessTokens.updateAll((_, e) => (expiresAt: past, userId: e.userId));
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  static List<String> _strList(Object? v) => v is List
      ? v.map((e) => '$e').where((s) => s.isNotEmpty).toList()
      : <String>[];

  static DateTime now() => DateTime.now();
  static int nowMs() => DateTime.now().millisecondsSinceEpoch;
}
