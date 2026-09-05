import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pet.dart';
import '../../services/api_config.dart';
import '../../services/app_state.dart';
import '../../services/map_service.dart';
import '../../services/storage_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/user_avatar.dart';
import '../calendar/checkin_calendar_page.dart';
import '../cat/cat_play_page.dart';
import '../pet/add_pet_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// 常用城市列表（手动选择天气位置用）
const _kCities = [
  ('北京', 39.9042, 116.4074),
  ('上海', 31.2304, 121.4737),
  ('广州', 23.1291, 113.2644),
  ('深圳', 22.5431, 114.0579),
  ('杭州', 30.2741, 120.1551),
  ('成都', 30.5728, 104.0668),
  ('重庆', 29.5630, 106.5516),
  ('武汉', 30.5928, 114.3055),
  ('西安', 34.3416, 108.9398),
  ('南京', 32.0603, 118.7969),
  ('天津', 39.3434, 117.3616),
  ('长沙', 28.2282, 112.9388),
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
      // 尝试获取真实 GPS 定位
      final position = await MapService.getCurrentPosition();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      }
    }

    final weather = await WeatherService.getWeatherByLocation(lat, lng);
    if (!mounted) return;
    setState(() {
      _weather = weather;
      _manualCity = manualCity;
      _loadingWeather = false;
    });
  }

  /// 天气位置选择弹窗：恢复定位 / 选择常用城市。
  void _showLocationPicker() {
    AppBottomSheet.show<void>(
      context,
      title: '选择天气位置',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await StorageService.clearWeatherLocation();
                _loadWeather();
              },
              icon: const Icon(Icons.my_location, size: AppDimens.fsSub),
              label: const Text('使用当前定位'),
            ),
          ),
          const SizedBox(height: AppDimens.sp12),
          Text(
            '或选择常用城市',
            style: const TextStyle(
              fontSize: AppDimens.fsCaption,
              color: AppColors.textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimens.sp8),
          Wrap(
            spacing: AppDimens.sp8,
            runSpacing: AppDimens.sp8,
            children: _kCities.map((city) {
              final name = city.$1;
              final isSelected = _manualCity == name;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await StorageService.saveWeatherLocation(
                      name,
                      city.$2,
                      city.$3,
                    );
                    _loadWeather();
                  },
                  borderRadius: BorderRadius.circular(AppDimens.rFull),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.sp12,
                      vertical: AppDimens.sp8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.mintLight : AppColors.sand,
                      border: Border.all(
                        color: isSelected ? AppColors.mint : AppColors.line,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppDimens.rFull),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: AppDimens.fsFoot,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.mint : AppColors.text,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
                onRefresh: _loadWeather,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.sp16,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(state),
                      const SizedBox(height: AppDimens.sp12),
                      _buildWeatherCard(),
                      const SizedBox(height: AppDimens.sp12),
                      _buildPetGoalCard(pet, state),
                      const SizedBox(height: AppDimens.sp12),
                      _buildStreakCard(state),
                      const SizedBox(height: AppDimens.sp12),
                      _buildStartButton(context, pet),
                      const SizedBox(height: AppDimens.sp8),
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
    final greeting = hour < 6
        ? '凌晨好'
        : hour < 12
            ? '早上好'
            : hour < 14
                ? '中午好'
                : hour < 18
                    ? '下午好'
                    : '晚上好';
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.sp8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 统一头像组件：兼容 emoji/本地路径/网络 URL 三态
              UserAvatar(
                url: state.user?.avatarUrl,
                radius: AppDimens.sp20,
                fallbackEmoji: '👩',
              ),
              const SizedBox(width: AppDimens.sp8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: AppDimens.fsFoot,
                          color: AppColors.textSoft,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // 仅 Mock 模式可见的环境角标（联调防呆）
                      if (ApiConfig.isMock) ...[
                        const SizedBox(width: AppDimens.sp4),
                        const MockDevBadge(),
                      ],
                    ],
                  ),
                  Text(
                    state.user?.nickname ?? '铲屎官',
                    style: const TextStyle(
                      fontSize: AppDimens.fsSub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('消息中心即将开放，敬请期待')),
            ),
            child: Container(
              width: AppDimens.sp40,
              height: AppDimens.sp40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
                border: Border.all(color: AppColors.line),
              ),
              child: const Center(
                child: Icon(Icons.notifications_none_rounded,
                    size: 20, color: AppColors.textSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    final weather = _weather;
    final hasWarning = weather?.warning != null;
    final cardColor = hasWarning ? AppColors.coralLight : AppColors.sky;
    final borderColor = hasWarning ? AppColors.coralLine : AppColors.skyLine;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showLocationPicker,
        borderRadius: BorderRadius.circular(AppDimens.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.sp16),
          decoration: AppDimens.cardBox(
            color: cardColor,
            borderColor: borderColor,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _manualCity ?? weather?.cityName ?? '定位中...',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: AppDimens.fsCaption,
                                  color: AppColors.textSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_loadingWeather)
                              Container(
                                width: AppDimens.fsMicro,
                                height: AppDimens.fsMicro,
                                margin: const EdgeInsets.only(
                                  left: AppDimens.sp4,
                                ),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.textSoft,
                                ),
                              )
                            else ...[
                              const SizedBox(width: AppDimens.sp4),
                              const Icon(
                                Icons.swap_horiz,
                                size: AppDimens.fsFoot,
                                color: AppColors.textMute,
                              ),
                              const Text(
                                ' 切换',
                                style: TextStyle(
                                  fontSize: AppDimens.fsMicro,
                                  color: AppColors.textMute,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppDimens.sp4),
                        Text(
                          '${weather?.temperature ?? '--'}°C ${weather?.condition ?? ''} · ${weather?.isGoodForWalk == true ? '适合遛狗' : '建议室内'}',
                          style: const TextStyle(
                            fontSize: AppDimens.fsBody,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    weather?.conditionIcon ?? '🌤️',
                    style: const TextStyle(fontSize: 28),
                  ),
                ],
              ),
              if (weather != null) ...[
                const SizedBox(height: AppDimens.sp8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.sp12,
                    vertical: AppDimens.sp8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mintLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppDimens.rSm),
                  ),
                  child: Text(
                    weather.walkAdvice,
                    style: const TextStyle(
                      fontSize: AppDimens.fsCaption,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mint,
                    ),
                  ),
                ),
              ],
              if (hasWarning) ...[
                const SizedBox(height: AppDimens.sp8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.sp12,
                    vertical: AppDimens.sp8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.coralLight.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppDimens.rSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppColors.coral),
                      const SizedBox(width: AppDimens.sp4),
                      Flexible(
                        child: Text(
                          weather!.warning!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppDimens.fsCaption,
                            fontWeight: FontWeight.w700,
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.sp8),
                      Flexible(
                        child: Text(
                          weather.warning!.advice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: AppDimens.fsMicro,
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetGoalCard(Pet pet, AppState state) {
    final todayMinutes = state.getTodayExerciseMinutes(pet.id);
    final goalMinutes = pet.recommendedExerciseMinutes;
    final progress = (todayMinutes / goalMinutes).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppDimens.sp16),
      decoration: AppDimens.cardBox(borderColor: AppColors.line),
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
                child: Center(
                  child: Text(
                    pet.speciesEmoji,
                    style: const TextStyle(fontSize: AppDimens.sp24),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pet.name} · ${pet.breed} ${pet.ageYears}岁',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppDimens.fsSub,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '基础目标 $goalMinutes分钟 · 体重 ${pet.weight}kg',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppDimens.fsCaption,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sp12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日进度',
                style: TextStyle(
                  fontSize: AppDimens.fsCaption,
                  color: AppColors.textSoft,
                ),
              ),
              Text(
                '$todayMinutes分 / $goalMinutes分钟',
                style: const TextStyle(
                  fontSize: AppDimens.fsFoot,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sp8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.rFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: AppDimens.sp8,
            ),
          ),
          const SizedBox(height: AppDimens.sp12),
          Row(
            children: [
              Expanded(
                child: _buildGoalChip(
                  '基础目标',
                  '$goalMinutes分',
                  progress >= 1 ? '已达成' : '进行中',
                  AppColors.mintLight,
                  AppColors.mint,
                ),
              ),
              const SizedBox(width: AppDimens.sp8),
              Expanded(
                child: _buildGoalChip(
                  '建议目标',
                  '${(goalMinutes * 0.8).toInt()}分',
                  '今天忙',
                  AppColors.sky,
                  AppColors.skyDeep,
                ),
              ),
              const SizedBox(width: AppDimens.sp8),
              Expanded(
                child: _buildGoalChip(
                  '挑战目标',
                  '${(goalMinutes * 1.2).toInt()}分',
                  '冲榜',
                  AppColors.coralLight,
                  AppColors.coral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChip(
    String label,
    String value,
    String hint,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sp4,
        vertical: AppDimens.sp8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimens.rMd),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppDimens.fsMicro,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
          const SizedBox(height: AppDimens.sp4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppDimens.fsMicro,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
          const SizedBox(height: AppDimens.sp4),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppDimens.fsMicro,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sp16,
        vertical: AppDimens.sp12,
      ),
      decoration: AppDimens.cardBox(
        color: AppColors.mintLight,
        borderColor: AppColors.mintLine,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '连续打卡',
                style: TextStyle(
                  fontSize: AppDimens.fsCaption,
                  color: AppColors.textSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimens.sp4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${state.user?.streakDays ?? 0}',
                    style: const TextStyle(
                      fontSize: AppDimens.fsStat,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mint,
                    ),
                  ),
                  const SizedBox(width: AppDimens.sp4),
                  const Text(
                    '天',
                    style: TextStyle(
                      fontSize: AppDimens.fsBody,
                      color: AppColors.mint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
            ),
            child: const Center(
              child: Icon(Icons.local_fire_department_rounded,
                  size: 24, color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, Pet pet) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.read<AppState>().setIndex(1),
        icon: const Icon(Icons.pets_rounded, size: 18),
        label: Text('开始遛${pet.name}'),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            label: '陪猫玩',
            icon: Icons.sports_esports_rounded,
            color: AppColors.sand,
            borderColor: AppColors.line,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CatPlayPage()),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.sp8),
        Expanded(
          child: _QuickAction(
            label: '打卡日历',
            icon: Icons.calendar_month_rounded,
            color: AppColors.coralLight,
            borderColor: AppColors.coralLine,
            foregroundColor: AppColors.coral,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckInCalendarPage()),
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
          const SizedBox(height: AppDimens.sp16),
          const Text(
            '还没有添加宠物',
            style: TextStyle(
              fontSize: AppDimens.fsHeadline,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppDimens.sp8),
          const Text(
            '添加你的宝贝，开始运动打卡吧',
            style: TextStyle(
              fontSize: AppDimens.fsBody,
              color: AppColors.textSoft,
            ),
          ),
          const SizedBox(height: AppDimens.sp24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPetPage()),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('添加宠物'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.foregroundColor = AppColors.text,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.sp12),
          decoration: AppDimens.cardBox(color: color, borderColor: borderColor),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: foregroundColor),
                const SizedBox(width: AppDimens.sp8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppDimens.fsFoot,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
