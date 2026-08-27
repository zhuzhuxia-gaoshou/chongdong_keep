import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class HealthSafetyPage extends StatefulWidget {
  const HealthSafetyPage({super.key});

  @override
  State<HealthSafetyPage> createState() => _HealthSafetyPageState();
}

class _HealthSafetyPageState extends State<HealthSafetyPage> {
  String? _selectedSymptom;

  final List<Map<String, dynamic>> _symptoms = [
    {'icon': '😷', 'name': '咳嗽/喷嚏', 'level': 'low', 'advice': '观察是否有其他症状，多喝水'},
    {'icon': '🤢', 'name': '呕吐', 'level': 'medium', 'advice': '暂停进食2-4小时，保持饮水'},
    {'icon': '💤', 'name': '没精神', 'level': 'low', 'advice': '观察1-2小时，注意休息'},
    {'icon': '🦴', 'name': '走路瘸', 'level': 'medium', 'advice': '减少活动，观察是否有外伤'},
    {'icon': '😵', 'name': '抽搐', 'level': 'high', 'advice': '⚠️ 建议立即就医！保持冷静，不要强行按压'},
    {'icon': '🚫', 'name': '不吃东西', 'level': 'medium', 'advice': '检查食物是否变质，换新鲜食物试试'},
    {'icon': '💧', 'name': '喝很多水', 'level': 'low', 'advice': '观察是否有其他异常，可能只是天气热'},
    {'icon': '🩸', 'name': '出血', 'level': 'high', 'advice': '⚠️ 建议立即就医！避免移动，注意保暖'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('健康安全')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyBanner(),
            const SizedBox(height: 20),
            const Text('症状自查', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('选择宠物出现的症状，获取专业建议', style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
            const SizedBox(height: 14),
            _buildSymptomsGrid(),
            const SizedBox(height: 20),
            if (_selectedSymptom != null) _buildSymptomDetail(),
            const SizedBox(height: 20),
            _buildNearbyHospitals(),
            const SizedBox(height: 20),
            _buildHealthTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF8A65), Color(0xFFFF6B6B)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🚨', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('紧急情况？', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                const Text('抽搐/中毒/严重外伤请立即就医', style: TextStyle(fontSize: 11, color: Colors.white70)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('📞 呼叫医院', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.coral)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('📍 附近医院', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
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
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _symptoms.length,
      itemBuilder: (context, index) {
        final symptom = _symptoms[index];
        final isSelected = _selectedSymptom == symptom['name'];
        final levelColor = symptom['level'] == 'high'
            ? AppColors.coral
            : symptom['level'] == 'medium'
                ? const Color(0xFFFFB74D)
                : AppColors.mint;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSymptom = isSelected ? null : symptom['name'] as String;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? levelColor.withValues(alpha: 0.15) : AppColors.card,
              border: Border.all(color: isSelected ? levelColor : AppColors.line, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(symptom['icon'] as String, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  symptom['name'] as String,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? levelColor : AppColors.text),
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
    final levelText = level == 'high' ? '需要就医' : level == 'medium' ? '建议观察' : '一般情况';
    final levelColor = level == 'high' ? AppColors.coral : level == 'medium' ? const Color(0xFFFFB74D) : AppColors.mint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: levelColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(levelText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: levelColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('💡 ${symptom['advice']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('查看兽医建议'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: levelColor),
                  child: const Text('附近医院'),
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
      children: [
        const Text('附近宠物医院', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _buildHospitalItem('新瑞鹏宠物医院', '1.2km', '24小时急诊', true),
        const SizedBox(height: 8),
        _buildHospitalItem('瑞鹏动物医院', '2.5km', '9:00-22:00', false),
        const SizedBox(height: 8),
        _buildHospitalItem('宠爱动物诊所', '3.8km', '8:30-20:00', false),
      ],
    );
  }

  Widget _buildHospitalItem(String name, String distance, String hours, bool isEmergency) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEmergency ? AppColors.coralLight : AppColors.mintLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(isEmergency ? '🏥' : '🏪', style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (isEmergency) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('急诊', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(hours, style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
                const SizedBox(height: 2),
                Text(distance, style: TextStyle(fontSize: 11, color: AppColors.mint, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.mint),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTips() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0E9DC)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.mint),
              SizedBox(width: 6),
              Text('温馨提示', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.mint)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '本功能提供的信息仅供参考，不能替代兽医诊断。如宠物出现严重症状，请及时就医。',
            style: TextStyle(fontSize: 11, color: AppColors.textSoft, height: 1.5),
          ),
        ],
      ),
    );
  }
}
