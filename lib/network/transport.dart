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
      if (m == 'GET') {
        resp = await _client.get(uri, headers: headers).timeout(timeout);
      } else if (m == 'PATCH') {
        resp = await _client
            .patch(uri, body: jsonEncode(body), headers: headers)
            .timeout(timeout);
      } else {
        resp = await _client
            .post(uri, body: jsonEncode(body), headers: headers)
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
