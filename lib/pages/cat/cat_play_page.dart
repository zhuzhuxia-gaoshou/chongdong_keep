import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../models/exercise_record.dart';
import '../../utils/uuid.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/ui_kit.dart';

/// 陪猫玩耍记录页（2026-09-15 质感 v2）：
/// 玩法宫格 emoji→Material 图标（猫咪 chip 中的 🐈 属内容吉祥物保留）；
/// 时长数字走展示体；全页 cardBox + token 归档。
/// 红线自查：GridView 有界 / 无 stretch / 无透明度入场动效。
class CatPlayPage extends StatefulWidget {
  const CatPlayPage({super.key});

  @override
  State<CatPlayPage> createState() => _CatPlayPageState();
}

/// 玩法 → 图标（出网 emoji 字段保留给分享卡文案，页面仅用图标）
final Map<CatPlayType, IconData> _playIcons = {
  CatPlayType.featherWand: Icons.gesture_rounded, // 逗猫棒挥舞
  CatPlayType.laserPointer: Icons.flare_rounded, // 激光光点
  CatPlayType.yarnBall: Icons.autorenew_rounded, // 毛线卷
  CatPlayType.electricMouse: Icons.cruelty_free_rounded, // 小动物
  CatPlayType.bouncyBall: Icons.sports_baseball_rounded, // 球
  CatPlayType.boxAdventure: Icons.inventory_2_rounded, // 纸箱
};

class _CatPlayPageState extends State<CatPlayPage> {
  final List<String> _selectedCatIds = [];
  CatPlayType _playType = CatPlayType.featherWand;
  int _duration = 15;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cats = state.pets.where((p) => p.species.name == 'cat').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('陪猫玩耍')),
      body: cats.isEmpty
          ? const Center(
              child: EmptyState(
                emoji: '🐈',
                title: '还没有猫咪档案',
                message: '先去「我的」页添加一只猫咪宝贝吧',
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.sp16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择本次玩耍的猫咪',
                      style: TextStyle(
                          fontSize: AppDimens.fsFoot,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSoft)),
                  const SizedBox(height: AppDimens.sp8),
                  Wrap(
                    spacing: AppDimens.sp8,
                    children: cats.map((cat) {
                      final isSelected = _selectedCatIds.contains(cat.id);
                      return PressableScale(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.sp16,
                              vertical: AppDimens.sp8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.mintLight
                                : AppColors.card,
                            border: Border.all(
                                color: isSelected
                                    ? AppColors.mint
                                    : AppColors.line,
                                width: isSelected ? 2 : 1),
                            borderRadius:
                                BorderRadius.circular(AppDimens.rMd),
                          ),
                          child: Text('🐈 ${cat.name}',
                              style: TextStyle(
                                  fontSize: AppDimens.fsFoot,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.mint
                                      : AppColors.text)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimens.sp16),
                  const Text('玩耍类型',
                      style: TextStyle(
                          fontSize: AppDimens.fsFoot,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSoft)),
                  const SizedBox(height: AppDimens.sp8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: AppDimens.sp8,
                      mainAxisSpacing: AppDimens.sp8,
                    ),
                    itemCount: CatPlayType.values.length,
                    itemBuilder: (_, index) {
                      final type = CatPlayType.values[index];
                      final isActive = _playType == type;
                      return PressableScale(
                        onTap: () => setState(() => _playType = type),
                        child: Container(
                          decoration: isActive
                              ? BoxDecoration(
                                  // 选中：tonal 平面 + 薄荷描边
                                  color: AppColors.mintLight,
                                  border: Border.all(
                                      color: AppColors.mint, width: 2),
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.rMd),
                                )
                              // 未选中：2 列 sp8 间距密集宫格，双层影压邻格 →
                              // 描边平面，圆角与选中态 rMd 对齐（D1-4）
                              : AppDimens.cardBox(
                                  borderColor: AppColors.line,
                                  radius: AppDimens.rMd),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_playIcons[type]!,
                                  size: 26,
                                  color: isActive
                                      ? AppColors.mint
                                      : AppColors.textSoft),
                              const SizedBox(height: AppDimens.sp4),
                              Text(type.label,
                                  style: TextStyle(
                                      fontSize: AppDimens.fsCaption,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? AppColors.mint
                                          : AppColors.text)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimens.sp16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.sp16, vertical: AppDimens.sp12),
                    decoration: AppDimens.cardBox(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.timer_rounded,
                                size: AppDimens.iconSm, color: AppColors.textSoft),
                            SizedBox(width: AppDimens.sp8),
                            Text('时长',
                                style: TextStyle(
                                    fontSize: AppDimens.fsBody,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Row(
                          children: [
                            _circleBtn(Icons.remove_rounded,
                                () => setState(() => _duration = (_duration - 5).clamp(5, 120))),
                            const SizedBox(width: AppDimens.sp12),
                            Text('$_duration分',
                                style: AppText.numericInline()),
                            const SizedBox(width: AppDimens.sp12),
                            _circleBtn(Icons.add_rounded,
                                () => setState(() => _duration = (_duration + 5).clamp(5, 120))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.sp16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _selectedCatIds.isEmpty ? null : _save,
                      icon: const Icon(Icons.check_circle_rounded,
                          size: AppDimens.iconMd),
                      label: const Text('保存记录并打卡'),
                    ),
                  ),
                  const SizedBox(height: AppDimens.sp8),
                  const Center(
                      child: Text('满5分钟即算今日打卡成功',
                          style: TextStyle(
                              fontSize: AppDimens.fsMicro,
                              color: AppColors.textMute))),
                ],
              ),
            ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.mintLight,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: AppDimens.iconSm, color: AppColors.mint),
        ),
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
        catPlayType: _playType.name, // 玩法落库（契约 ⑭ catPlayType）
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
