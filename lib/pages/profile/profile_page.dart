import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../network/api_exception.dart';
import '../../services/app_services.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/user_avatar.dart';
import '../pet/add_pet_page.dart';
import '../pet/pet_detail_page.dart';
import '../calendar/checkin_calendar_page.dart';
import '../ranking/ranking_page.dart';
import '../report/weekly_report_page.dart';
import '../family/family_group_page.dart';
import '../health/health_safety_page.dart';
import '../settings/settings_page.dart';
import '../route/route_favorites_page.dart';
import '../badge/badges_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _showEditProfileSheet(context),
                child: _buildHeader(),
              ),
              const SizedBox(height: 14),
              _buildStatsRow(),
              const SizedBox(height: 14),
              _buildBadgesRow(),
              const SizedBox(height: 14),
              _buildMenuSection('我的宠物', [
                _menuItem('🐕', '宠物档案', '${state.pets.length}只宠物', () {
                  if (state.pets.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PetDetailPage(pet: state.pets.first),
                    ));
                  }
                }),
                _menuItem('➕', '添加宠物', '', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()))),
              ]),
              const SizedBox(height: 10),
              _buildMenuSection('运动与打卡', [
                _menuItem('📅', '打卡日历', '${user?.streakDays ?? 0}天连续', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInCalendarPage()))),
                _menuItem('🏆', '排行榜', '好友周榜', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingPage()))),
                _menuItem('📊', '周报月报', '查看本周报告', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyReportPage()))),
                _menuItem('🏅', '徽章成就', '6/16已解锁', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesPage()))),
                _menuItem('🗺️', '收藏路线', '3条路线', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RouteFavoritesPage()))),
              ]),
              const SizedBox(height: 10),
              _buildMenuSection('家庭与健康', [
                _menuItem('👨‍👩‍👧', '家庭照护组', '3位成员', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyGroupPage()))),
                _menuItem('🏥', '健康安全', '症状自查/附近医院', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthSafetyPage()))),
              ]),
              const SizedBox(height: 10),
              _buildMenuSection('设置', [
                _menuItem('🔒', '隐私与设置', '', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
                _menuItem('📤', '分享宠动Keep', '', null),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.coral),
                  child: const Text('退出登录'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final state = context.watch<AppState>();
    final user = state.user;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.mint, Color(0xFF6BC89D)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              // 统一头像组件：兼容 emoji/本地路径/网络 URL 三态
              UserAvatar(
                url: user?.avatarUrl,
                radius: 32,
                fallbackEmoji: '👩',
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.mint, width: 1.5),
                  ),
                  child: const Center(child: Text('✏️', style: TextStyle(fontSize: 9))),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(user?.nickname ?? '铲屎官', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    const Text('✏️', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '加入宠动Keep ${DateTime.now().difference(user?.createdAt ?? DateTime.now()).inDays}天',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('🔥 连续打卡 ${user?.streakDays ?? 0} 天', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final state = context.watch<AppState>();
    return Row(
      children: [
        Expanded(child: _statCard('${state.records.length}', '总运动次数')),
        const SizedBox(width: 6),
        Expanded(child: _statCard('${state.records.fold(0, (sum, r) => sum + r.duration.inHours)}h', '总时长')),
        Expanded(child: _statCard('${state.records.fold(0.0, (sum, r) => sum + r.distance).toStringAsFixed(1)}', '总距离')),
        const SizedBox(width: 6),
        Expanded(child: _statCard('${state.user?.signCardCount ?? 3}', '补签卡')),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.mint)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: AppColors.textSoft)),
        ],
      ),
    );
  }

  Widget _buildBadgesRow() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _badge('🔥', '7天', true),
          _badge('🏆', '30天', true),
          _badge('💎', '100天', false),
          _badge('🚀', '100公里', true),
          _badge('👑', '365天', false),
        ],
      ),
    );
  }

  Widget _badge(String emoji, String label, bool unlocked) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked ? AppColors.mintLight : AppColors.sand,
              border: Border.all(color: unlocked ? AppColors.mint : AppColors.line, width: 2),
            ),
            child: Center(child: Text(emoji, style: TextStyle(fontSize: 20, color: unlocked ? null : AppColors.textMute))),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9, color: unlocked ? AppColors.text : AppColors.textMute)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSoft)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _menuItem(String emoji, String title, String subtitle, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              if (subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(subtitle, style: TextStyle(fontSize: 10, color: AppColors.textMute)),
                ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textMute),
            ],
          ),
        ),
      ),
    );
  }

  /// 编辑资料底部弹窗：改头像（拍照/相册）+ 改昵称。
  /// M1 流程：选图仅本地预览，点保存 → uploadAvatar → patchMe，
  /// 以服务端回包为准提交（见《前端开发计划》§四）。
  void _showEditProfileSheet(BuildContext context) {
    final state = context.read<AppState>();
    final user = state.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.nickname);
    XFile? pickedFile; // 新选的头像（未上传）
    String? preview = user.avatarUrl; // 弹窗内头像预览源
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final messenger = ScaffoldMessenger.of(ctx);
          Future<void> pickImage(ImageSource source) async {
            try {
              final picked = await ImagePicker().pickImage(
                source: source,
                imageQuality: 80,
                maxWidth: 720,
              );
              if (picked == null) return;
              setSheetState(() {
                pickedFile = picked;
                preview = picked.path; // 本地临时路径仅供预览
              });
            } catch (_) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('无法打开相机或相册，请检查权限')),
                );
              }
            }
          }

          Future<void> save() async {
            final nickname = nameController.text.trim();
            if (nickname.isEmpty) {
              messenger.showSnackBar(const SnackBar(content: Text('昵称不能为空哦')));
              return;
            }
            if (saving) return;
            setSheetState(() => saving = true);
            try {
              String? avatarUrl;
              if (pickedFile != null) {
                avatarUrl =
                    (await AppServices.instance.users.uploadAvatar(pickedFile!))
                        .url;
              }
              final echo = await AppServices.instance.users
                  .patchMe(nickname: nickname, avatarUrl: avatarUrl);
              // ignore: use_build_context_synchronously
              if (!ctx.mounted) return;
              await ctx.read<AppState>().patchProfile(echo);
              // ignore: use_build_context_synchronously
              if (ctx.mounted) Navigator.pop(ctx);
            } on ApiException catch (e) {
              messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
            } finally {
              // 弹窗可能已随成功关闭而销毁；失败时恢复按钮
              if (ctx.mounted) setSheetState(() => saving = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 16),
                      const Text('编辑资料', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      // 头像预览（UserAvatar 兼容本地临时路径与历史 URL）
                      GestureDetector(
                        onTap: () => pickImage(ImageSource.camera),
                        child: Stack(
                          children: [
                            Container(
                              width: 84, height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.mintLight,
                                border: Border.all(color: AppColors.mint, width: 2),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: UserAvatar(
                                url: preview,
                                radius: 39,
                                fallbackEmoji: '👩',
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.mint),
                                child: const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined, size: 16),
                            label: const Text('拍照', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_outlined, size: 16),
                            label: const Text('相册', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('昵称', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSoft)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        maxLength: 12,
                        decoration: const InputDecoration(hintText: '给自己起个名字', counterText: ''),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: saving ? null : save,
                          icon: saving
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check, size: 16),
                          label: Text(saving ? '保存中…' : '保存'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<AppState>().logout();
              Navigator.pop(ctx);
            },
            child: const Text('退出', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }
}
