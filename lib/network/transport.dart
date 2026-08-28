import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// 传输层抽象：执行一次线上调用，返回完整响应信封 JSON。
///
/// - 业务错误码**原样透传**（由上层 [unwrapEnvelope] 统一解释）；
/// - 仅当拿不到合法信封时才在本层抛 [ApiException]：
///   负码 = 网络故障（-1 超时/断网、-2 响应体不是合法 JSON）、
///   40101 = HTTP 401 且无信封（引导上层走刷新链路）、
///   50000 = 其他 HTTP 异常。
abstract interface class Transport {
  Future<Map<String, dynamic>?> send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  });

  /// multipart 文件上传（POST）
  Future<Map<String, dynamic>?> sendMultipart(
    String path, {
    required List<int> bytes,
    required String filename,
    String fileField = 'file',
    Map<String, String> fields = const {},
    Map<String, String>? headers,
  });
}

/// 基于 package:http 的真实实现。
class HttpTransport implements Transport {
  HttpTransport(
    this.baseUrl, {
    this.timeout = const Duration(seconds: 10),
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  Uri _uri(String path, Map<String, String>? query) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  /// package:http 对 String body 默认打 text/plain，Express 只认
  /// application/json 才解析请求体——联调实测（2026-08-28）：不带此
  /// 头则登录/上报等所有带体请求被后端判成"参数缺失"。所有 JSON 请求
  /// 显式声明编码；调用方已给 content-type 时不覆盖。
  static Map<String, String> _jsonHeaders(Map<String, String>? headers) => {
        'Content-Type': 'application/json; charset=utf-8',
        ...?headers,
      };

  @override
  Future<Map<String, dynamic>?> send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, query);
    try {
      final m = method.toUpperCase();
      late final http.Response resp;
      switch (m) {
        case 'GET':
          resp = await _client.get(uri, headers: headers).timeout(timeout);
        case 'PATCH':
          resp = await _client
              .patch(uri,
                  body: jsonEncode(body), headers: _jsonHeaders(headers))
              .timeout(timeout);
        case 'DELETE':
          // 联调坑：早期实现落入 else→post 分支，DELETE 被当 POST 发出
          resp = await _client.delete(uri, headers: headers).timeout(timeout);
        default:
          resp = await _client
              .post(uri,
                  body: jsonEncode(body), headers: _jsonHeaders(headers))
              .timeout(timeout);
      }
      return _decode(resp);
    } on TimeoutException {
      throw ApiException(-1, '请求超时');
    } on http.ClientException {
      throw ApiException(-1, '网络连接失败');
    }
  }

  @override
  Future<Map<String, dynamic>?> sendMultipart(
    String path, {
    required List<int> bytes,
    required String filename,
    String fileField = 'file',
    Map<String, String> fields = const {},
    Map<String, String>? headers,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _uri(path, null))
        ..fields.addAll(fields)
        ..headers.addAll(headers ?? const {})
        ..files.add(
          http.MultipartFile.fromBytes(fileField, bytes, filename: filename),
        );
      final streamed = await _client.send(req).timeout(timeout);
      final resp = await http.Response.fromStream(streamed).timeout(timeout);
      return _decode(resp);
    } on TimeoutException {
      throw ApiException(-1, '上传超时');
    } on http.ClientException {
      throw ApiException(-1, '网络连接失败');
    }
  }

  Map<String, dynamic>? _decode(http.Response resp) {
    dynamic json;
    if (resp.body.isNotEmpty) {
      try {
        json = jsonDecode(resp.body);
      } on FormatException {
        json = null;
      }
    }
    if (json is Map<String, dynamic>) return json; // 信封存在即交上层解释

    final inRange = resp.statusCode >= 200 && resp.statusCode < 300;
    if (inRange) {
      // 成功状态却没有合法信封：视为坏响应
      throw ApiException(-2, '响应解析失败', httpStatus: resp.statusCode);
    }
    if (resp.statusCode == 401) {
      throw ApiException(kCodeAccessExpired, '登录已过期', httpStatus: 401);
    }
    throw ApiException(
      kCodeServerErrorBase,
      '服务器开小差了，请稍后重试',
      httpStatus: resp.statusCode,
    );
  }
}
