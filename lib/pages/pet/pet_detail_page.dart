import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/pet.dart';

class PetDetailPage extends StatelessWidget {
  final Pet pet;

  const PetDetailPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfo(),
                  const SizedBox(height: 16),
                  _buildHealthInfo(),
                  const SizedBox(height: 16),
                  _buildRecentRecords(),
                  const SizedBox(height: 16),
                  _buildEditButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      stretch: true,
      backgroundColor: AppColors.mint,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.mint, Color(0xFF6BC89D)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  child: Text(pet.speciesEmoji, style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 10),
                Text(pet.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(pet.breed, style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('基本信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _infoItem('年龄', pet.age)),
              Expanded(child: _infoItem('体重', '${pet.weight}kg')),
              Expanded(child: _infoItem('运动', '${pet.recommendedExerciseMinutes}分/天')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _infoItem('品种', pet.breed)),
              Expanded(child: _infoItem('性别', pet.genderText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildHealthInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('健康备忘', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _buildTagList('过敏', pet.allergies, AppColors.coral),
          const SizedBox(height: 10),
          _buildTagList('疫苗', pet.vaccinations, AppColors.mint),
          const SizedBox(height: 10),
          _buildEmergencyContact(),
        ],
      ),
    );
  }

  Widget _buildTagList(String label, List<String> tags, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags.isEmpty
              ? [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('暂无记录', style: TextStyle(fontSize: 11, color: AppColors.textMute)),
                  ),
                ]
              : tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  );
                }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmergencyContact() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency, size: 20, color: AppColors.mint),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('紧急联系人', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('暂无设置', style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('添加')),
        ],
      ),
    );
  }

  Widget _buildRecentRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('近期运动', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _buildRecordItem('今天', '遛狗 35分钟', '🎯 打卡成功', true),
        const SizedBox(height: 8),
        _buildRecordItem('昨天', '遛狗 42分钟', '🎯 打卡成功', false),
        const SizedBox(height: 8),
        _buildRecordItem('8.24', '遛狗 28分钟', '✅ 打卡成功', false),
      ],
    );
  }

  Widget _buildRecordItem(String date, String content, String status, bool isToday) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isToday ? AppColors.mint : AppColors.line, width: isToday ? 2 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isToday ? AppColors.mint : AppColors.textSoft)),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('编辑档案'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.mint),
          foregroundColor: AppColors.mint,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
