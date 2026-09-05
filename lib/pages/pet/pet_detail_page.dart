import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise_record.dart';
import '../../models/pet.dart';
import '../../network/api_exception.dart';
import '../../services/app_state.dart';
import '../../services/map_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../record/record_history_page.dart';
import 'add_pet_page.dart';

/// 宠物档案详情。数据始终按 id 从 AppState 解析（M2 云端回写后自动刷新），
/// 传入的 [pet] 仅作兜底快照。
class PetDetailPage extends StatefulWidget {
  final Pet pet;

  const PetDetailPage({super.key, required this.pet});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  /// 当前展示的宠物 id；可切换查看其他宠物
  late String _selectedId = widget.pet.id;

  /// 云端化后的"活"宠物：列表里被编辑/删除立刻反映到本页。
  Pet get _pet =>
      context
          .watch<AppState>()
          .pets
          .where((p) => p.id == _selectedId)
          .firstOrNull ??
      context.watch<AppState>().pets.firstOrNull ??
      widget.pet;

  @override
  Widget build(BuildContext context) {
    final pet = _pet;
    final allPets = context.watch<AppState>().pets;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(pet),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.sp16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (allPets.length > 1) ...[
                    const SizedBox(height: AppDimens.sp12),
                    _buildPetSwitcher(allPets, pet),
                  ],
                  _buildBasicInfo(pet),
                  const SizedBox(height: AppDimens.sp16),
                  _buildHealthInfo(pet),
                  const SizedBox(height: AppDimens.sp16),
                  _buildRecentRecords(pet),
                  const SizedBox(height: AppDimens.sp16),
                  _buildEditButton(pet),
                  const SizedBox(height: AppDimens.sp24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 多宠物切换条（仅一只时隐藏）
  Widget _buildPetSwitcher(List<Pet> pets, Pet current) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final p in pets)
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.sp8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedId = p.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.sp12, vertical: AppDimens.sp8),
                  decoration: BoxDecoration(
                    color: p.id == current.id
                        ? AppColors.mintLight
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(AppDimens.rFull),
                    border: Border.all(
                      color: p.id == current.id ? AppColors.mint : AppColors.line,
                      width: p.id == current.id ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.speciesEmoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: AppDimens.sp4),
                      Text(p.name,
                          style: TextStyle(
                              fontSize: AppDimens.fsFoot,
                              fontWeight: FontWeight.w700,
                              color: p.id == current.id
                                  ? AppColors.mint
                                  : AppColors.text)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Pet pet) {
    return SliverAppBar(
      expandedHeight: 200,
      stretch: true,
      backgroundColor: AppColors.mint,
      floating: false,
      pinned: true,
      actions: [
        IconButton(
          onPressed: () => _confirmDelete(pet),
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          tooltip: '删除档案',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  child: pet.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                              pet.avatarUrl!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                  pet.speciesEmoji,
                                  style: const TextStyle(fontSize: 48))),
                        )
                      : Text(pet.speciesEmoji,
                          style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: AppDimens.sp12),
                Text(pet.name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: AppDimens.sp8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.sp12, vertical: AppDimens.sp4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppDimens.rSm),
                  ),
                  child: Text(pet.breed,
                      style: const TextStyle(
                          fontSize: AppDimens.fsFoot, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sp16),
      decoration: AppDimens.cardBox(borderColor: AppColors.line),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('基本信息',
              style: TextStyle(
                  fontSize: AppDimens.fsBodyMid, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppDimens.sp12),
          Row(
            children: [
              Expanded(child: _infoItem('年龄', pet.age)),
              Expanded(child: _infoItem('体重', '${pet.weight}kg')),
              Expanded(
                  child:
                      _infoItem('运动', '${pet.recommendedExerciseMinutes}分/天')),
            ],
          ),
          const SizedBox(height: AppDimens.sp12),
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
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sp4),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: AppDimens.fsFoot, color: AppColors.textSoft)),
          const SizedBox(width: AppDimens.sp8),
          Expanded(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: AppDimens.fsBody,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildHealthInfo(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sp16),
      decoration: AppDimens.cardBox(borderColor: AppColors.line),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('健康备忘',
              style: TextStyle(
                  fontSize: AppDimens.fsBodyMid, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppDimens.sp12),
          _buildTagList('过敏', pet.allergies, AppColors.coral),
          const SizedBox(height: AppDimens.sp12),
          _buildTagList('疫苗', pet.vaccinations, AppColors.mint),
          const SizedBox(height: AppDimens.sp12),
          _buildEmergencyContact(pet),
        ],
      ),
    );
  }

  Widget _buildTagList(String label, List<String> tags, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: AppDimens.fsCaption, color: AppColors.textSoft)),
        const SizedBox(height: AppDimens.sp8),
        Wrap(
          spacing: AppDimens.sp8,
          runSpacing: AppDimens.sp8,
          children: tags.isEmpty
              ? [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.sp12, vertical: AppDimens.sp4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppDimens.rSm),
                    ),
                    child: const Text('暂无记录',
                        style: TextStyle(
                            fontSize: AppDimens.fsCaption,
                            color: AppColors.textMute)),
                  ),
                ]
              : tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.sp12, vertical: AppDimens.sp4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimens.rSm),
                    ),
                    child: Text(tag,
                        style: TextStyle(
                            fontSize: AppDimens.fsCaption,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  );
                }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmergencyContact(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sp12),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        borderRadius: BorderRadius.circular(AppDimens.rMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency,
              size: AppDimens.sp20, color: AppColors.mint),
          const SizedBox(width: AppDimens.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('紧急联系人',
                    style: TextStyle(
                        fontSize: AppDimens.fsFoot,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(pet.emergencyContact ?? '暂无设置',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: AppDimens.fsCaption,
                        color: AppColors.textSoft)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _editEmergencyContact(pet),
            child: Text(pet.emergencyContact == null ? '添加' : '修改'),
          ),
        ],
      ),
    );
  }

  /// 紧急联系人编辑（PRD 4.5.2）：姓名+电话，保存走既有 PATCH 链路
  Future<void> _editEmergencyContact(Pet pet) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('紧急联系人'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: '称呼（如：李姐/爸爸）'),
              maxLength: 12,
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: '电话'),
              maxLength: 15,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final contact = (name.isEmpty || phone.isEmpty) ? null : '$name $phone';
    try {
      await context.read<AppState>().updatePet(Pet(
            id: pet.id,
            name: pet.name,
            species: pet.species,
            breed: pet.breed,
            gender: pet.gender,
            ageYears: pet.ageYears,
            weight: pet.weight,
            birthDate: pet.birthDate,
            avatarUrl: pet.avatarUrl,
            allergies: pet.allergies,
            chronicConditions: pet.chronicConditions,
            isNeutered: pet.isNeutered,
            isVaccinated: pet.isVaccinated,
            emergencyContact: contact,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(contact == null ? '已清除紧急联系人' : '紧急联系人已保存')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.friendlyMessage)));
    }
  }

  // ---- 近期运动（真实本地记录，M3 接查询接口后同源切换） ----

  Widget _buildRecentRecords(Pet pet) {
    final all = context.watch<AppState>().records;
    final mine = all.where((r) => r.petId == pet.id).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final top = mine.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('近期运动',
            style: TextStyle(
                fontSize: AppDimens.fsBodyMid, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppDimens.sp12),
        if (top.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.sp16),
            decoration: AppDimens.cardBox(borderColor: AppColors.line),
            child: const Text('还没有运动记录，带它去遛一圈吧 🐾',
                style: TextStyle(
                    fontSize: AppDimens.fsCaption, color: AppColors.textSoft)),
          )
        else
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDimens.sp8),
            _buildRecordItem(top[i]),
          ],
        if (mine.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: AppDimens.sp8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecordHistoryPage())),
                child: Text('查看全部 ${mine.length} 次记录 →',
                    style: TextStyle(
                        fontSize: AppDimens.fsCaption, color: AppColors.mint)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecordItem(ExerciseRecord r) {
    final now = DateTime.now();
    final isToday = r.startTime.year == now.year &&
        r.startTime.month == now.month &&
        r.startTime.day == now.day;
    final typeName = r.typeDisplayName;
    return Container(
      padding: const EdgeInsets.all(AppDimens.sp12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.rMd),
        border: Border.all(
            color: isToday ? AppColors.mint : AppColors.line,
            width: isToday ? 2 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel(r.startTime),
                    style: TextStyle(
                        fontSize: AppDimens.fsCaption,
                        color: AppColors.textSoft)),
                const SizedBox(height: AppDimens.sp4),
                Text(
                    '$typeName ${MapService.formatDuration(r.duration)} · ${MapService.formatDistance(r.distance)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: AppDimens.fsBody,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(
            r.canCheckIn ? '🎯 打卡成功' : '未达打卡时长',
            style: TextStyle(
                fontSize: AppDimens.fsCaption,
                fontWeight: FontWeight.w700,
                color: r.canCheckIn ? AppColors.mint : AppColors.textSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(Pet pet) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => AddPetPage(pet: pet))),
        icon: const Icon(Icons.edit, size: AppDimens.sp20),
        label: const Text('编辑档案'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.mint),
          foregroundColor: AppColors.mint,
          padding: const EdgeInsets.symmetric(vertical: AppDimens.sp16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.rMd)),
        ),
      ),
    );
  }

  // ---- 删除（服务端软删，记录保留） ----

  Future<void> _confirmDelete(Pet pet) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除宠物档案'),
        content: Text('删除「${pet.name}」后，它的运动记录仍会保留在历史中。确定删除吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await state.removePet(pet.id);
      nav.pop(); // 回到"我的"页，列表已响应式移除
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
    }
  }

  static String _dateLabel(DateTime t) {
    final now = DateTime.now();
    final day = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (t.year != now.year) return '${t.year}年${t.month}月${t.day}日';
    return '${t.month}月${t.day}日';
  }
}
