import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_config.dart';
import '../models/exercise_record.dart';
import '../utils/coord_convert.dart';
import '../theme/app_colors.dart';

/// 遛狗地图组件
///
/// - 已配置腾讯地图Key（--dart-define=TENCENT_MAP_KEY=xxx）：
///   用 WebView 加载腾讯地图 JS API，轨迹实时推送到地图上绘制；
///   加载完成或出错、超时会自动处理，绝不一直停在"加载中"。
/// - 未配置Key 或 WebView 加载失败/超时：
///   自动降级为本地【离线轨迹图】（Canvas 绘制），GPS 记录功能完全不受影响。
class TencentMapWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final List<GeoPoint> route;
  final bool showCurrentLocation;

  const TencentMapWidget({
    super.key,
    this.initialLat = 39.9,
    this.initialLng = 116.4,
    this.route = const [],
    this.showCurrentLocation = true,
  });

  @override
  State<TencentMapWidget> createState() => _TencentMapWidgetState();
}

class _TencentMapWidgetState extends State<TencentMapWidget> {
  WebViewController? _controller;
  bool _isLoading = true; // WebView 是否还在加载
  bool _useFallback = false; // 是否降级为本地轨迹图
  Timer? _loadTimeout;
  int _lastPushedSize = 0;

  bool get _hasKey => ApiConfig.hasTencentMap;

  @override
  void initState() {
    super.initState();
    _lastPushedSize = widget.route.length;
    if (_hasKey) {
      _initWebView();
    } else {
      _useFallback = true;
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.mintLight)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _loadTimeout?.cancel();
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) => _switchToFallback(),
        ),
      )
      ..loadHtmlString(_generateMapHtml());

    // 兜底：10秒仍未加载完成（如网络不通）→ 切换本地轨迹图
    _loadTimeout = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) _switchToFallback();
    });
  }

  void _switchToFallback() {
    _loadTimeout?.cancel();
    if (mounted) {
      setState(() {
        _useFallback = true;
        _isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant TencentMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 轨迹有新点且 WebView 可用时，把完整路线推送过去实时重绘
    if (!_useFallback &&
        _controller != null &&
        widget.route.length > _lastPushedSize) {
      _lastPushedSize = widget.route.length;
      // 底图为 GCJ-02：显示前转换（存储/上报仍是 WGS-84）
      final points = widget.route.map((p) {
        final (lat, lng) = wgs84ToGcj02(p.latitude, p.longitude);
        return '{"lat":$lat,"lng":$lng}';
      }).join(',');
      _controller!
          .runJavaScript('window.updateRoute && window.updateRoute([$points]);')
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    super.dispose();
  }

  String _generateMapHtml() {
    final (initLat, initLng) =
        wgs84ToGcj02(widget.initialLat, widget.initialLng);
    final initialPoints = widget.route.map((p) {
      final (lat, lng) = wgs84ToGcj02(p.latitude, p.longitude);
      return '{lat: $lat, lng: $lng}';
    }).join(',');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; }
    html, body { width: 100%; height: 100%; }
    #container { width: 100%; height: 100%; }
  </style>
  <script src="https://map.qq.com/api/gljs?v=2.exp&key=${ApiConfig.tencentMapKey}"></script>
  <script>
    var map = null;
    var overlays = [];
    var didFit = false;

    function clearOverlays() {
      overlays.forEach(function(o) { try { o.setMap(null); } catch (e) {} });
      overlays = [];
    }

    function drawRoute(points) {
      if (!map || !points || points.length === 0) return;
      var latlngs = points.map(function(p) { return new TMap.LatLng(p.lat, p.lng); });

      if (latlngs.length >= 2) {
        var line = new TMap.MultiPolyline({
          map: map,
          styles: {
            style: new TMap.PolylineStyle({
              color: "#4CAF82",
              width: 5,
              lineCap: "round",
              lineJoin: "round"
            })
          },
          geometries: [{
            id: "route_" + Date.now(),
            styleId: "style",
            paths: latlngs
          }]
        });
        overlays.push(line);

        var cur = new TMap.MultiMarker({
          map: map,
          styles: {
            end: new TMap.MarkerStyle({
              width: 28,
              height: 28,
              anchor: { x: 14, y: 14 },
              src: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyOCIgaGVpZ2h0PSIyOCIgdmlld0JveD0iMCAwIDIwIDIwIj48Y2lyY2xlIGN4PSIxMCIgY3k9IjEwIiByPSI5IiBmaWxsPSIjNEE5RkQ5IiBzdHJva2U9IiNmZmYiIHN0cm9rZS13aWR0aD0iMi41Ii8+PGNpcmNsZSBjeD0iMTAiIGN5PSIxMCIgcj0iNCIgZmlsbD0iI2ZmZiIvPjwvc3ZnPg=="
            })
          },
          geometries: [{
            id: "cur_" + Date.now(),
            styleId: "end",
            position: latlngs[latlngs.length - 1]
          }]
        });
        overlays.push(cur);

        // 只在首次拥有两点时自适应视野，避免运动中画面跳动
        if (!didFit) {
          var bounds = new TMap.LatLngBounds();
          latlngs.forEach(function(ll) { bounds.extend(ll); });
          try { map.fitBounds(bounds); } catch (e) {}
          didFit = true;
        }
      } else {
        var p = new TMap.MultiMarker({
          map: map,
          geometries: [{ id: "p_" + Date.now(), position: latlngs[0] }]
        });
        overlays.push(p);
      }
    }

    // Flutter 端轨迹更新入口（传入完整点集）
    window.updateRoute = function(points) { drawRoute(points); };

    function initMap() {
      var center = new TMap.LatLng($initLat, $initLng);
      map = new TMap.Map("container", {
        center: center,
        zoom: 16,
        pitch: 30
      });
      drawRoute([$initialPoints]);
    }

    setTimeout(initMap, 100);
  </script>
</head>
<body>
  <div id="container"></div>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return _TrackView(
        route: widget.route,
        badgeText: _hasKey ? '离线轨迹模式' : '离线轨迹模式 · 未配置地图Key',
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          Container(
            color: AppColors.mintLight,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                        color: AppColors.mint, strokeWidth: 2),
                  ),
                  SizedBox(height: 8),
                  Text('地图加载中...',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textSoft)),
                ],
              ),
            ),
          ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.line),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.mint),
                SizedBox(width: 4),
                Text('腾讯地图',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSoft)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 本地离线轨迹视图：Canvas 绘制路线，无需任何网络和Key
class _TrackView extends StatelessWidget {
  final List<GeoPoint> route;
  final String badgeText;

  const _TrackView({required this.route, required this.badgeText});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mintLight,
      child: Stack(
        children: [
          CustomPaint(
            painter: _TrackPainter(route),
            child: const SizedBox.expand(),
          ),
          if (route.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.satellite_alt_outlined,
                      size: 40, color: Colors.white.withValues(alpha: 0.9)),
                  const SizedBox(height: 8),
                  Text('等待GPS信号…',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700.withValues(alpha: 0.7))),
                  const SizedBox(height: 4),
                  Text('已开始记录，信号稳定后显示轨迹',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              Colors.green.shade700.withValues(alpha: 0.55))),
                ],
              ),
            ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route, size: 14, color: AppColors.mint),
                  const SizedBox(width: 4),
                  Text(badgeText,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSoft)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  final List<GeoPoint> route;

  _TrackPainter(this.route);

  @override
  void paint(Canvas canvas, Size size) {
    // 背景 + 淡网格，模拟地图底图质感
    final bgPaint = Paint()..color = AppColors.mintLight;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    const gridStep = 26.0;
    for (double x = 0; x <= size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (route.isEmpty) return;

    // 经纬度范围
    double minLat = route.first.latitude, maxLat = route.first.latitude;
    double minLng = route.first.longitude, maxLng = route.first.longitude;
    for (final p in route) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    const pad = 32.0;
    final availW = size.width - pad * 2;
    final availH = size.height - pad * 2;
    final spanLat = math.max(maxLat - minLat, 1e-5); // 避免单点时跨度为0
    final spanLng = math.max(maxLng - minLng, 1e-5);

    final scale = math.min(availW / spanLng, availH / spanLat);
    final offX = pad + (availW - spanLng * scale) / 2;
    final offY = pad + (availH - spanLat * scale) / 2;

    Offset toCanvas(GeoPoint p) => Offset(
          offX + (p.longitude - minLng) * scale,
          offY + (maxLat - p.latitude) * scale, // 纬度向上为北，画布y向下
        );

    // 轨迹线
    if (route.length >= 2) {
      final linePaint = Paint()
        ..color = AppColors.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()
        ..moveTo(toCanvas(route.first).dx, toCanvas(route.first).dy);
      for (int i = 1; i < route.length; i++) {
        final o = toCanvas(route[i]);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // 起点标记（绿色实心圆）
    final start = toCanvas(route.first);
    canvas.drawCircle(start, 7, Paint()..color = AppColors.mint);
    canvas.drawCircle(
        start,
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);

    // 当前位置（蓝色圆点+白圈）
    final cur = toCanvas(route.last);
    canvas.drawCircle(cur, 9, Paint()..color = Colors.white);
    canvas.drawCircle(cur, 6.5, Paint()..color = AppColors.skyDeep);
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) =>
      oldDelegate.route.length != route.length;
}
