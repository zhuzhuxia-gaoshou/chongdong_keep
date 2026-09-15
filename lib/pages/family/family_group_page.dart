import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

/// 家庭照护组（P2 未定稿的演示页，入口已从「我的」摘除）。
/// 2026-09-15 质感 v2：heroGradient 内容大卡降级为 mintLight tonal
/// （全 App 唯一渐变内容卡让位首页 Hero），统计数字迁展示体，
/// 成员头像 emoji→person 图标，白卡统一浮起。
class FamilyGroupPage extends StatefulWidget {
  const FamilyGroupPage({super.key});

  @override
  State<FamilyGroupPage> createState() => _FamilyGroupPageState();
}

class _FamilyGroupPageState extends State<FamilyGroupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家庭照护组')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.sp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFamilyCard(),
            const SizedBox(height: AppDimens.sp20),
            _buildMembersList(),
            const SizedBox(height: AppDimens.sp20),
            _buildSharedPets(),
            const SizedBox(height: AppDimens.sp20),
            _buildPermissions(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showInviteDialog();
        },
        backgroundColor: AppColors.mint,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(
          fontSize: AppDimens.fsBodyMid,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3));

  Widget _buildFamilyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.sp16),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        border: Border.all(color: AppColors.mintLine),
        borderRadius: BorderRadius.circular(AppDimens.rLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconChip(
                  icon: Icons.groups_rounded,
                  background: AppColors.card,
                  color: AppColors.mint),
              const SizedBox(width: AppDimens.sp12),
              const Expanded(
                child: Text('可乐的家',
                    style: TextStyle(
                        fontSize: AppDimens.fsHeadline,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.sp12, vertical: AppDimens.sp4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppDimens.rFull),
                ),
                child: const Text('管理员',
                    style: TextStyle(
                        fontSize: AppDimens.fsCaption,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mint)),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sp12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('3', '成员'),
              _buildStat('2', '宠物'),
              _buildStat('156', '累计打卡'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppText.numericStat(color: AppColors.mint)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: AppDimens.fsMicro, color: AppColors.textSoft)),
      ],
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('成员'),
        const SizedBox(height: AppDimens.sp12),
        _buildMemberItem('我', '管理员', true),
        _buildMemberItem('老婆', '照护者', false),
        _buildMemberItem('妈妈', '只读成员', false),
      ],
    );
  }

  Widget _buildMemberItem(String name, String role, bool isMe) {
    final roleColor = role == '管理员'
        ? AppColors.mint
        : role == '照护者'
            ? AppColors.coral
            : AppColors.textSoft;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sp8),
      padding: const EdgeInsets.all(AppDimens.sp12),
      decoration: AppDimens.cardBox(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.mintLight,
            child: Icon(Icons.person_rounded, size: AppDimens.iconLg, color: AppColors.mint),
          ),
          const SizedBox(width: AppDimens.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: AppDimens.fsBodyMid,
                            fontWeight: FontWeight.w700)),
                    if (isMe) ...[
                      const SizedBox(width: AppDimens.sp8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.sp8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.mintLight,
                          borderRadius:
                              BorderRadius.circular(AppDimens.rXs),
                        ),
                        child: const Text('我',
                            style: TextStyle(
                                fontSize: AppDimens.fsMicro,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mint)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppDimens.sp4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.sp8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimens.rXs),
                      ),
                      child: Text(role,
                          style: TextStyle(
                              fontSize: AppDimens.fsMicro,
                              fontWeight: FontWeight.w700,
                              color: roleColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMe)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSoft),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('修改角色')),
                const PopupMenuItem(value: 'remove', child: Text('移除成员')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSharedPets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('共享宠物'),
        const SizedBox(height: AppDimens.sp12),
        Row(
          children: [
            _buildPetCard('🐕', '可乐', '柯基'),
            const SizedBox(width: AppDimens.sp12),
            _buildPetCard('🐈', '咪咪', '布偶猫'),
          ],
        ),
      ],
    );
  }

  Widget _buildPetCard(String emoji, String name, String breed) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.sp12),
        decoration: AppDimens.cardBox(),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppDimens.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: AppDimens.fsBodyMid,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(breed,
                      style: const TextStyle(
                          fontSize: AppDimens.fsCaption,
                          color: AppColors.textSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('权限说明'),
        const SizedBox(height: AppDimens.sp12),
        _buildPermissionItem('管理员', '所有成员记录、修改角色、移除成员'),
        _buildPermissionItem('照护者', '记录运动、查看所有数据、不能修改设置'),
        _buildPermissionItem('只读成员', '只能查看数据，不能记录或修改'),
      ],
    );
  }

  Widget _buildPermissionItem(String role, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sp8),
      padding: const EdgeInsets.all(AppDimens.sp12),
      decoration: AppDimens.cardBox(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.sp8, vertical: AppDimens.sp4),
            decoration: BoxDecoration(
              color: AppColors.mintLight,
              borderRadius: BorderRadius.circular(AppDimens.rSm),
            ),
            child: Text(role,
                style: const TextStyle(
                    fontSize: AppDimens.fsCaption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mint)),
          ),
          const SizedBox(width: AppDimens.sp12),
          Expanded(
            child: Text(desc,
                style: const TextStyle(
                    fontSize: AppDimens.fsFoot, color: AppColors.textSoft)),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('邀请成员'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: '手机号'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppDimens.sp12),
            const Text('或分享邀请链接',
                style: TextStyle(
                    fontSize: AppDimens.fsFoot, color: AppColors.textSoft)),
            const SizedBox(height: AppDimens.sp8),
            Container(
              padding: const EdgeInsets.all(AppDimens.sp12),
              decoration: BoxDecoration(
                color: AppColors.mintLight,
                borderRadius: BorderRadius.circular(AppDimens.rSm),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link, size: AppDimens.iconSm, color: AppColors.mint),
                  SizedBox(width: AppDimens.sp8),
                  Text('复制邀请链接',
                      style: TextStyle(
                          fontSize: AppDimens.fsFoot,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mint)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('发送邀请')),
        ],
      ),
    );
  }
}
