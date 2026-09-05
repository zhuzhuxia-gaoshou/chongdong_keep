import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../models/exercise_record.dart';
import '../../services/storage_service.dart';

class ShareCardPage extends StatefulWidget {
  final ExerciseRecord record;

  const ShareCardPage({super.key, required this.record});

  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  int _selectedTemplate = 0;
  bool _showLocation = false;
  bool _showDistance = true;
  bool _saving = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  final List<Map<String, dynamic>> _templates = [
    {'name': '可爱风', 'color': AppColors.mint, 'icon': '🐾'},
    {'name': '杂志风', 'color': const Color(0xFF7E57C2), 'icon': '📖'},
    {'name': '数据风', 'color': const Color(0xFF26C6DA), 'icon': '📊'},
    {'name': '夜景风', 'color': const Color(0xFF37474F), 'icon': '🌙'},
    {'name': '生日风', 'color': AppColors.coral, 'icon': '🎂'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  /// 隐私设置（设置页）：分享位置作为页内开关的初始值，显示距离控制公里数展示。
  Future<void> _loadPrivacySettings() async {
    final s = await StorageService.loadAppSettings();
    if (!mounted) return;
    setState(() {
      _showLocation = (s['shareLocation'] as bool?) ?? false;
      _showDistance = (s['showDistance'] as bool?) ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分享卡片')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Screenshot(
                    controller: _screenshotController,
                    child: _buildCardPreview(),
                  ),
                  const SizedBox(height: 20),
                  const Text('选择模板',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  _buildTemplateSelector(),
                  const SizedBox(height: 16),
                  _buildOptions(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    final template = _templates[_selectedTemplate];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: template['color'] as Color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(template['icon'] as String,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text('宠动Keep',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('🐕 遛狗',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(200, 80),
                // 真实轨迹绘制（无轨迹时回退装饰曲线）
                painter: _CardRoutePainter(
                  widget.record.route,
                  Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCardStat('${widget.record.duration.inMinutes}', '分钟'),
              if (_showDistance)
                _buildCardStat(
                    widget.record.distance.toStringAsFixed(1), '公里'),
              _buildCardStat('${widget.record.steps}', '步'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (widget.record.locationName?.isEmpty ?? true)
                ? ''
                : (_showLocation
                    ? widget.record.locationName!
                    : '位置已隐藏'),
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text('坚持运动，和宝贝一起健康成长',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildCardStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          final isSelected = _selectedTemplate == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTemplate = index);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 56,
              decoration: BoxDecoration(
                color: template['color'] as Color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.text : Colors.transparent,
                  width: isSelected ? 3 : 0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(template['icon'] as String,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(template['name'] as String,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, size: 18, color: AppColors.textSoft),
          const SizedBox(width: 10),
          const Expanded(child: Text('显示位置', style: TextStyle(fontSize: 13))),
          Switch(
            value: _showLocation,
            onChanged: (v) => setState(() => _showLocation = v),
            activeColor: AppColors.mint,
          ),
        ],
      ),
    );
  }

  /// 截图卡片 → 系统分享面板（用户可保存到相册或发给好友）
  Future<void> _captureAndShare() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _screenshotController.capture();
      if (bytes == null) throw StateError('capture null');
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              mimeType: 'image/png', name: 'chongdong_card.png'),
        ],
        text:
            '我在宠动Keep完成了${widget.record.duration.inMinutes}分钟的运动，一起来关注宠物健康吧！',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('生成失败，再试一次哦')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
        color: AppColors.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : _captureAndShare,
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.save_alt_rounded, size: 15), SizedBox(width: 4), Text('保存相册')]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                await Share.share(
                    '我在宠动Keep完成了${widget.record.duration.inMinutes}分钟的运动，一起来关注宠物健康吧！');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.ios_share_rounded, size: 15), SizedBox(width: 4), Text('分享')]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardRoutePainter extends CustomPainter {
  final List<GeoPoint> route;
  final Color color;

  _CardRoutePainter(this.route, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 无轨迹/单点：画装饰曲线（catPlay 等无 GPS 记录）
    if (route.length < 2) {
      final path = Path()
        ..moveTo(10, size.height * 0.8)
        ..quadraticBezierTo(size.width * 0.3, size.height * 0.3,
            size.width * 0.5, size.height * 0.6)
        ..quadraticBezierTo(size.width * 0.7, size.height * 0.9,
            size.width * 0.85, size.height * 0.2)
        ..lineTo(size.width - 10, size.height * 0.4);
      canvas.drawPath(path, paint);
      return;
    }

    // 真实轨迹：按经纬度包围盒缩放进卡片区域
    double minLat = route.first.latitude, maxLat = route.first.latitude;
    double minLng = route.first.longitude, maxLng = route.first.longitude;
    for (final p in route) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    const pad = 12.0;
    final spanLat = (maxLat - minLat).abs().clamp(1e-5, 180.0);
    final spanLng = (maxLng - minLng).abs().clamp(1e-5, 180.0);
    final scale = (size.width - pad * 2) / spanLng <
            (size.height - pad * 2) / spanLat
        ? (size.width - pad * 2) / spanLng
        : (size.height - pad * 2) / spanLat;
    final offX = (size.width - spanLng * scale) / 2;
    final offY = (size.height - spanLat * scale) / 2;

    Offset toCanvas(GeoPoint p) => Offset(
          offX + (p.longitude - minLng) * scale,
          offY + (maxLat - p.latitude) * scale,
        );

    final path = Path()..moveTo(toCanvas(route.first).dx, toCanvas(route.first).dy);
    for (var i = 1; i < route.length; i++) {
      final o = toCanvas(route[i]);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, paint);

    // 起点/终点标记
    final start = toCanvas(route.first);
    final end = toCanvas(route.last);
    canvas.drawCircle(start, 4, Paint()..color = Colors.white);
    canvas.drawCircle(end, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CardRoutePainter oldDelegate) =>
      oldDelegate.route.length != route.length;
}
