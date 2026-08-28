import '../../utils/iso_time.dart';
import '../exercise_record.dart';
import 'wire_enums.dart';

/// 服务端 ExerciseRecordDTO ↔ 本地 ExerciseRecord 转换（契约 §3 / §4.6 ⑭⑮）。
///
/// - 时间出入网统一走 [formatIsoWithOffset]（带时区偏移，契约强约束）；
/// - `startPhotoPath`（本地文件路径）在 API 层换名 `startPhotoUrl`，
///   本地路径**绝不上网**（⑬ 图床未就绪前一律发 null）；
/// - 上报前抽稀：route 上限 5000 点，超出等距采样、末点必留；
/// - 解析方向全程宽容（缺字段给默认值），服务端字段增减不至于崩 UI。
class RecordDto {
  const RecordDto._();

  /// 契约 ⑭：单次上报轨迹点上限。
  static const int maxRoutePoints = 5000;

  /// 契约 ⑮：列表接口服务端会按 ~50 抽稀轨迹，本端展示轨迹点数足够用。
  static const int listRouteThinFactor = 50;

  /// 上报体：ExerciseRecordDTO 去掉 id/userId/createdAt（服务端生成）。
  static Map<String, dynamic> toWire(ExerciseRecord r) => {
        'clientRecordId': r.clientRecordId,
        'petId': r.petId,
        'type': exerciseTypeToWire(r.type),
        'startTime': formatIsoWithOffset(r.startTime),
        'endTime': formatIsoWithOffset(r.endTime),
        'duration': r.duration.inSeconds,
        'distance': r.distance,
        'steps': r.steps,
        'locationName': r.locationName,
        'startPhotoUrl': _urlOrNull(r.startPhotoPath),
        'isCompleted': r.isCompleted,
        'isManual': r.isManual,
        'route': thinRoute(r.route).map(_pointToWire).toList(),
      };

  static ExerciseRecord fromWire(Map<String, dynamic> j) {
    final start = tryParseIsoWithOffset(j['startTime'] as String?) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final end = tryParseIsoWithOffset(j['endTime'] as String?) ?? start;
    return ExerciseRecord(
      id: '${j['id'] ?? ''}',
      clientRecordId: j['clientRecordId'] as String?,
      petId: '${j['petId'] ?? ''}',
      userId: '${j['userId'] ?? ''}',
      type: exerciseTypeFromWire('${j['type'] ?? 'walkDog'}'),
      startTime: start,
      endTime: end.isAfter(start) ? end : start,
      duration: Duration(
          seconds: _asInt(j['duration']) ?? end.difference(start).inSeconds),
      distance: _asDouble(j['distance']) ?? 0,
      steps: _asInt(j['steps']) ?? 0,
      route: _pointsFromWire(j['route']),
      locationName: j['locationName'] as String?,
      // startPhotoUrl 是 CDN 地址，而本地模型的 startPhotoPath 全程按
      // Image.file 消费——刻意不映射；图床（⑬）接入后再加远程图展示字段。
      isCompleted: j['isCompleted'] as bool? ?? true,
      isManual: j['isManual'] as bool? ?? false,
    );
  }

  /// 等距抽稀：n≤5000 原样返回；否则每 step=ceil(n/5000) 取一点并保证末点。
  static List<GeoPoint> thinRoute(List<GeoPoint> route) {
    if (route.length <= maxRoutePoints) return route;
    final step = (route.length / maxRoutePoints).ceil();
    final out = <GeoPoint>[];
    for (var i = 0; i < route.length; i += step) {
      out.add(route[i]);
    }
    if (out.last != route.last) out.add(route.last);
    return out;
  }

  static Map<String, dynamic> _pointToWire(GeoPoint p) => {
        'latitude': double.parse(p.latitude.toStringAsFixed(6)),
        'longitude': double.parse(p.longitude.toStringAsFixed(6)),
        'timestamp': formatIsoWithOffset(p.timestamp),
        'accuracy': p.accuracy,
      };

  static List<GeoPoint> _pointsFromWire(Object? v) {
    if (v is! List) return const [];
    final out = <GeoPoint>[];
    for (final e in v) {
      if (e is! Map) continue;
      final lat = _asDouble(e['latitude']);
      final lng = _asDouble(e['longitude']);
      if (lat == null || lng == null) continue; // 缺坐标的点直接丢弃
      out.add(GeoPoint(
        latitude: lat,
        longitude: lng,
        timestamp:
            tryParseIsoWithOffset(e['timestamp'] as String?) ?? DateTime.now(),
        accuracy: _asDouble(e['accuracy']),
      ));
    }
    return out;
  }

  /// 只把真正的远端 URL 当图片地址；本地文件路径不上网也不回填。
  static String? _urlOrNull(Object? v) {
    final s = v as String?;
    if (s == null || s.isEmpty) return null;
    return s.startsWith('http') ? s : null;
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  static double? _asDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}');
  }
}
