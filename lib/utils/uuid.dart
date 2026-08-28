import 'dart:math';

/// 极简 UUID v4 生成器（契约 §4.6 幂等键 clientRecordId 用）。
///
/// 刻意不引入 uuid 包——本项目依赖面冻结（Gradle 环境脆弱），
/// 而这里只需要随机十六进制串，十几行足够。
/// 使用 [Random.secure]，失败时退回时间戳+随机混合（设备熵源极罕见不可用）。
String newUuidV4() {
  final Random rnd;
  try {
    rnd = Random.secure();
  } on UnsupportedError {
    return _fallbackUuid();
  }
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  return _render(bytes);
}

String _fallbackUuid() {
  final rnd = Random(DateTime.now().microsecondsSinceEpoch);
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  return _render(bytes);
}

String _render(List<int> bytes) {
  // 版本位与变体位按 RFC 4122 覆写：v4 / RFC4122
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
