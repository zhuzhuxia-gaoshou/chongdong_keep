import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/map_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/nearby_hospitals_section.dart';
import '../../widgets/pressable_scale.dart';
import 'emergency_care_page.dart';

/// 健康安全页（2026-09-15 质感 v2）：
/// 症状九宫格 emoji→Material 图标（图标色=风险级：珊瑚=需就医/琥珀=建议观察/薄荷=一般）；
/// 中间风险色收编 AppColors.amber；急救横幅配方化 coralGradient。
/// 红线自查：GridView 有界 / 无 stretch / 无透明度入场动效。
class HealthSafetyPage extends StatefulWidget {
  const HealthSafetyPage({super.key});

  @override
  State<HealthSafetyPage> createState() => _HealthSafetyPageState();
}

class _HealthSafetyPageState extends State<HealthSafetyPage> {
  String? _selectedSymptom;
  double? _lat;
  double? _lng;
  final GlobalKey _hospitalSectionKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final pos = await MapService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    }
  }

  void _jumpToHospitals() {
    final ctx = _hospitalSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 400), alignment: 0.05);
    }
  }

  void _openEmergencyCare() {
    final pet = context.read<AppState>().currentPet;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => EmergencyCarePage(pet: pet)));
  }

  Color _levelColor(String level) => level == 'high'
      ? AppColors.coral
      : level == 'medium'
          ? AppColors.amber
          : AppColors.mint;

  final List<Map<String, dynamic>> _symptoms = [
    {
      'icon': Icons.sick_rounded,
      'name': '咳嗽/喷嚏',
      'level': 'low',
      'advice': '观察是否有其他症状，多喝水'
    },
    {
      'icon': Icons.no_meals_rounded,
      'name': '呕吐',
      'level': 'medium',
      'advice': '暂停进食2-4小时，保持饮水'
    },
    {
      'icon': Icons.bedtime_rounded,
      'name': '没精神',
      'level': 'low',
      'advice': '观察1-2小时，注意休息'
    },
    {
      'icon': Icons.accessible_rounded,
      'name': '走路瘸',
      'level': 'medium',
      'advice': '减少活动，观察是否有外伤'
    },
    {
      'icon': Icons.bolt_rounded,
      'name': '抽搐',
      'level': 'high',
      'advice': '⚠️ 建议立即就医！保持冷静，不要强行按压'
    },
    {
      'icon': Icons.no_food_rounded,
      'name': '不吃东西',
      'level': 'medium',
      'advice': '检查食物是否变质，换新鲜食物试试'
    },
    {
      'icon': Icons.water_drop_rounded,
      'name': '喝很多水',
      'level': 'low',
      'advice': '观察是否有其他异常，可能只是天气热'
    },
    {
      'icon': Icons.bloodtype_rounded,
      'name': '出血',
      'level': 'high',
      'advice': '⚠️ 建议立即就医！避免移动，注意保暖'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('健康安全')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimens.sp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyBanner(),
            const SizedBox(height: AppDimens.sp20),
            const Text('症状自查',
                style: TextStyle(
                    fontSize: AppDimens.fsHeadline,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimens.sp4),
            const Text('选择宠物出现的症状，获取专业建议',
                style:
                    TextStyle(fontSize: AppDimens.fsFoot, color: AppColors.textSoft)),
            const SizedBox(height: AppDimens.sp16),
            _buildSymptomsGrid(),
            const SizedBox(height: AppDimens.sp20),
            if (_selectedSymptom != null) _buildSymptomDetail(),
            const SizedBox(height: AppDimens.sp20),
            _buildNearbyHospitals(),
            const SizedBox(height: AppDimens.sp20),
            _buildHealthTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sp16),
      decoration: BoxDecoration(
        gradient: AppColors.coralGradient,
        borderRadius: BorderRadius.circular(AppDimens.rLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency_rounded,
              size: 30, color: AppColors.onAccent),
          const SizedBox(width: AppDimens.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('紧急情况？',
                    style: TextStyle(
                        fontSize: AppDimens.fsSub,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                const Text('抽搐/中毒/严重外伤请立即就医',
                    style: TextStyle(
                        fontSize: AppDimens.fsCaption, color: Colors.white70)),
                const SizedBox(height: AppDimens.sp8),
                Row(
                  children: [
                    PressableScale(
                      onTap: _openEmergencyCare,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.sp12, vertical: AppDimens.sp4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimens.rSm),
                        ),
                        child: const Text('就医协助',
                            style: TextStyle(
                                fontSize: AppDimens.fsCaption,
                                fontWeight: FontWeight.w700,
                                color: AppColors.coral)),
                      ),
                    ),
                    const SizedBox(width: AppDimens.sp8),
                    PressableScale(
                      onTap: _jumpToHospitals,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.sp12, vertical: AppDimens.sp4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius:
                              BorderRadius.circular(AppDimens.rSm),
                        ),
                        child: const Text('附近医院',
                            style: TextStyle(
                                fontSize: AppDimens.fsCaption,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppDimens.sp8,
        mainAxisSpacing: AppDimens.sp8,
      ),
      itemCount: _symptoms.length,
      itemBuilder: (context, index) {
        final symptom = _symptoms[index];
        final isSelected = _selectedSymptom == symptom['name'];
        final levelColor = _levelColor(symptom['level'] as String);
        return PressableScale(
          onTap: () {
            setState(() {
              _selectedSymptom = isSelected ? null : symptom['name'] as String;
            });
          },
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    // 选中：tonal 平面卡 + 风险色描边（质感规则：tonal 不加影）
                    color: levelColor.withValues(alpha: 0.15),
                    border: Border.all(color: levelColor, width: 2),
                    borderRadius: BorderRadius.circular(AppDimens.rMd),
                  )
                : AppDimens.cardBox(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: levelColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(symptom['icon'] as IconData,
                      size: AppDimens.iconLg, color: levelColor),
                ),
                const SizedBox(height: AppDimens.sp8),
                Text(
                  symptom['name'] as String,
                  style: TextStyle(
                      fontSize: AppDimens.fsCaption,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? levelColor : AppColors.text),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymptomDetail() {
    final symptom = _symptoms.firstWhere((s) => s['name'] == _selectedSymptom);
    final level = symptom['level'] as String;
    final levelText = level == 'high'
        ? '需要就医'
        : level == 'medium'
            ? '建议观察'
            : '一般情况';
    final levelColor = _levelColor(level);

    return Container(
      padding: const EdgeInsets.all(AppDimens.sp16),
      decoration: AppDimens.cardBox(borderColor: levelColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.sp8, vertical: AppDimens.sp4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimens.rXs),
                ),
                child: Text(levelText,
                    style: TextStyle(
                        fontSize: AppDimens.fsCaption,
                        fontWeight: FontWeight.w700,
                        color: levelColor)),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sp12),
          Text(symptom['advice'] as String,
              style: const TextStyle(
                  fontSize: AppDimens.fsBodyMid,
                  fontWeight: FontWeight.w600,
                  height: 1.5)),
          const SizedBox(height: AppDimens.sp12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _jumpToHospitals,
                  icon: const Icon(Icons.place_rounded, size: AppDimens.iconSm),
                  label: const Text('附近医院'),
                ),
              ),
              const SizedBox(width: AppDimens.sp8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _openEmergencyCare,
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          level == 'high' ? AppColors.coral : AppColors.mint),
                  child: Text(level == 'high' ? '立即就医' : '就医协助'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyHospitals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: _hospitalSectionKey,
      children: [
        if (_lat != null && _lng != null)
          NearbyHospitalsSection(wgsLat: _lat!, wgsLng: _lng!)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.sp12),
            decoration: AppDimens.cardBox(borderColor: AppColors.line),
            child: const Text('正在获取当前位置以查找附近医院…\n可检查定位权限后下拉稍候',
                style: TextStyle(
                    fontSize: AppDimens.fsFoot,
                    color: AppColors.textSoft,
                    height: 1.5)),
          ),
      ],
    );
  }

  Widget _buildHealthTips() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sp16),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        borderRadius: BorderRadius.circular(AppDimens.rMd),
        border: Border.all(color: AppColors.mintLine),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: AppDimens.iconSm, color: AppColors.mint),
              SizedBox(width: AppDimens.sp8),
              Text('温馨提示',
                  style: TextStyle(
                      fontSize: AppDimens.fsFoot,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mint)),
            ],
          ),
          SizedBox(height: AppDimens.sp8),
          Text(
            '本功能提供的信息仅供参考，不能替代兽医诊断。如宠物出现严重症状，请及时就医。',
            style: TextStyle(
                fontSize: AppDimens.fsCaption,
                color: AppColors.textSoft,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}
