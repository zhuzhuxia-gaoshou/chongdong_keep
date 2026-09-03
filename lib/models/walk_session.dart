import 'exercise_record.dart';

/// 遛狗进行中的可恢复会话快照（PRD 4.2.3「APP被杀」场景）。
///
/// 运动中每 10 秒落盘一次；进程被杀后下次启动由遛狗页检测并弹出
/// 「继续 / 结束保存 / 放弃」恢复弹窗。route 上限 2000 点防体积膨胀。
class WalkSession {
  /// 持久化时轨迹点上限（超出裁掉头部，distance/steps 已随快照保存不受影响）
  static const int maxRoutePoints = 2000;

  final List<String> selectedPetIds;
  final DateTime startTime;
  final int elapsedSeconds; // 已运动秒数（恢复时按墙钟回推，跨进程死亡也连续）
  final List<GeoPoint> route;
  final double distance; // 公里
  final int steps;
  final String locationName;
  final String? startPhotoPath;
  final double currentLat;
  final double currentLng;

  WalkSession({
    required this.selectedPetIds,
    required this.startTime,
    required this.elapsedSeconds,
    required this.route,
    required this.distance,
    required this.steps,
    required this.locationName,
    required this.startPhotoPath,
    required this.currentLat,
    required this.currentLng,
  });

  /// 超出上限时裁掉头部、保留最近轨迹
  List<GeoPoint> get routeCapped => route.length > maxRoutePoints
      ? route.sublist(route.length - maxRoutePoints)
      : route;

  Map<String, dynamic> toJson() => {
        'selectedPetIds': selectedPetIds,
        'startTime': startTime.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        'route': routeCapped.map((e) => e.toJson()).toList(),
        'distance': distance,
        'steps': steps,
        'locationName': locationName,
        'startPhotoPath': startPhotoPath,
        'currentLat': currentLat,
        'currentLng': currentLng,
      };

  factory WalkSession.fromJson(Map<String, dynamic> json) => WalkSession(
        selectedPetIds: (json['selectedPetIds'] as List<dynamic>? ?? [])
            .cast<String>(),
        startTime: DateTime.parse(json['startTime'] as String),
        elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
        route: (json['route'] as List<dynamic>? ?? [])
            .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
        steps: json['steps'] as int? ?? 0,
        locationName: json['locationName'] as String? ?? '',
        startPhotoPath: json['startPhotoPath'] as String?,
        currentLat: (json['currentLat'] as num?)?.toDouble() ?? 39.9,
        currentLng: (json['currentLng'] as num?)?.toDouble() ?? 116.4,
      );
}
