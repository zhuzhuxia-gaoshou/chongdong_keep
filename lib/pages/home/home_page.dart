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
import '../../theme/app_theme.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/user_avatar.dart';
import '../calendar/checkin_calendar_page.dart';
import '../cat/cat_play_page.dart';
import '../pet/add_pet_page.dart';
import '../report/weekly_report_page.dart';

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
  String? _selectedPetId; // 首页展示的宠物，null = 第一只

  // 注意：此处曾有「整页上滑淡入」入场动效，真机上动画未推进导致
  // FadeTransition 停在透明度 0、整页空白（2026-09-13 事故），已移除。
  // 教训：内容可见性绝不允许依赖动画推进；透明度类装饰动效一律不做。

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
              icon: const Icon(Icons.my_location_rounded, size: AppDimens.fsSub),
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
    final pet = state.pets
            .where((p) => p.id == _selectedPetId)
            .firstOrNull ??
        state.currentPet;

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
                      _buildExerciseEntries(context, pet),
                      const SizedBox(height: AppDimens.sp8),
                      _buildQuickActions(context),
                      const SizedBox(height: 96), // 悬浮 Dock 遮挡区
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('消息中心即将开放，敬请期待哦')),
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
                    size: AppDimens.iconMd, color: AppColors.textSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 多宠切换底部弹窗：选择首页展示的宠物（D2-6 收编 AppBottomSheet 品牌壳）
  void _showPetPicker(BuildContext context, AppState state) {
    final effectiveId =
        _selectedPetId ?? state.currentPet?.id;
    AppBottomSheet.show<void>(
      context,
      title: '选择要查看的宠物',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in state.pets)
            ListTile(
              leading:
                  Text(p.speciesEmoji, style: const TextStyle(fontSize: 22)),
              title: Text(p.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(p.breed),
              trailing: p.id == effectiveId
                  ? const Icon(Icons.check_rounded, color: AppColors.mint)
                  : null,
              onTap: () {
                setState(() => _selectedPetId = p.id);
                Navigator.pop(ctx);
              },
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
                                Icons.swap_horiz_rounded,
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

  /// 今日目标 Hero 卡：全 App 唯一的大胆元素（质感原则「唯一主角」）。
  /// 薄荷渐变 + 大号细体数字 + 白色进度轨道；原三档目标 chip 移除（克制原则）。
  Widget _buildPetGoalCard(Pet pet, AppState state) {
    final todayMinutes = state.getTodayExerciseMinutes(pet.id);
    final goalMinutes = pet.recommendedExerciseMinutes;
    final progress = (todayMinutes / goalMinutes).clamp(0.0, 1.0);
    final reached = todayMinutes >= goalMinutes;

    return Container(
      padding: const EdgeInsets.all(AppDimens.sp20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mint, AppColors.mintDeep],
        ),
        borderRadius: BorderRadius.circular(AppDimens.rXl),
        // 落地影从 mintDeep token 派生（20%），主色若调、投影随动（D2-1）
        boxShadow: [
          BoxShadow(
            color: AppColors.mintDeep.withValues(alpha: 0.20),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -22,
            child: Text(
              pet.speciesEmoji,
              style: TextStyle(
                fontSize: 96,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _heroAvatar(pet),
                  const SizedBox(width: AppDimens.sp12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppDimens.fsSub,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pet.breed} · ${pet.ageYears}岁',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppDimens.fsCaption,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.pets.length > 1)
                    GestureDetector(
                      onTap: () => _showPetPicker(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.sp8, vertical: AppDimens.sp4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppDimens.rFull),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 2),
                            Text('切换',
                                style: TextStyle(
                                    fontSize: AppDimens.fsMicro,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.sp24),
              Text(
                '今日进度 · 基础目标 $goalMinutes 分钟',
                style: TextStyle(
                  fontSize: AppDimens.fsCaption,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: AppDimens.sp4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$todayMinutes',
                      style: AppText.numericHero(color: Colors.white)),
                  const SizedBox(width: AppDimens.sp8),
                  const Text('分钟',
                      style: TextStyle(
                          fontSize: AppDimens.fsBody,
                          color: Colors.white70)),
                  const Spacer(),
                  if (reached)
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: AppDimens.iconSm, color: Colors.white),
                        SizedBox(width: 4),
                        Text('已达成',
                            style: TextStyle(
                                fontSize: AppDimens.fsFoot,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    )
                  else
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: AppDimens.fsBodyMid,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.sp12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.rFull),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.24),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Hero 卡头像：白圈托底，与渐变形成清透对比
  Widget _heroAvatar(Pet pet) {
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: pet.avatarUrl != null
          ? Image.network(
              pet.avatarUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(pet.speciesEmoji,
                    style: const TextStyle(fontSize: AppDimens.sp24)),
              ),
            )
          : Center(
              child: Text(pet.speciesEmoji,
                  style: const TextStyle(fontSize: AppDimens.sp24)),
            ),
    );
  }

  Widget _buildStreakCard(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sp16,
        vertical: AppDimens.sp12,
      ),
      // 白卡+投影（Hero 之后的次级元素，安静克制）
      decoration: AppDimens.cardBox(),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppDimens.sp4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${state.user?.streakDays ?? 0}',
                      style: AppText.numericSection(color: AppColors.mint)),
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
              color: AppColors.coralLight,
            ),
            child: const Center(
              child: Icon(Icons.local_fire_department_rounded,
                  size: AppDimens.iconLg, color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  /// 两个平等的运动入口（2026-09 用户指定：遛狗与陪猫玩同级，猫不显示"开始遛"）：
  /// - 当前是狗 →「开始遛{name}」/「陪猫玩」
  /// - 当前是猫 →「开始遛狗」/「陪{name}玩」
  Widget _buildExerciseEntries(BuildContext context, Pet pet) {
    final isDog = pet.species == PetSpecies.dog;
    // 勿用 CrossAxisAlignment.stretch：本 Row 处于滚动视图的无界高度环境，
    // stretch 会把无限高度传给子级导致渲染崩溃（真机红屏事故根因）。
    // 两卡片内容结构一致，默认高度天然相同。
    return Row(
      children: [
        Expanded(
          child: PressableScale(
            onTap: () => context.read<AppState>().setIndex(1),
            child: _exerciseEntry(
              icon: Icons.pets_rounded,
              iconBg: AppColors.mintLight,
              iconColor: AppColors.mint,
              title: isDog ? '开始遛${pet.name}' : '开始遛狗',
              subtitle: 'GPS 轨迹记录',
            ),
          ),
        ),
        const SizedBox(width: AppDimens.sp8),
        Expanded(
          child: PressableScale(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CatPlayPage())),
            child: _exerciseEntry(
              icon: Icons.sports_esports_rounded,
              iconBg: AppColors.coralLight,
              iconColor: AppColors.coral,
              title: isDog ? '陪猫玩' : '陪${pet.name}玩',
              subtitle: '互动打卡',
            ),
          ),
        ),
      ],
    );
  }

  Widget _exerciseEntry({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sp12),
      decoration: AppDimens.cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
            child: Center(child: Icon(icon, size: AppDimens.iconMd, color: iconColor)),
          ),
          const SizedBox(height: AppDimens.sp8),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: AppDimens.fsBodyMid, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSoft)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
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
        const SizedBox(width: AppDimens.sp8),
        Expanded(
          child: _QuickAction(
            label: '运动周报',
            icon: Icons.auto_graph_rounded,
            color: AppColors.sky,
            borderColor: AppColors.line,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeeklyReportPage()),
            ),
          ),
        ),
      ],
    );
  }

  /// 无宠物空态（D1-8 收编为品牌 EmptyState；SafeArea 内 body 有界，Center 安全）
  Widget _buildNoPet(BuildContext context) {
    return Center(
      child: EmptyState(
        emoji: '🐾',
        title: '还没有添加宠物',
        message: '添加你的宝贝，开始运动打卡吧',
        actionLabel: '添加宠物',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPetPage()),
        ),
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
                Icon(icon, size: AppDimens.iconSm, color: foregroundColor),
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
