import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_config.dart';
import '../models/exercise_record.dart';
import '../utils/app_platform.dart';
import '../utils/coord_convert.dart';

/// GPS定位与地图服务
class MapService {
  /// 定位精度差于该值（米）视为弱信号（PRD 4.2.3）
  static const double kWeakGpsAccuracyMeters = 30;
  /// 超过该时长未收到有效定位点视为信号停滞（PRD 4.2.3 的">30秒提示"）
  static const Duration kWeakGpsStaleness = Duration(seconds: 30);

  /// 恢复会话时新旧轨迹衔接点距离超过该值（米），视为进程死亡期间已被
  /// 移动到别处：旧轨迹封存（距离已累计），新段从当前位置重新起绘
  static const double kResumeGapMeters = 200;

  /// 检查并请求定位权限
  static Future<bool> checkPermission() async {
    // Web：浏览器自行管理定位授权，geolocator 取位置时会触发授权弹窗
    if (AppPlatform.isWeb) return true;
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    if (status.isGranted) {
      var bgStatus = await Permission.locationAlways.status;
      if (bgStatus.isDenied) {
        await Permission.locationAlways.request();
      }
    }
    return status.isGranted || status.isLimited;
  }

  /// 获取当前位置
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// 开始GPS轨迹追踪
  static Stream<Position> startTracking() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  /// 计算两点间距离（米）
  static double distanceBetween(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// 计算轨迹总距离（公里）
  static double calculateRouteDistance(List<GeoPoint> route) {
    if (route.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < route.length; i++) {
      total += distanceBetween(
        route[i - 1].latitude, route[i - 1].longitude,
        route[i].latitude, route[i].longitude,
      );
    }
    return total / 1000;
  }

  /// 根据速度估算步数
  static int estimateSteps(double distanceKm) {
    return (distanceKm * 1000 / 0.5).round();
  }

  /// 判断 curr 相对 prev 是否为GPS漂移点
  /// （两点间推算速度≥15m/s，或时间戳异常时视为漂移）
  static bool isAbnormalPoint(GeoPoint prev, GeoPoint curr) {
    final timeDiff = curr.timestamp.difference(prev.timestamp).inSeconds;
    if (timeDiff <= 0) return true;
    final speed = distanceBetween(
      prev.latitude, prev.longitude,
      curr.latitude, curr.longitude,
    ) / timeDiff;
    return speed >= 15;
  }

  /// 过滤GPS漂移点
  static List<GeoPoint> filterAbnormalPoints(List<GeoPoint> route) {
    if (route.length < 2) return route;
    final filtered = <GeoPoint>[route[0]];
    for (int i = 1; i < route.length; i++) {
      if (!isAbnormalPoint(filtered.last, route[i])) {
        filtered.add(route[i]);
      }
    }
    return filtered;
  }

  /// 腾讯地图逆地址解析 - 根据坐标获取地址描述
  /// 结果按 ~110 米网格缓存（会话内），避免重复消耗 WebService 日配额
  static final Map<String, String> _placeCache = {};

  static Future<String> getLocationName(double lat, double lng) async {
    if (!ApiConfig.hasTencentMap) {
      return '当前位置';
    }
    final cacheKey =
        '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    final cached = _placeCache[cacheKey];
    if (cached != null) return cached;
    try {
      // 腾讯 WebService 接受 GCJ-02，入参先转换（GPS 原始值为 WGS-84）
      final (gcjLat, gcjLng) = wgs84ToGcj02(lat, lng);
      final response = await http.get(Uri.parse(
        'https://apis.map.qq.com/ws/geocoder/v1/?location=$gcjLat,$gcjLng&key=${ApiConfig.tencentMapKey}&output=json',
      ));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 0 && data['result'] != null) {
          final address = data['result']['address'] ?? '未知位置';
          final poi = data['result']['formatted_addresses']?['recommend'] ?? address;
          _placeCache[cacheKey] = poi as String;
          return poi;
        }
      }
      return '当前位置';
    } catch (e) {
      return '当前位置';
    }
  }

  /// 获取附近地址的简短描述（用于卡片展示）
  static Future<String> getShortLocationName(double lat, double lng) async {
    final fullName = await getLocationName(lat, lng);
    if (fullName.length > 15) {
      return '${fullName.substring(0, 15)}...';
    }
    return fullName;
  }

  /// 格式化距离显示
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()}m';
    }
    return '${km.toStringAsFixed(2)}km';
  }

  /// 格式化时长显示
  static String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// 生成腾讯地图静态图片URL（用于分享卡片）
  static String getStaticMapUrl(double lat, double lng, {int zoom = 15, int width = 600, int height = 400}) {
    if (!ApiConfig.hasTencentMap) {
      return '';
    }
    return 'https://apis.map.qq.com/ws/staticmap/v2/?center=$lat,$lng&zoom=$zoom&size=$width*$height&key=${ApiConfig.tencentMapKey}';
  }

  /// 搜索附近宠物医院（腾讯 WebService 地点搜索，PRD 4.5.2）。
  /// 入参为 WGS-84，内部先转 GCJ-02 再请求。
  /// 无 Key / 请求失败 / 配额不足返回 null（调用方降级为友好空态）。
  static Future<List<PetHospital>?> searchNearbyPetHospitals(
      double lat, double lng,
      {int radiusMeters = 5000}) async {
    if (!ApiConfig.hasTencentMap) return null;
    final (gcjLat, gcjLng) = wgs84ToGcj02(lat, lng);
    try {
      final url = 'https://apis.map.qq.com/ws/place/v1/search'
          '?keyword=${Uri.encodeComponent('宠物医院')}'
          '&boundary=nearby($gcjLat,$gcjLng,$radiusMeters)'
          '&orderby=_distance&page_size=10'
          '&key=${ApiConfig.tencentMapKey}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body);
      if (data['status'] != 0 || data['data'] is! List) return null;
      return (data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(PetHospital.fromMap)
          .toList();
    } catch (_) {
      return null;
    }
  }
}

/// 附近宠物医院搜索结果
class PetHospital {
  final String title;
  final String address;
  final double? distanceMeters; // 距查询点直线距离（米）
  final String? tel;

  PetHospital({
    required this.title,
    required this.address,
    this.distanceMeters,
    this.tel,
  });

  factory PetHospital.fromMap(Map<String, dynamic> m) => PetHospital(
        title: m['title'] as String? ?? '未知医院',
        address: m['address'] as String? ?? '',
        distanceMeters: (m['_distance'] as num?)?.toDouble(),
        tel: _cleanTel(m['tel'] as String?),
      );

  static String? _cleanTel(String? raw) {
    final t = raw?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
