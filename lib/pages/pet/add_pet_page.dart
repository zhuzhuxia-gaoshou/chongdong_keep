import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/pet.dart';
import '../../network/api_exception.dart';
import '../../services/app_services.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/local_image.dart';

/// 添加/编辑宠物档案。传入 [pet] 即编辑模式（PATCH 上报，服务端回包为准）。
class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key, this.pet});

  final Pet? pet;

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  late PetSpecies _species;
  late final TextEditingController _nameController;
  late String _breed;
  late PetGender _gender;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _allergyController;
  bool _saving = false;
  XFile? _pickedAvatar;

  final _dogBreeds = [
    '柯基',
    '金毛',
    '拉布拉多',
    '边牧',
    '法斗',
    '哈士奇',
    '泰迪',
    '柴犬',
    '萨摩耶',
    '德牧',
    '比熊',
    '博美',
    '雪纳瑞',
    '阿拉斯加',
    '秋田'
  ];
  final _catBreeds = [
    '橘猫',
    '英短蓝猫',
    '布偶猫',
    '美短',
    '暹罗猫',
    '波斯猫',
    '缅因猫',
    '狸花猫',
    '加菲猫',
    '斯芬克斯',
    '孟买猫',
    '暹罗',
    '折耳猫',
    '波斯',
    '其他'
  ];

  bool get _isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _species = p?.species ?? PetSpecies.dog;
    _nameController = TextEditingController(text: p?.name ?? '');
    _breed = p?.breed ?? _dogBreeds.first;
    _gender = p?.gender ?? PetGender.male;
    _ageController =
        TextEditingController(text: p != null ? '${p.ageYears}' : '2');
    _weightController =
        TextEditingController(text: p != null ? '${p.weight}' : '10.5');
    _allergyController = TextEditingController(
        text: p == null
            ? ''
            : [
                ...p.allergies,
                ...p.chronicConditions,
              ].join('、'));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('请输入宠物名字')));
      return;
    }
    final weight = double.tryParse(_weightController.text) ?? 0;
    if (weight <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('体重需大于 0 kg')));
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();

    // 头像上传（可跳过）：失败不阻塞档案保存
    String? avatarUrl = widget.pet?.avatarUrl;
    if (_pickedAvatar != null) {
      try {
        avatarUrl = (await AppServices.instance.users
                .uploadAvatar(_pickedAvatar!))
            .url;
      } on ApiException catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
            content: Text('头像上传失败：${e.friendlyMessage}，档案仍会保存')));
      }
    }

    final age = int.tryParse(_ageController.text) ?? 1;
    final pet = Pet(
      id: widget.pet?.id ?? 'pet_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      species: _species,
      breed: _breed,
      gender: _gender,
      ageYears: age,
      weight: weight,
      birthDate: widget.pet?.birthDate ??
          DateTime.now().subtract(Duration(days: age * 365)),
      avatarUrl: avatarUrl,
      allergies: _allergyController.text.isNotEmpty
          ? _allergyController.text
              .split(RegExp(r'[,，、]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      chronicConditions: widget.pet?.chronicConditions ?? const [],
      isNeutered: widget.pet?.isNeutered ?? false,
      isVaccinated: widget.pet?.isVaccinated ?? false,
      emergencyContact: widget.pet?.emergencyContact,
    );

    try {
      if (_isEditing) {
        await state.updatePet(pet);
      } else {
        await state.addPet(pet);
      }
      // ignore: use_build_context_synchronously
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
          SnackBar(content: Text(_isEditing ? '档案已更新' : '宠物添加成功')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final breeds =
        List<String>.of(_species == PetSpecies.dog ? _dogBreeds : _catBreeds);
    if (!breeds.contains(_breed)) breeds.insert(0, _breed);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑档案' : '添加宠物')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.sp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像上传（点选相册图片）
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: 90,
                  height: 90,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mintLight,
                    border: Border.all(
                        color: AppColors.mint,
                        width: 2,
                        style: BorderStyle.solid),
                  ),
                  child: _avatarChild(),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.sp20),
            Text('选择物种',
                style: TextStyle(
                    fontSize: AppDimens.fsFoot,
                    color: AppColors.textSoft,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: AppDimens.sp8),
            Row(
              children: [
                Expanded(child: _speciesBtn(PetSpecies.dog, '🐕', '狗狗')),
                const SizedBox(width: AppDimens.sp8),
                Expanded(child: _speciesBtn(PetSpecies.cat, '🐈', '猫咪')),
              ],
            ),
            const SizedBox(height: AppDimens.sp16),
            _buildField(
                '宠物名字',
                TextField(
                  controller: _nameController,
                  maxLength: 8,
                  decoration: const InputDecoration(
                      hintText: '给宝贝起个名字', counterText: ''),
                )),
            const SizedBox(height: AppDimens.sp16),
            _buildField(
                '品种',
                DropdownButtonFormField<String>(
                  value: _breed,
                  decoration: const InputDecoration(),
                  items: breeds
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _breed = v ?? _breed),
                )),
            const SizedBox(height: AppDimens.sp16),
            Row(
              children: [
                Expanded(
                    child: _buildField(
                        '性别',
                        DropdownButtonFormField<PetGender>(
                          value: _gender,
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(
                                value: PetGender.male, child: Text('公')),
                            DropdownMenuItem(
                                value: PetGender.female, child: Text('母')),
                          ],
                          onChanged: (v) => setState(() => _gender = v!),
                        ))),
                const SizedBox(width: AppDimens.sp8),
                Expanded(
                    child: _buildField(
                        '年龄',
                        TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '岁')))),
              ],
            ),
            const SizedBox(height: AppDimens.sp16),
            Row(
              children: [
                Expanded(
                    child: _buildField(
                        '体重',
                        TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(hintText: 'kg')))),
                const SizedBox(width: AppDimens.sp8),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: AppDimens.sp16),
            _buildField(
                '过敏/慢病（可选）',
                TextField(
                    controller: _allergyController,
                    decoration:
                        const InputDecoration(hintText: '如：鸡肉过敏、关节问题'))),
            const SizedBox(height: AppDimens.sp24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check, size: AppDimens.sp16),
                label: Text(_saving ? '保存中…' : '保存宠物档案'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (picked != null && mounted) setState(() => _pickedAvatar = picked);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开相册，请检查权限')),
        );
      }
    }
  }

  Widget _avatarChild() {
    if (_pickedAvatar != null) {
      return buildLocalImage(_pickedAvatar!.path, width: 86, height: 86);
    }
    final existing = widget.pet?.avatarUrl;
    if (existing != null && existing.startsWith('http')) {
      return Image.network(existing,
          width: 86,
          height: 86,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.pets_rounded,
              size: 30, color: AppColors.textSoft));
    }
    return const Center(
        child: Icon(Icons.add_a_photo_rounded,
            size: 30, color: AppColors.textSoft));
  }

  Widget _speciesBtn(PetSpecies species, String emoji, String label) {
    final isActive = _species == species;
    return GestureDetector(
      onTap: () => setState(() {
        _species = species;
        _breed =
            species == PetSpecies.dog ? _dogBreeds.first : _catBreeds.first;
      }),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.sp16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.mintLight : AppColors.card,
          border: Border.all(
              color: isActive ? AppColors.mint : AppColors.line,
              width: isActive ? 2 : 1),
          borderRadius: BorderRadius.circular(AppDimens.rMd),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: AppDimens.sp4),
            Text(label,
                style: TextStyle(
                    fontSize: AppDimens.fsBody,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.mint : AppColors.text)),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: AppDimens.fsFoot,
                color: AppColors.textSoft,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppDimens.sp8),
        child,
      ],
    );
  }
}
