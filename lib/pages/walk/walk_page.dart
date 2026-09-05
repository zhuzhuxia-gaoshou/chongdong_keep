import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../services/app_state.dart';
import '../../services/map_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/tencent_map_widget.dart';
import '../../widgets/local_image.dart';
import '../../models/pet.dart';
import '../../models/exercise_record.dart';
import '../../models/walk_session.dart';
import '../../utils/uuid.dart';
import '../share/share_card_page.dart';
import '../health/emergency_care_page.dart';

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

  /// 启动恢复检查只做一次（等宠物列表异步就绪后在 build 里触发）
  bool _recoveryChecked = false;

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
          color: AppColors.card,
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
                const Text('记录出发时刻？',
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
                        label: const Text('拍一张'),
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

    if (mounted) _startStreams();
  }

  /// 启动GPS流与秒级计时器（开始运动 / 恢复会话共用）
  void _startStreams() {
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
        // 每10秒落盘快照，进程被杀/闪退后可恢复（PRD 4.2.3）
        if (_elapsed.inSeconds % 10 == 0) _persistWalkSession();
      }
    });
  }

  /// 把进行中的运动写入可恢复快照（轨迹超限自动裁头，防体积膨胀）
  void _persistWalkSession() {
    if (_startTime == null) return;
    StorageService.saveWalkSession(WalkSession(
      selectedPetIds: List.of(_selectedPets),
      startTime: _startTime!,
      elapsedSeconds: _elapsed.inSeconds,
      route: List.of(_route),
      distance: _distance,
      steps: _steps,
      locationName: _locationName,
      startPhotoPath: _startPhotoPath,
      currentLat: _currentLat,
      currentLng: _currentLng,
    ));
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
    StorageService.clearWalkSession(); // 已正常结束，快照不再需要

    final shareRecord = _buildAndSaveRecords();
    if (mounted && _elapsed.inMinutes >= 1) {
      _showWalkResult(record: shareRecord);
    }
  }

  /// 按当前选中宠物逐只落库（多宠同遛各记一条），返回分享卡片用的
  /// 第一条记录。
  ExerciseRecord? _buildAndSaveRecords() {
    final state = context.read<AppState>();
    final now = DateTime.now();
    ExerciseRecord? shareRecord;
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
    return shareRecord;
  }

  /// 启动时检测未完成会话（进程被杀/闪退），弹「继续/结束保存/放弃」
  /// （PRD 4.2.3）。会话中宠物已被删除时过滤，全部失效则只能放弃。
  Future<void> _maybeRecoverSession(AppState state) async {
    final session = await StorageService.loadWalkSession();
    if (session == null || !mounted || _isWalking) return;
    final validPets = session.selectedPetIds
        .where((id) => state.pets.any((p) => p.id == id))
        .toList();
    final mins = session.elapsedSeconds ~/ 60;
    final secs = session.elapsedSeconds % 60;

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('发现一条未完成的运动'),
        content: Text(validPets.isEmpty
            ? '已记录 $mins 分 $secs 秒，但本次一起运动的宠物已被删除，无法保存记录哦。'
            : '上次运动被中断，已记录 $mins 分 $secs 秒。要怎么处理呢？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('放弃'),
          ),
          if (validPets.isNotEmpty) ...[
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('结束保存'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'continue'),
              child: const Text('继续'),
            ),
          ],
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'continue' && validPets.isNotEmpty) {
      await _resumeSession(session, validPets);
    } else if (choice == 'save' && validPets.isNotEmpty) {
      _saveRecoveredSession(session, validPets);
    } else {
      StorageService.clearWalkSession();
    }
  }

  /// 恢复字段后直接按已记录时长落库并展示结果面板（不重启GPS）。
  Future<void> _saveRecoveredSession(
      WalkSession s, List<String> petIds) async {
    setState(() {
      _selectedPets
        ..clear()
        ..addAll(petIds);
      _startTime = s.startTime;
      _elapsed = Duration(seconds: s.elapsedSeconds);
      _distance = s.distance;
      _steps = s.steps;
      _route
        ..clear()
        ..addAll(s.route);
      _locationName = s.locationName;
      _startPhotoPath = s.startPhotoPath;
      _currentLat = s.currentLat;
      _currentLng = s.currentLng;
    });
    await StorageService.clearWalkSession();
    if (!mounted) return;
    final shareRecord = _buildAndSaveRecords();
    if (_elapsed.inMinutes >= 1) {
      _showWalkResult(record: shareRecord);
    }
  }

  /// 恢复进行中状态并重启GPS流/计时器。时长从快照续算（进程死亡期间
  /// 的空档不计入）；若期间设备被大幅移动（>200m），旧轨迹封存、新段
  /// 从当前位置重新起绘，避免一条长直线污染路线。
  Future<void> _resumeSession(WalkSession s, List<String> petIds) async {
    setState(() {
      _isWalking = true;
      _selectedPets
        ..clear()
        ..addAll(petIds);
      _startTime =
          DateTime.now().subtract(Duration(seconds: s.elapsedSeconds));
      _elapsed = Duration(seconds: s.elapsedSeconds);
      _distance = s.distance;
      _steps = s.steps;
      _route
        ..clear()
        ..addAll(s.route);
      _locationName = s.locationName;
      _startPhotoPath = s.startPhotoPath;
      _currentLat = s.currentLat;
      _currentLng = s.currentLng;
      _weakGps = false;
      _gpsError = null;
      _lastGoodFixAt = DateTime.now();
    });

    final pos = await MapService.getCurrentPosition();
    if (pos != null && mounted && _isWalking) {
      final fresh = GeoPoint(
        latitude: pos.latitude,
        longitude: pos.longitude,
        timestamp: DateTime.now(),
        accuracy: pos.accuracy,
      );
      final last = _route.isEmpty ? null : _route.last;
      final gap = last == null
          ? 0.0
          : MapService.distanceBetween(
              last.latitude, last.longitude, fresh.latitude, fresh.longitude);
      final bigJump = last != null && gap > MapService.kResumeGapMeters;
      final okPoint =
          last == null || bigJump || !MapService.isAbnormalPoint(last, fresh);
      if (okPoint) {
        setState(() {
          if (bigJump) {
            // 距离已随快照累计，旧轨迹不拼接长直线，从当前位置重新起绘
            _route
              ..clear()
              ..add(fresh);
          } else {
            _route.add(fresh);
          }
          _currentLat = fresh.latitude;
          _currentLng = fresh.longitude;
        });
      }
      _loadLocationName(fresh.latitude, fresh.longitude);
    }
    if (!mounted || !_isWalking) return;
    _startStreams();
    _persistWalkSession(); // 恢复后立即落一次快照
  }

  void _showWalkResult({ExerciseRecord? record}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
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
              const Text('遛狗完成！',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mint)),
              if (_locationName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_locationName,
                    style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
              ],
              // 出发照片回顾
              if (_startPhotoPath != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: buildLocalImage(
                    _startPhotoPath!,
                    height: 140,
                    width: double.infinity,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _resultItem(Icons.timer_rounded, MapService.formatDuration(_elapsed), '时长'),
                  _resultItem(Icons.route_rounded, MapService.formatDistance(_distance), '距离'),
                  _resultItem(Icons.directions_walk_rounded, '$_steps', '步数'),
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
                  child: const Text('今日打卡成功！',
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
                      child: const Text('生成卡片'),
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

  Widget _resultItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.mint),
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

  /// 「宠物不舒服」（PRD 4.5.2）：选症状 → 高风险直跳紧急就医页，
  /// 非高风险建议暂停观察，可选结束保存当前运动。
  Future<void> _onDiscomfort() async {
    final state = context.read<AppState>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('宝贝怎么啦？',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('选一下症状，我来帮你判断要不要就医',
                    style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in const [
                      ('😫', '累了'),
                      ('🤮', '呕吐'),
                      ('😷', '咳嗽'),
                      ('🦴', '瘸了'),
                      ('❓', '其他'),
                    ])
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, s.$2),
                        child: Text('${s.$1} ${s.$2}'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;

    final highRisk = choice == '呕吐' || choice == '瘸了';
    if (highRisk) {
      // 高风险：先停下保存进度再就医，避免一路带着计时
      _stopWalk();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EmergencyCarePage(pet: state.currentPet)));
      return;
    }
    // 非高风险：建议暂停观察，用户可选继续或结束保存
    final stop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('关于「$choice」'),
        content: const Text('先暂停运动休息一下观察，持续的话去医院哦💗\n要结束本次运动并保存记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('继续遛'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('结束并保存'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (stop == true) _stopWalk();
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
    // GPS 遛狗仅针对狗狗；猫咪走首页「陪猫玩」手动记录
    final pets =
        state.pets.where((p) => p.species == PetSpecies.dog).toList();

    // 启动恢复检查：等宠物列表就绪后触发一次（进程被杀场景，PRD 4.2.3）
    if (!_recoveryChecked && !_isWalking && pets.isNotEmpty) {
      _recoveryChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isWalking) _maybeRecoverSession(state);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('运动')),
      body: pets.isEmpty
          ? (state.pets.isEmpty
              ? _buildNoPet()
              : _buildNoDog())
          : _isWalking
              ? _buildWalkingView(state)
              : _buildReadyView(pets, state),
    );
  }

  /// 只养猫的提示：遛狗功能面向狗狗，猫咪引导去「陪猫玩」
  Widget _buildNoDog() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐈', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('GPS 遛狗面向狗狗',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          Text('猫咪的运动去首页「陪猫玩」记录哦',
              style: TextStyle(color: AppColors.textSoft)),
        ],
      ),
    );
  }

  /// 出发准备页（2026-09 重设计）：大头像卡片，一眼分清是哪只狗；
  /// 列表占满剩余空间，按钮文案随选中数量变化。
  Widget _buildReadyView(List<Pet> pets, AppState state) {
    final count = _selectedPets.length;
    final singleName = count == 1
        ? pets
            .where((p) => p.id == _selectedPets.first)
            .firstOrNull
            ?.name ??
            ''
        : '';
    final buttonLabel = count == 0
        ? '选择狗狗后开始'
        : count == 1
            ? '开始遛$singleName'
            : '带$count只宝贝出发';
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('🗺️', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          const Text('准备好出发了吗？',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('点选一起运动的狗狗，可多选',
              style: TextStyle(fontSize: 13, color: AppColors.textSoft)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [for (final pet in pets) _dogCard(pet)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: count == 0 ? null : _toggleWalk,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.pets_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(buttonLabel),
                ]),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('GPS将自动记录路线、距离和步数',
                style: TextStyle(fontSize: 11, color: AppColors.textMute)),
          ),
        ],
      ),
    );
  }

  Widget _dogCard(Pet pet) {
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintLight : AppColors.card,
          borderRadius: BorderRadius.circular(AppDimens.rLg),
          border: Border.all(
              color: isSelected ? AppColors.mint : AppColors.line,
              width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            _petAvatar(pet, selected: isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${pet.breed} · ${pet.speciesEmoji}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSoft)),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 24,
              color: isSelected ? AppColors.mint : AppColors.textMute,
            ),
          ],
        ),
      ),
    );
  }

  /// 宠物头像：优先服务端头像 URL；未设置/加载失败 → 名字首字圆标
  ///（此前清一色物种 emoji，用户分不清是哪只）。
  Widget _petAvatar(Pet pet, {bool selected = false}) {
    final initial =
        pet.name.isNotEmpty ? pet.name.substring(0, 1) : '🐾';
    final url = pet.avatarUrl;
    return Container(
      width: 54,
      height: 54,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.mintLight,
        border: Border.all(
            color: selected ? AppColors.mint : AppColors.line,
            width: selected ? 2 : 1),
      ),
      child: (url != null && url.isNotEmpty)
          ? Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                  child: Text(initial,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mint))))
          : Center(
              child: Text(initial,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mint))),
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
                color: AppColors.warning,
                border: Border.all(color: AppColors.warningText),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _gpsError ?? '定位信号较弱，数据可能有偏差哦',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warningText),
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
                      '距离', MapService.formatDistance(_distance), '')),
              const SizedBox(width: 8),
              Expanded(child: _buildDataCard('步数', '$_steps', '步')),
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
                Text('目标',
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
                onTap: _onDiscomfort,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.coralLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.healing_rounded, size: 14), SizedBox(width: 4), Text('不舒服', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.coral))]),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _toggleWalk,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sand,
                    foregroundColor: AppColors.text),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.stop_rounded, size: 14), SizedBox(width: 4), Text('结束', style: TextStyle(fontSize: 13))]),
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
                  ? '已运动${_elapsed.inMinutes}分钟，记得适时补水'
                  : '出发吧！记得带好拾便袋和水',
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
