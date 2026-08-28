/// 业务错误码常量（与《API 接口契约》4.6 错误码分段一致）
const int kCodeParamInvalid = 40001; // 参数/校验类
const int kCodeNicknameInvalid = 40002;
const int kCodePetLimit = 40003;
const int kCodeMakeupInvalid = 40004;
const int kCodeUploadType = 40006; // 图片类型不支持
const int kCodeUploadSize = 40007; // 图片大小超限
const int kCodeUnauthorizedGeneric = 40100; // 网关未授权（token 无效/损坏；联调实测）
const int kCodeSmsWrong = 40102; // 验证码错误或过期
const int kCodeSmsTooFrequent = 40103; // 发送过于频繁
const int kCodeAccessExpired = 40101; // accessToken 过期
const int kCodeRefreshInvalid = 40104; // refreshToken 无效或过期
const int kCodeForbiddenBase = 40300; // 权限类分段起点
const int kCodeNotOwner = 40301; // 非本人资源（契约 §4.4/§4.6）
const int kCodeNotFoundBase = 40400; // 不存在分段起点
const int kCodePetNotFound = 40401; // 宠物不存在或已删除
const int kCodeTooFrequentBase = 42900; // 限流分段起点
const int kCodeServerErrorBase = 50000; // 服务端异常分段起点

/// 宽松整数解析：服务端可能把数值字段下发成字符串（联调实测
/// expiresIn="604800"），解析失败一律回退默认值，绝不让类型崩到界面。
int asIntOrDefault(Object? v, {required int or}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? or;
}

/// 统一业务异常。
///
/// [code] 来自响应信封 body.code；负数表示传输层故障：
/// -1 超时/断网、-2 响应不是合法 JSON。
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.httpStatus});

  final int code;
  final String message;
  final int? httpStatus;

  bool get isAccessExpired => code == kCodeAccessExpired;
  bool get isRefreshInvalid => code == kCodeRefreshInvalid;

  /// 传输层故障（非服务端业务码）
  bool get isNetwork => code < 0;

  /// 用户可见文案：永不向用户展示裸错误码
  String get friendlyMessage {
    if (isNetwork) return '网络不给力，请检查网络后重试';
    switch (code) {
      case kCodeAccessExpired || kCodeRefreshInvalid:
        return '登录已过期，请重新登录';
      case kCodeSmsWrong:
        return '验证码错误或已过期';
      case kCodeSmsTooFrequent:
        return '发送太频繁了，请稍等再试';
      case kCodeParamInvalid:
        return '请求参数有误';
      case kCodeNicknameInvalid:
        return '昵称需为1~12个字符';
      case kCodeMakeupInvalid:
        return '该日期无需补签';
      case kCodeUploadType:
        return '仅支持 JPG/PNG/WebP 图片';
      case kCodeUploadSize:
        return '图片大小超出限制';
    }
    if (code >= kCodeForbiddenBase && code < kCodeForbiddenBase + 100) {
      return '没有权限执行此操作';
    }
    if (code >= kCodeNotFoundBase && code < kCodeNotFoundBase + 100) {
      return '内容不存在或已删除';
    }
    if (code >= kCodeTooFrequentBase && code < kCodeTooFrequentBase + 100) {
      return '操作太频繁，请稍后再试';
    }
    if (code >= kCodeServerErrorBase) return '服务器开小差了，请稍后重试';
    return '请求失败，请稍后重试';
  }

  @override
  String toString() => 'ApiException($code, $message)';
}

/// 解包统一响应信封 `{code, message, data}`。
///
/// - `code == 0`：返回 `data`（缺失视为空 Map）
/// - 其他：抛出携带原 code/message 的 [ApiException]
/// - 信封不合法（null / 缺 code）：按服务端异常处理
Map<String, dynamic> unwrapEnvelope(
  Map<String, dynamic>? json, {
  int? httpStatus,
}) {
  if (json == null) {
    throw ApiException(kCodeServerErrorBase, '服务器开小差了，请稍后重试',
        httpStatus: httpStatus);
  }
  final dynamic rawCode = json['code'];
  final int? parsed =
      rawCode is int ? rawCode : int.tryParse(rawCode?.toString() ?? '');
  final int code = parsed ?? kCodeServerErrorBase;
  if (code != 0) {
    final String serverMessage = json['message'] as String? ?? '';
    throw ApiException(code, serverMessage.isNotEmpty ? serverMessage : '请求失败',
        httpStatus: httpStatus);
  }
  final dynamic data = json['data'];
  return data is Map<String, dynamic>
      ? data
      : data is List<dynamic>
          ? {'list': data}
          : <String, dynamic>{};
}
