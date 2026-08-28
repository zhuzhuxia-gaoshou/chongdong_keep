import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../services/app_state.dart';
import '../../models/exercise_record.dart';
import '../../utils/uuid.dart';

class CatPlayPage extends StatefulWidget {
  const CatPlayPage({super.key});

  @override
  State<CatPlayPage> createState() => _CatPlayPageState();
}

class _CatPlayPageState extends State<CatPlayPage> {
  final List<String> _selectedCatIds = [];
  CatPlayType _playType = CatPlayType.featherWand;
  int _duration = 15;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cats = state.pets.where((p) => p.species.name == 'cat').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('🐈 陪猫玩耍')),
      body: cats.isEmpty
        ? Center(child: Text('请先添加猫咪', style: TextStyle(color: AppColors.textSoft)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择本次玩耍的猫咪', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSoft)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: cats.map((cat) {
                    final isSelected = _selectedCatIds.contains(cat.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCatIds.remove(cat.id);
                          } else {
                            _selectedCatIds.add(cat.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.mintLight : AppColors.card,
                          border: Border.all(color: isSelected ? AppColors.mint : AppColors.line, width: isSelected ? 2 : 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('🐈 ${cat.name}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? AppColors.mint : AppColors.text)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('玩耍类型', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSoft)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: CatPlayType.values.length,
                  itemBuilder: (_, index) {
                    final type = CatPlayType.values[index];
                    final isActive = _playType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _playType = type),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.mintLight : AppColors.card,
                          border: Border.all(color: isActive ? AppColors.mint : AppColors.line, width: isActive ? 2 : 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(type.emoji, style: const TextStyle(fontSize: 28)),
                            Text(type.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppColors.mint : AppColors.text)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('⏱️ 时长', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          _circleBtn(Icons.remove, () => setState(() => _duration = (_duration - 5).clamp(5, 120))),
                          const SizedBox(width: 10),
                          Text('${_duration}分', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 10),
                          _circleBtn(Icons.add, () => setState(() => _duration = (_duration + 5).clamp(5, 120))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedCatIds.isEmpty ? null : _save,
                    child: const Text('✅ 保存记录并打卡'),
                  ),
                ),
                const SizedBox(height: 10),
                Center(child: Text('满5分钟即算今日打卡成功', style: TextStyle(fontSize: 10, color: AppColors.textMute))),
              ],
            ),
          ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.mintLight,
        ),
        child: Icon(icon, size: 16, color: AppColors.mint),
      ),
    );
  }

  void _save() {
    final state = context.read<AppState>();
    final now = DateTime.now();
    for (final catId in _selectedCatIds) {
      state.addRecord(ExerciseRecord(
        id: 'rec_${now.millisecondsSinceEpoch}_$catId',
        clientRecordId: newUuidV4(), // ⑭ 上报幂等键；猫玩记录同样可上报
        petId: catId,
        userId: state.user?.id ?? '',
        type: ExerciseType.catPlay,
        startTime: now.subtract(Duration(minutes: _duration)),
        endTime: now,
        duration: Duration(minutes: _duration),
        isManual: true,
      ));
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('记录成功！运动$_duration分钟${_duration >= 5 ? '，打卡成功✅' : ''}')),
    );
  }
}
