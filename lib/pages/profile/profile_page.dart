import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../network/api_exception.dart';
import '../../services/api_config.dart';
import '../../services/app_services.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/user_avatar.dart';
import '../badge/badges_page.dart';
import '../calendar/checkin_calendar_page.dart';
import '../family/family_group_page.dart';
import '../health/health_safety_page.dart';
import '../pet/add_pet_page.dart';
import '../pet/pet_detail_page.dart';
import '../ranking/ranking_page.dart';
import '../record/record_history_page.dart';
import '../report/weekly_report_page.dart';
import '../route/route_favorites_page.dart';
import '../settings/settings_page.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.sp16),
          child: Column(
            children: [
              const SizedBox(height: AppDimens.sp16),
              GestureDetector(
                onTap: () => _showEditProfileSheet(context),
                child: _buildHeader(),
              ),
              const SizedBox(height: AppDimens.sp16),
              _buildStatsRow(),
              const SizedBox(height: AppDimens.sp16),
              _buildBadgesRow(),
              const SizedBox(height: AppDimens.sp16),
              SectionCard(title: '我的宠物', children: [
                MenuTile(
                  leading: _menuIcon(Icons.pets_rounded),
                  title: '宠物档案',
                  subtitle: '${state.pets.length}只宠物',
                  onTap: () {
                    if (state.pets.isNotEmpty) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PetDetailPage(pet: state.pets.first),
                          ));
                    }
                  },
                ),
                _menuTile(
                    Icons.add_rounded,
                    '添加宠物',
                    null,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddPetPage()))),
              ]),
              const SizedBox(height: AppDimens.sp12),
              SectionCard(title: '运动与打卡', children: [
                _menuTile(
                    Icons.calendar_month_rounded,
                    '打卡日历',
                    '${user?.streakDays ?? 0}天连续',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckInCalendarPage()))),
                _menuTile(
                    Icons.list_alt_rounded,
                    '运动记录',
                    '${state.records.length}次',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RecordHistoryPage()))),
                _menuTile(
                    Icons.emoji_events_rounded,
                    '排行榜',
                    '好友周榜',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RankingPage()))),
                _menuTile(
                    Icons.bar_chart_rounded,
                    '周报月报',
                    '查看本周报告',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WeeklyReportPage()))),
                _menuTile(
                    Icons.workspace_premium_rounded,
                    '徽章成就',
                    '6/16已解锁',
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BadgesPage()))),
                _menuTile(
                    Icons.route_rounded,
                    '收藏路线',
                    '3条路线',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RouteFavoritesPage()))),
              ]),
              const SizedBox(height: AppDimens.sp12),
              SectionCard(title: '家庭与健康', children: [
                _menuTile(
                    Icons.groups_rounded,
                    '家庭照护组',
                    '3位成员',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FamilyGroupPage()))),
                _menuTile(
                    Icons.health_and_safety_rounded,
                    '健康安全',
                    '症状自查/附近医院',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HealthSafetyPage()))),
              ]),
              const SizedBox(height: AppDimens.sp12),
              SectionCard(title: '设置', children: [
                _menuTile(
                    Icons.lock_outline_rounded,
                    '隐私与设置',
                    null,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsPage()))),
                _menuTile(Icons.ios_share_rounded, '分享宠动Keep', null, null),
              ]),
              const SizedBox(height: AppDimens.sp16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coral),
                  child: const Text('退出登录'),
                ),
              ),
              const SizedBox(height: AppDimens.sp40),
            ],
          ),
        ),
      ),
    );
  }

  /// 着色圆角图标底：菜单行统一的高级感前导件
  Widget _menuIcon(IconData icon) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.mintLight,
          borderRadius: BorderRadius.circular(AppDimens.rSm),
        ),
        child: Icon(icon, size: 20, color: AppColors.mint),
      );

  /// 菜单行快捷构造：着色图标底 + 标题 + 副标题 + 统一右箭头。
  Widget _menuTile(
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback? onTap,
  ) {
    return MenuTile(
      leading: _menuIcon(icon),
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  Widget _buildHeader() {
    final state = context.watch<AppState>();
    final user = state.user;
    return Container(
      padding: const EdgeInsets.all(AppDimens.sp16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppDimens.rLg),
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
                  width: AppDimens.sp20,
                  height: AppDimens.sp20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.mint, width: 1.5),
                  ),
                  child: const Center(
                      child: Text('✏️', style: TextStyle(fontSize: 9))),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDimens.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user?.nickname ?? '铲屎官',
                        style: const TextStyle(
                          fontSize: AppDimens.fsHeadline,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimens.sp4),
                    const Text('✏️', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: AppDimens.sp4),
                Text(
                  '加入宠动Keep ${DateTime.now().difference(user?.createdAt ?? DateTime.now()).inDays}天',
                  style: const TextStyle(
                      fontSize: AppDimens.fsFoot, color: Colors.white70),
                ),
                const SizedBox(height: AppDimens.sp8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.sp8, vertical: AppDimens.sp4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppDimens.rFull),
                  ),
                  child: Text(
                    '🔥 连续打卡 ${user?.streakDays ?? 0} 天',
                    style: const TextStyle(
                      fontSize: AppDimens.fsCaption,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
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
    final records = state.records;
    return Row(
      children: [
        Expanded(child: StatTile(value: '${records.length}', label: '总运动次数')),
        const SizedBox(width: AppDimens.sp8),
        Expanded(
          child: StatTile(
            value: '${records.fold(0, (sum, r) => sum + r.duration.inHours)}h',
            label: '总时长',
          ),
        ),
        const SizedBox(width: AppDimens.sp8),
        Expanded(
          child: StatTile(
            value: records
                .fold(0.0, (sum, r) => sum + r.distance)
                .toStringAsFixed(1),
            label: '总距离',
          ),
        ),
        const SizedBox(width: AppDimens.sp8),
        Expanded(
            child: StatTile(
                value: '${state.user?.signCardCount ?? 3}', label: '补签卡')),
      ],
    );
  }

  Widget _buildBadgesRow() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.sp12),
      decoration: AppDimens.cardBox(borderColor: AppColors.line),
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
      padding: const EdgeInsets.only(right: AppDimens.sp12),
      child: Center(
        child: BadgeCircle(
          emoji: emoji,
          label: label,
          unlocked: unlocked,
          size: AppDimens.sp40,
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

    AppBottomSheet.show<void>(
      context,
      title: '编辑资料',
      isScrollControlled: true,
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
              // 头像上传失败不阻塞昵称保存（格式/网络问题单独提示）
              String? avatarUrl;
              String? avatarWarning;
              if (pickedFile != null) {
                try {
                  avatarUrl = (await AppServices.instance.users
                          .uploadAvatar(pickedFile!))
                      .url;
                } on ApiException catch (e) {
                  avatarWarning = '头像上传失败：${e.friendlyMessage}，昵称仍会保存';
                }
              }
              final echo = await AppServices.instance.users
                  .patchMe(nickname: nickname, avatarUrl: avatarUrl);
              // ignore: use_build_context_synchronously
              if (!ctx.mounted) return;
              // Mock 模式的假 CDN 图无法加载：
              // 换了头像 → 本会话用本地预览路径；只改昵称 → 沿用当前显示的头像
              var localEcho = echo;
              if (ApiConfig.isMock) {
                final currentAvatar = ctx.read<AppState>().user?.avatarUrl;
                final displayAvatar = pickedFile != null
                    ? pickedFile!.path
                    : currentAvatar ?? echo.avatarUrl;
                localEcho = echo.copyWith(avatarUrl: displayAvatar);
              }
              await ctx.read<AppState>().patchProfile(localEcho);
              // ignore: use_build_context_synchronously
              if (!ctx.mounted) return;
              if (avatarWarning != null) {
                messenger.showSnackBar(SnackBar(content: Text(avatarWarning)));
              }
              // ignore: use_build_context_synchronously
              if (ctx.mounted) Navigator.pop(ctx);
            } on ApiException catch (e) {
              messenger
                  .showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
            } finally {
              // 弹窗可能已随成功关闭而销毁；失败时恢复按钮
              if (ctx.mounted) setSheetState(() => saving = false);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 头像预览（UserAvatar 兼容本地临时路径与历史 URL）
              GestureDetector(
                onTap: () => pickImage(ImageSource.camera),
                child: Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mintLight,
                        border: Border.all(color: AppColors.mint, width: 2),
                      ),
                      padding: const EdgeInsets.all(AppDimens.sp4),
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
                        padding: const EdgeInsets.all(AppDimens.sp4),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.mint),
                        child: const Icon(Icons.photo_camera,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.sp12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined,
                        size: AppDimens.sp16),
                    label: const Text('拍照',
                        style: TextStyle(fontSize: AppDimens.fsFoot)),
                  ),
                  const SizedBox(width: AppDimens.sp8),
                  TextButton.icon(
                    onPressed: () => pickImage(ImageSource.gallery),
                    icon:
                        const Icon(Icons.photo_outlined, size: AppDimens.sp16),
                    label: const Text('相册',
                        style: TextStyle(fontSize: AppDimens.fsFoot)),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sp12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('昵称',
                    style: TextStyle(
                      fontSize: AppDimens.fsFoot,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSoft,
                    )),
              ),
              const SizedBox(height: AppDimens.sp8),
              TextField(
                controller: nameController,
                maxLength: 12,
                decoration:
                    const InputDecoration(hintText: '给自己起个名字', counterText: ''),
              ),
              const SizedBox(height: AppDimens.sp16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check, size: AppDimens.sp16),
                  label: Text(saving ? '保存中…' : '保存'),
                ),
              ),
            ],
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
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
