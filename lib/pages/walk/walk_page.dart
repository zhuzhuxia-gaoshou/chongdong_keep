import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../services/app_state.dart';
import '../../services/map_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/tencent_map_widget.dart';
import '../../models/pet.dart';
import '../../models/exercise_record.dart';
import '../../utils/uuid.dart';
import '../share/share_card_page.dart';

class WalkPage extends StatefulWidget {
  const WalkPage({super.key});

  @override
  State<WalkPage> createState() => _WalkPageState();
}

class _WalkPageState extends State<WalkPage> {
  bool _isWalking = false;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  final List<String> _selectedPets = [];
  final List<GeoPoint> _route = [];
  StreamSubscription<Position>? _positionSub;
  double _distance = 0;
  int _steps = 0;
  Timer? _timer;
  double _currentLat = 39.9;
  double _currentLng = 116.4;
  String _locationName = '';
  String? _startPhotoPath;
  // GPS 质量监控（PRD 4.2.3）：弱信号/错误横幅
  bool _weakGps = false;
  String? _gpsError;
  DateTime _lastGoodFixAt = DateTime.now();

  Future<void> _toggleWalk() async {
    if (_isWalking) {
      _stopWalk();
    } else {
      await _onStartPressed();
    }
  }

  /// 开始前的准备流程：权限检查 → 可选拍照记录出发 → 正式开始追踪
  Future<void> _onStartPressed() async {
    final hasPermission = await MapService.checkPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要定位权限才能记录遛狗路线，请在设置中开启')),
        );
      }
      return;
    }

    // 用户可自由选择是否拍照记录出发时刻
    final wantPhoto = await _promptStartPhoto();
    String? photoPath;
    if (wantPhoto && mounted) {
      try {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 75,
          maxWidth: 1280,
        );
        if (picked != null) {
          photoPath = await StorageService.savePickedImage(picked.path);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开相机，已直接开始运动')),
          );
        }
      }
    }

    if (!mounted) return;
    _startWalk(startPhotoPath: photoPath);
  }

  /// 弹窗询问是否拍出发照片，返回 true 表示用户选择拍照
  Future<bool> _promptStartPhoto() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 18),
                const Text('📸 记录出发时刻？',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('给这次运动拍一张出发照片吧～ 不想拍也可以直接开始',
                    style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('跳过，直接开始'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.photo_camera_outlined, size: 17),
                        label: const Text('📷 拍一张'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result == true;
  }

  Future<void> _startWalk({String? startPhotoPath}) async {
    setState(() {
      _isWalking = true;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
      _route.clear();
      _distance = 0;
      _steps = 0;
      _startPhotoPath = startPhotoPath;
      _weakGps = false;
      _gpsError = null;
      _lastGoodFixAt = DateTime.now();
    });

    final initialPos = await MapService.getCurrentPosition();
    if (initialPos != null) {
      setState(() {
        _currentLat = initialPos.latitude;
        _currentLng = initialPos.longitude;
        _route.add(GeoPoint(
          latitude: initialPos.latitude,
          longitude: initialPos.longitude,
          timestamp: DateTime.now(),
          accuracy: initialPos.accuracy,
        ));
      });
      _loadLocationName(initialPos.latitude, initialPos.longitude);
    }

    _positionSub = MapService.startTracking().listen(
      (Position position) {
        if (!_isWalking) return;
        final point = GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          accuracy: position.accuracy,
        );
        // 丢弃GPS漂移点，避免路线和距离被异常坐标污染
        final last = _route.isEmpty ? null : _route.last;
        if (last != null && MapService.isAbnormalPoint(last, point)) {
          return;
        }
        final weak =
            position.accuracy > MapService.kWeakGpsAccuracyMeters;
        _lastGoodFixAt = DateTime.now();
        if (!mounted) return;
        setState(() {
          _route.add(point);
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _distance = MapService.calculateRouteDistance(_route);
          _steps = MapService.estimateSteps(_distance);
          _weakGps = weak;
        });
      },
      onError: (e) {
        // 不再静默：定位服务异常时提示用户轨迹可能不完整（每次会话提示一次）
        if (!_isWalking || !mounted || _gpsError != null) return;
        setState(() => _gpsError = '定位服务异常，轨迹可能不完整');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('定位出现异常，已尽力记录时长，路线可能不完整哦')),
        );
      },
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null && _isWalking) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
          // 长时间无有效定位点 → 视为弱信号停滞
          if (!_weakGps &&
              DateTime.now().difference(_lastGoodFixAt) >
                  MapService.kWeakGpsStaleness) {
            _weakGps = true;
          }
        });
      }
    });
  }

  Future<void> _loadLocationName(double lat, double lng) async {
    final name = await MapService.getShortLocationName(lat, lng);
    if (mounted) {
      setState(() => _locationName = name);
    }
  }

  void _stopWalk() {
    _positionSub?.cancel();
    _positionSub = null;
    _timer?.cancel();
    _timer = null;
    setState(() => _isWalking = false);

    final state = context.read<AppState>();
    final now = DateTime.now();
    ExerciseRecord? shareRecord; // 分享卡片用（多宠取第一只）
    for (final petId in _selectedPets) {
      final record = ExerciseRecord(
        id: 'rec_${now.millisecondsSinceEpoch}_$petId',
        clientRecordId: newUuidV4(), // ⑭ 上报幂等键（契约 §4.6）
        petId: petId,
        userId: state.user?.id ?? '',
        type: ExerciseType.walkDog,
        startTime: _startTime ?? now,
        endTime: now,
        duration: _elapsed,
        distance: _distance,
        steps: _steps,
        route: List.of(_route),
        locationName: _locationName,
        startPhotoPath: _startPhotoPath,
      );
      state.addRecord(record);
      shareRecord ??= record;
    }

    if (mounted && _elapsed.inMinutes >= 1) {
      _showWalkResult(record: shareRecord);
    }
  }

  void _showWalkResult({ExerciseRecord? record}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('🐾 遛狗完成！',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mint)),
              if (_locationName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('📍 $_locationName',
                    style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
              ],
              // 出发照片回顾
              if (_startPhotoPath != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_startPhotoPath!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _resultItem('⏱️', MapService.formatDuration(_elapsed), '时长'),
                  _resultItem('📏', MapService.formatDistance(_distance), '距离'),
                  _resultItem('👟', '$_steps', '步数'),
                ],
              ),
              const SizedBox(height: 16),
              if (_elapsed.inMinutes >= 5)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mintLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('✅ 今日打卡成功！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mint)),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.coralLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('还需${5 - _elapsed.inMinutes}分钟才能打卡',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.coral)),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final nav = Navigator.of(ctx);
                        nav.pop();
                        if (record != null) {
                          nav.push(MaterialPageRoute(
                              builder: (_) => ShareCardPage(record: record)));
                        }
                      },
                      child: const Text('🎨 生成卡片'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('完成'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mint)),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
      ],
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pets = state.pets;

    return Scaffold(
      appBar: AppBar(title: const Text('运动')),
      body: pets.isEmpty
          ? _buildNoPet()
          : _isWalking
              ? _buildWalkingView(state)
              : _buildReadyView(pets, state),
    );
  }

  Widget _buildReadyView(List<Pet> pets, AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('准备好遛狗了吗？',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('选择要一起运动的宠物，点击开始',
                style: TextStyle(fontSize: 13, color: AppColors.textSoft)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: pets.map((pet) {
                final isSelected = _selectedPets.contains(pet.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedPets.remove(pet.id);
                      } else {
                        _selectedPets.add(pet.id);
                      }
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.mintLight : AppColors.card,
                      border: Border.all(
                          color: isSelected ? AppColors.mint : AppColors.line,
                          width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pet.speciesEmoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(pet.name,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.mint
                                    : AppColors.text)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPets.isEmpty ? null : _toggleWalk,
                child: const Text('🐾 开始遛狗'),
              ),
            ),
            const SizedBox(height: 12),
            Text('GPS将自动记录路线、距离和步数',
                style: TextStyle(fontSize: 11, color: AppColors.textMute)),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkingView(AppState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 顶部信息条
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('🐕', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedPets
                              .map((id) => state.pets
                                  .firstWhere((p) => p.id == id,
                                      orElse: () => state.pets.first)
                                  .name)
                              .join(' + '),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  MapService.formatDuration(_elapsed),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          // 位置显示
          if (_locationName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.textSoft),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(_locationName,
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textSoft),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          // GPS 质量横幅（弱信号 / 定位异常，PRD 4.2.3）
          if (_weakGps || _gpsError != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E0),
                border: Border.all(color: const Color(0xFFF5C36B)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _gpsError ?? '定位信号较弱，数据可能有偏差哦',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9A6B1F)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // 腾讯地图区域
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: TencentMapWidget(
                initialLat: _currentLat,
                initialLng: _currentLng,
                route: _route,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 数据卡片
          Row(
            children: [
              Expanded(
                  child: _buildDataCard(
                      '📏 距离', MapService.formatDistance(_distance), '')),
              const SizedBox(width: 8),
              Expanded(child: _buildDataCard('👟 步数', '$_steps', '步')),
            ],
          ),
          const SizedBox(height: 10),
          // 目标进度
          Builder(builder: (context) {
            final pet = state.pets.firstWhere(
              (p) =>
                  p.id == (_selectedPets.isNotEmpty ? _selectedPets.first : ''),
              orElse: () => state.pets.first,
            );
            final goal = pet.recommendedExerciseMinutes;
            final progress = (_elapsed.inMinutes / goal).clamp(0.0, 1.0);
            return Row(
              children: [
                Text('🎯目标',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.sand,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.mint),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(progress * 100).clamp(0, 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mint)),
              ],
            );
          }),
          const SizedBox(height: 10),
          // 按钮组
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.coralLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('⚠️ 不舒服',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.coral)),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _toggleWalk,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sand,
                    foregroundColor: AppColors.text),
                child: const Text('⏹️ 结束', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mintLight,
              border: Border.all(color: AppColors.mintLine),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _elapsed.inMinutes > 0
                  ? '💡 已运动${_elapsed.inMinutes}分钟，记得适时补水'
                  : '💡 出发吧！记得带好拾便袋和水',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mint),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(String label, String value, String unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSoft,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mint)),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(unit,
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textSoft)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐾', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('请先添加宠物', style: TextStyle(color: AppColors.textSoft)),
        ],
      ),
    );
  }
}
