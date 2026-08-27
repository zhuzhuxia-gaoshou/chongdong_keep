/// 契约时间格式工具：接口出入网的时间一律 ISO8601 且必带时区偏移
/// （如 `2026-08-27T14:30:00+08:00`）。M3 运动记录上报前统一走这里生成。
library;

/// 宽松解析：非法输入返回 null，由调用方决定兜底值（绝不抛异常打断 UI）
DateTime? tryParseIsoWithOffset(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    return DateTime.parse(s);
  } on FormatException {
    return null;
  }
}

/// 生成带本地时区偏移的 ISO8601 字符串。
///
/// 输入若是 UTC 时间会先转本地再追加 ±HH:mm 后缀，
/// 保证输出恒不含 `Z` 且可被两端无歧义还原同一时刻。
String formatIsoWithOffset(DateTime dt) {
  final local = dt.isUtc ? dt.toLocal() : dt;
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  String two(int v) => v.toString().padLeft(2, '0');
  final hh = two(offset.inHours.abs());
  final mm = two(offset.inMinutes.remainder(60));
  return '${local.toIso8601String()}$sign$hh:$mm';
}
