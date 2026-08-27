import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../services/app_state.dart';
import '../../models/pet.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  PetSpecies _species = PetSpecies.dog;
  final _nameController = TextEditingController();
  String _breed = '柯基';
  PetGender _gender = PetGender.male;
  final _ageController = TextEditingController(text: '2');
  final _weightController = TextEditingController(text: '10.5');
  final _allergyController = TextEditingController();

  final _dogBreeds = ['柯基', '金毛', '拉布拉多', '边牧', '法斗', '哈士奇', '泰迪', '柴犬', '萨摩耶', '德牧', '比熊', '博美', '雪纳瑞', '阿拉斯加', '秋田'];
  final _catBreeds = ['橘猫', '英短蓝猫', '布偶猫', '美短', '暹罗猫', '波斯猫', '缅因猫', '狸花猫', '加菲猫', '斯芬克斯', '孟买猫', '暹罗', '折耳猫', '波斯', '其他'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入宠物名字')));
      return;
    }
    final pet = Pet(
      id: 'pet_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text,
      species: _species,
      breed: _breed,
      gender: _gender,
      ageYears: int.tryParse(_ageController.text) ?? 1,
      weight: double.tryParse(_weightController.text) ?? 5.0,
      birthDate: DateTime.now().subtract(Duration(days: (int.tryParse(_ageController.text) ?? 1) * 365)),
      allergies: _allergyController.text.isNotEmpty ? _allergyController.text.split(RegExp(r'[,，、]')) : [],
    );
    context.read<AppState>().addPet(pet);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('宠物添加成功 🐾')));
  }

  @override
  Widget build(BuildContext context) {
    final breeds = _species == PetSpecies.dog ? _dogBreeds : _catBreeds;

    return Scaffold(
      appBar: AppBar(title: const Text('添加宠物 🐾')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像上传
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.mintLight,
                  border: Border.all(color: AppColors.mint, width: 2, style: BorderStyle.solid),
                ),
                child: const Center(child: Text('📷', style: TextStyle(fontSize: 32))),
              ),
            ),
            const SizedBox(height: 20),
            Text('选择物种', style: TextStyle(fontSize: 12, color: AppColors.textSoft, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _speciesBtn(PetSpecies.dog, '🐕', '狗狗')),
                const SizedBox(width: 8),
                Expanded(child: _speciesBtn(PetSpecies.cat, '🐈', '猫咪')),
              ],
            ),
            const SizedBox(height: 14),
            _buildField('宠物名字', TextField(controller: _nameController, decoration: const InputDecoration(hintText: '给宝贝起个名字'))),
            const SizedBox(height: 14),
            _buildField('品种', DropdownButtonFormField<String>(
              value: _breed,
              decoration: const InputDecoration(),
              items: breeds.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _breed = v!),
            )),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildField('性别', DropdownButtonFormField<PetGender>(
                  value: _gender,
                  decoration: const InputDecoration(),
                  items: const [DropdownMenuItem(value: PetGender.male, child: Text('公')), DropdownMenuItem(value: PetGender.female, child: Text('母'))],
                  onChanged: (v) => setState(() => _gender = v!),
                ))),
                const SizedBox(width: 8),
                Expanded(child: _buildField('年龄', TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '岁')))),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildField('体重', TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'kg')))),
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 14),
            _buildField('过敏/慢病（可选）', TextField(controller: _allergyController, decoration: const InputDecoration(hintText: '如：鸡肉过敏、关节问题'))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: const Text('✅ 保存宠物档案')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _speciesBtn(PetSpecies species, String emoji, String label) {
    final isActive = _species == species;
    return GestureDetector(
      onTap: () => setState(() {
        _species = species;
        _breed = species == PetSpecies.dog ? _dogBreeds.first : _catBreeds.first;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.mintLight : AppColors.card,
          border: Border.all(color: isActive ? AppColors.mint : AppColors.line, width: isActive ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? AppColors.mint : AppColors.text)),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSoft, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
