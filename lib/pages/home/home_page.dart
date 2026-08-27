import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../services/api_config.dart';
import '../../services/app_state.dart';
import '../../services/storage_service.dart';
import '../../services/weather_service.dart';
import '../../services/map_service.dart';
import '../../models/pet.dart';
import '../../widgets/user_avatar.dart';
import '../cat/cat_play_page.dart';
import '../calendar/checkin_calendar_page.dart';
import '../pet/add_pet_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// 常用城市列表（手动选择天气位置用）
const _kCities = [
  ('北京', 39.9042, 116.4074), ('上海', 31.2304, 121.4737),
  ('广州', 23.1291, 113.2644), ('深圳', 22.5431, 114.0579),
  ('杭州', 30.2741, 120.1551), ('成都', 30.5728, 104.0668),
  ('重庆', 29.5630, 106.5516), ('武汉', 30.5928, 114.3055),
  ('西安', 34.3416, 108.9398), ('南京', 32.0603, 118.7969),
  ('天津', 39.3434, 117.3616), ('长沙', 28.2282, 112.9388),
];

class _HomePageState extends State<HomePage> {
  WeatherData? _weather;
  bool _loadingWeather = false;
  String? _manualCity; // 手动选择的城市名，null = 跟随定位

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _loadingWeather = true);
    double lat = 39.9; // 默认北京
    double lng = 116.4;
    String? manualCity;

    // 优先使用用户手动选择的位置
    final manual = await StorageService.loadWeatherLocation();
    if (manual != null) {
      lat = (manual['lat'] as num).toDouble();
      lng = (manual['lng'] as num).toDouble();
      manualCity = manual['name'] as String?;
    } else {
      // 尝试获取真实GPS定位
      final position = await MapService.getCurrentPosition();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      }
    }

    final weather = await WeatherService.getWeatherByLocation(lat, lng);
    if (mounted) {
      setState(() {
        _weather = weather;
        _manualCity = manualCity;
        _loadingWeather = false;
      });
    }
  }

  /// 天气位置选择弹窗：恢复定位 / 选择常用城市
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('🌤️ 选择天气位置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await StorageService.clearWeatherLocation();
                      _loadWeather();
                    },
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('使用当前定位'),
                  ),
                ),
                const SizedBox(height: 12),
                Text('或选择常用城市', style: TextStyle(fontSize: 11, color: AppColors.textSoft, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kCities.map((city) {
                    final name = city.$1;
                    final isSelected = _manualCity == name;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await StorageService.saveWeatherLocation(name, city.$2, city.$3);
                        _loadWeather();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.mintLight : AppColors.sand,
                          border: Border.all(color: isSelected ? AppColors.mint : AppColors.line, width: isSelected ? 1.5 : 1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.mint : AppColors.text)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pet = state.currentPet;

    return Scaffold(
      body: SafeArea(
        child: pet == null
          ? _buildNoPet(context)
          : RefreshIndicator(
              onRefresh: () async => _loadWeather(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildHeader(state),
                    const SizedBox(height: 12),
                    _buildWeatherCard(),
                    const SizedBox(height: 12),
                    _buildPetGoalCard(context, pet, state),
                    const SizedBox(height: 12),
                    _buildStreakCard(state),
                    const SizedBox(height: 12),
                    _buildStartButton(context, pet),
                    const SizedBox(height: 10),
                    _buildQuickActions(context),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    final hour = DateTime.now().hour;
    final greeting = hour < 6 ? '凌晨好' : hour < 12 ? '早上好' : hour < 14 ? '中午好' : hour < 18 ? '下午好' : '晚上好';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 统一头像组件：兼容 emoji/本地路径/网络 URL 三态
              UserAvatar(url: state.user?.avatarUrl, radius: 20, fallbackEmoji: '👩'),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(greeting, style: TextStyle(fontSize: 12, color: AppColors.textSoft, fontWeight: FontWeight.w500)),
                      // 仅 Mock 模式可见的环境角标（联调防呆）
                      if (ApiConfig.isMock) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('MOCK',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8A6D3B))),
                        ),
                      ],
                    ],
                  ),
                  Text(state.user?.nickname ?? '铲屎官', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.line),
            ),
            child: const Center(child: Text('🔔', style: TextStyle(fontSize: 15))),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    final w = _weather;
    
    // 有预警时的特殊样式
    final hasWarning = w?.warning != null;
    final cardColor = hasWarning ? AppColors.coralLight : AppColors.sky;
    final borderColor = hasWarning ? const Color(0xFFFFD9C8) : const Color(0xFFD4E8F7);

    return GestureDetector(
      onTap: _showLocationPicker,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _manualCity ?? w?.cityName ?? '定位中...',
                              style: TextStyle(fontSize: 11, color: AppColors.textSoft, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_loadingWeather)
                            Container(
                              width: 10, height: 10,
                              margin: const EdgeInsets.only(left: 6),
                              child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textSoft),
                            )
                          else ...[
                            const SizedBox(width: 6),
                            Icon(Icons.swap_horiz, size: 12, color: AppColors.textMute),
                            Text(' 切换', style: TextStyle(fontSize: 9, color: AppColors.textMute)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${w?.temperature ?? '--'}°C ${w?.condition ?? ''} · ${w?.isGoodForWalk == true ? '适合遛狗' : '建议室内'}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Text(w?.conditionIcon ?? '🌤️', style: const TextStyle(fontSize: 28)),
              ],
            ),
            // 运动建议
            if (w != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mintLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 ${w.walkAdvice}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mint),
                ),
              ),
            ],
            // 预警提示
            if (hasWarning) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.coralLight.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('⚠️ ${w!.warning!.title}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.coral)),
                    const Spacer(),
                    Text(w.warning!.advice, style: TextStyle(fontSize: 10, color: AppColors.coral)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPetGoalCard(BuildContext context, Pet pet, AppState state) {
    final todayMinutes = state.getTodayExerciseMinutes(pet.id);
    final goalMinutes = pet.recommendedExerciseMinutes;
    final progress = (todayMinutes / goalMinutes).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mintLight,
                    border: Border.all(color: AppColors.mint, width: 2),
                  ),
                  child: Center(child: Text(pet.speciesEmoji, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pet.name} · ${pet.breed} ${pet.ageYears}岁', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('基础目标 $goalMinutes分钟 · 体重 ${pet.weight}kg', style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('今日进度', style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
                Text('$todayMinutes分 / $goalMinutes分钟',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mint)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.sand,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mint),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildGoalChip('🎯基础', '$goalMinutes分', progress >= 1 ? '✅已达成' : '进行中', AppColors.mintLight, AppColors.mint)),
                const SizedBox(width: 6),
                Expanded(child: _buildGoalChip('💡建议', '${(goalMinutes * 0.8).toInt()}分', '今天忙', AppColors.sky, AppColors.skyDeep)),
                const SizedBox(width: 6),
                Expanded(child: _buildGoalChip('🏆挑战', '${(goalMinutes * 1.2).toInt()}分', '冲榜', AppColors.coralLight, AppColors.coral)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalChip(String label, String value, String hint, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text('$label\n$value\n$hint', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg, height: 1.3), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStreakCard(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        border: Border.all(color: const Color(0xFFD0E9DC)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('连续打卡', style: TextStyle(fontSize: 11, color: AppColors.textSoft, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${state.user?.streakDays ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.mint)),
                  const SizedBox(width: 2),
                  Text('天', style: TextStyle(fontSize: 13, color: AppColors.mint)),
                ],
              ),
            ],
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.card),
            child: const Center(child: Text('🏅', style: TextStyle(fontSize: 22))),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, Pet pet) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<AppState>().setIndex(1);
        },
        child: Text('🐾 开始遛${pet.name}'),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatPlayPage())),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sand,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('🐈 陪猫玩', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInCalendarPage())),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.coralLight,
                border: Border.all(color: const Color(0xFFFFD9C8)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('📅 打卡日历', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.coral))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPet(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐾', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('还没有添加宠物', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          Text('添加你的宝贝，开始运动打卡吧', style: TextStyle(fontSize: 13, color: AppColors.textSoft)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage())),
            child: const Text('➕ 添加宠物'),
          ),
        ],
      ),
    );
  }
}
