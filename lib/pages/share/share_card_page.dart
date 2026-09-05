import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/exercise_record.dart';
import '../../models/pet.dart' show PetSpecies;
import '../../services/app_state.dart';
import '../../services/map_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_platform.dart';

/// 分享卡片：5 套真实版式（可爱/杂志/数据/夜景/生日），不再只是换色。
/// - 类型徽章取自 record.typeDisplayName（遛狗 / 陪猫玩 · 逗猫棒），此前写死"遛狗"
/// - 遛狗且有轨迹 → 腾讯静态图真实地图描线（GCJ-02）；加载失败/Web → 手绘轨迹回退
/// - 显示距离/分享位置 跟随设置页隐私开关
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
  String _petName = '宝贝';
  String _petEmoji = '🐾';
  late final String _mapUrl;
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
    final state = context.read<AppState>();
    for (final p in state.pets) {
      if (p.id == widget.record.petId) {
        _petName = p.name;
        _petEmoji = p.species == PetSpecies.cat ? '🐈' : '🐕';
        break;
      }
    }
    _mapUrl = MapService.buildRouteStaticMapUrl(widget.record.route);
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

  // ---- 卡片数据 ----

  String get _typeLabel => widget.record.typeDisplayName;
  String get _minutes => '${widget.record.duration.inMinutes}';
  String get _km => widget.record.distance.toStringAsFixed(1);
  String get _steps => '${widget.record.steps}';
  String get _dateLabel {
    final d = widget.record.startTime;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  bool get _hasLocation =>
      _showLocation &&
      widget.record.locationName != null &&
      widget.record.locationName!.isNotEmpty;

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
                  const Text('选择版式',
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
    switch (_selectedTemplate) {
      case 1:
        return _layoutMagazine(_templates[1]);
      case 2:
        return _layoutData(_templates[2]);
      case 3:
        return _layoutNight(_templates[3]);
      case 4:
        return _layoutParty(_templates[4]);
      default:
        return _layoutCute(_templates[0]);
    }
  }

  // ---- 版式 1：可爱风（圆头像 + 白边地图 + 胶囊数据） ----

  Widget _layoutCute(Map<String, dynamic> t) {
    return _cardShell(t,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_petEmoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_petName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text(_dateLabel,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white70)),
                    ]),
              ),
              _badge(t),
            ]),
            const SizedBox(height: 14),
            _mapFrame(
              height: 150,
              radius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 3),
            ),
            const SizedBox(height: 14),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _pill(_minutes, '分钟'),
                  if (_showDistance) _pill(_km, '公里'),
                  _pill(_steps, '步数'),
                ]),
            if (_hasLocation) ...[
              const SizedBox(height: 8),
              Center(
                  child: Text('📍 ${widget.record.locationName}',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white70))),
            ],
            const SizedBox(height: 10),
            const Center(
                child: Text('坚持运动，和宝贝一起健康成长',
                    style: TextStyle(fontSize: 11, color: Colors.white70))),
          ],
        ));
  }

  // ---- 版式 2：杂志风（大标题 + 细线分栏） ----

  Widget _layoutMagazine(Map<String, dynamic> t) {
    final verb = widget.record.type == ExerciseType.walkDog ? '一起遛狗' : '一起陪玩';
    return _cardShell(t,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CHONGDONG KEEP · 宠动Keep',
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.white60,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('和$_petName$verb',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 12),
            _mapFrame(height: 140, radius: BorderRadius.circular(8)),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 10),
            Row(children: [
              _statCol(_minutes, '运动时长（分）'),
              _vLine(),
              if (_showDistance) ...[_statCol(_km, '距离（公里）'), _vLine()],
              _statCol(_steps, '步数'),
            ]),
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 8),
            Row(children: [
              Text(_dateLabel,
                  style: const TextStyle(fontSize: 10, color: Colors.white60)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white38),
                    borderRadius: BorderRadius.circular(999)),
                child: Text(_typeLabel,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ));
  }

  // ---- 版式 3：数据风（地图条 + 2×2 数据格） ----

  Widget _layoutData(Map<String, dynamic> t) {
    final now = widget.record.startTime;
    final dateCell = '${now.month}/${now.day}';
    return _cardShell(t,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('运动数据',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const Spacer(),
              _badge(t),
            ]),
            const SizedBox(height: 12),
            _mapFrame(height: 96, radius: BorderRadius.circular(10)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _dataCell(_minutes, '时长 · 分钟')),
              const SizedBox(width: 10),
              Expanded(
                  child: _dataCell(_showDistance ? _km : dateCell,
                      _showDistance ? '距离 · 公里' : '日期')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _dataCell(_steps, '步数')),
              const SizedBox(width: 10),
              Expanded(child: _dataCell('${widget.record.route.length}', '轨迹点')),
            ]),
            const SizedBox(height: 12),
            const Center(
                child: Text('宠动Keep · 和宝贝一起动起来',
                    style: TextStyle(fontSize: 11, color: Colors.white70))),
          ],
        ));
  }

  // ---- 版式 4：夜景风（大地图 + 大数字） ----

  Widget _layoutNight(Map<String, dynamic> t) {
    return _cardShell(t,
        child: Column(
          children: [
            Stack(children: [
              _mapFrame(
                  height: 170, radius: BorderRadius.circular(12)),
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$_petEmoji $_petName · $_typeLabel',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text(_minutes,
                style: const TextStyle(
                    fontSize: 36,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(widget.record.type == ExerciseType.walkDog ? '分钟遛狗' : '分钟陪玩',
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
            const SizedBox(height: 12),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showDistance)
                    Text('${_km}km  ',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70)),
                  Text('$_steps 步',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white70)),
                ]),
            if (_hasLocation) ...[
              const SizedBox(height: 8),
              Text('📍 ${widget.record.locationName}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38)),
            ],
          ],
        ));
  }

  // ---- 版式 5：生日风（庆祝 + 圆形地图） ----

  Widget _layoutParty(Map<String, dynamic> t) {
    return _cardShell(t,
        child: Column(
          children: [
            Text('🎉  $_petEmoji  🎉',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text('和$_petName的运动打卡',
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text('$_dateLabel · $_typeLabel',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: ClipOval(
                  child: _mapFrame(height: 150),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _pill(_minutes, '分钟'),
                  if (_showDistance) _pill(_km, '公里'),
                  _pill(_steps, '步数'),
                ]),
            const SizedBox(height: 10),
            const Center(
                child: Text('坚持就是胜利，今天也超棒！',
                    style: TextStyle(fontSize: 11, color: Colors.white70))),
          ],
        ));
  }

  // ---- 公共部件 ----

  Widget _cardShell(Map<String, dynamic> t, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t['color'] as Color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  /// 类型徽章：动态取 typeDisplayName（修复此前写死"🐕 遛狗"）
  Widget _badge(Map<String, dynamic> t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(_typeLabel,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }

  Widget _pill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ]),
    );
  }

  Widget _statCol(String value, String label) {
    return Expanded(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(value,
            style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 9, color: Colors.white60)),
      ]),
    );
  }

  Widget _vLine() => Container(
      width: 1, height: 26, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 10));

  Widget _dataCell(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ]),
    );
  }

  /// 地图区：真机 + 有轨迹 → 腾讯静态图（GCJ-02 描线）；
  /// 加载失败（含配额耗尽）/Web 端 → 手绘轨迹回退。
  Widget _mapFrame(
      {required double height,
      BorderRadius? radius,
      BoxBorder? border}) {
    final fallback = CustomPaint(
      size: Size(double.infinity, height),
      painter: _CardRoutePainter(widget.record.route, Colors.white70),
    );
    Widget child = (!AppPlatform.isWeb && _mapUrl.isNotEmpty)
        ? Image.network(_mapUrl,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback)
        : fallback;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: border,
        color: Colors.white24,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
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
