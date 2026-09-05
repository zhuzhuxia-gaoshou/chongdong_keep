import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../network/api_exception.dart';
import '../../services/api_config.dart';
import '../../services/app_services.dart';
import '../../services/app_state.dart';
import '../../services/reminder_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_platform.dart';
import '../../widgets/ui_kit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushEnabled = true;
  bool _locationVisible = true;
  bool _publicRanking = true;
  bool _showDistance = true;
  bool _shareLocation = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 开关持久化：进入页面恢复上次的选择；提醒开着则顺带确保通知已调度。
  Future<void> _loadSettings() async {
    final s = await StorageService.loadAppSettings();
    if (!mounted) return;
    setState(() {
      _pushEnabled = (s['pushEnabled'] as bool?) ?? true;
      _locationVisible = (s['locationVisible'] as bool?) ?? true;
      _publicRanking = (s['publicRanking'] as bool?) ?? true;
      _showDistance = (s['showDistance'] as bool?) ?? true;
      _shareLocation = (s['shareLocation'] as bool?) ?? false;
      _reminderHour = (s['reminderHour'] as int?) ?? 20;
      _reminderMinute = (s['reminderMinute'] as int?) ?? 0;
      _settingsLoaded = true;
    });
    if (_pushEnabled && AppPlatform.isMobile) {
      await _scheduleReminderQuietly();
    }
  }

  void _update(String key, bool value) {
    setState(() {
      switch (key) {
        case 'pushEnabled':
          _pushEnabled = value;
        case 'locationVisible':
          _locationVisible = value;
        case 'publicRanking':
          _publicRanking = value;
        case 'showDistance':
          _showDistance = value;
        case 'shareLocation':
          _shareLocation = value;
      }
    });
    StorageService.saveAppSettings({
      'pushEnabled': _pushEnabled,
      'locationVisible': _locationVisible,
      'publicRanking': _publicRanking,
      'showDistance': _showDistance,
      'shareLocation': _shareLocation,
    });
    if (key == 'publicRanking') _syncPublicRank(value);
    if (key == 'pushEnabled') _applyReminder(value);
  }

  /// 运动提醒开关：请求通知权限 → 调度每日本地通知；权限被拒则回退开关。
  Future<void> _applyReminder(bool enabled) async {
    if (!AppPlatform.isMobile) return;
    try {
      if (!enabled) {
        await ReminderService.instance.cancelDaily();
        return;
      }
      final granted = await ReminderService.instance.ensurePermission();
      if (!mounted) return;
      if (!granted) {
        _update('pushEnabled', false);
        _toast('没有通知权限，请在系统设置里允许宠动Keep发送通知');
        return;
      }
      await _scheduleReminderQuietly();
    } catch (_) {
      // 通知服务异常（模拟器缺 Google 服务等）不阻塞设置页
    }
  }

  Future<void> _scheduleReminderQuietly() async {
    try {
      await ReminderService.instance
          .scheduleDaily(hour: _reminderHour, minute: _reminderMinute);
    } catch (_) {
      // 调度失败静默：下次进入设置页会再尝试
    }
  }

  /// 提醒时间可调：选择后持久化并立即重排今日通知。
  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _reminderHour = picked.hour;
      _reminderMinute = picked.minute;
    });
    final s = Map<String, Object?>.from(await StorageService.loadAppSettings());
    s['reminderHour'] = _reminderHour;
    s['reminderMinute'] = _reminderMinute;
    await StorageService.saveAppSettings(s);
    if (_pushEnabled && AppPlatform.isMobile) {
      await _scheduleReminderQuietly();
    }
  }

  /// 公开排行榜参与开关同步到服务端（Live 模式）：后端据此把本用户从榜单剔除。
  /// 本机设置仍是「我的排名区」显示口径，同步失败不阻塞本地生效。
  Future<void> _syncPublicRank(bool value) async {
    if (ApiConfig.isMock) return;
    try {
      await AppServices.instance.users.patchMe(isPublicRank: value);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('排行榜设置同步服务器失败：${e.friendlyMessage}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_settingsLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.sp16, vertical: AppDimens.sp12),
        children: [
          SectionCard(title: '通知提醒', children: [
            MenuTile(
              leading: const Icon(Icons.notifications_active_outlined,
                  size: AppDimens.sp20, color: AppColors.textSoft),
              title: '运动提醒',
              subtitle: '每天定时提醒遛狗',
              trailing: Switch(
                value: _pushEnabled,
                onChanged: (v) => _update('pushEnabled', v),
              ),
            ),
            MenuTile(
              leading: const Icon(Icons.alarm,
                  size: AppDimens.sp20, color: AppColors.textSoft),
              title: '提醒时间',
              subtitle:
                  '每天 ${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
              onTap: _pickReminderTime,
            ),
          ]),
          const SizedBox(height: AppDimens.sp16),
          SectionCard(title: '隐私设置', children: [
            _switchTile(Icons.route, '轨迹可见', '好友功能上线后生效：好友可查看运动路线',
                _locationVisible, (v) => _update('locationVisible', v)),
            _switchTile(Icons.leaderboard_outlined, '公开排行榜', '参与好友排行榜排名',
                _publicRanking, (v) => _update('publicRanking', v)),
            _switchTile(Icons.straighten, '显示距离', '分享卡片显示运动距离', _showDistance,
                (v) => _update('showDistance', v)),
            _switchTile(Icons.location_on_outlined, '分享位置', '分享卡片显示具体位置',
                _shareLocation, (v) => _update('shareLocation', v)),
          ]),
          const SizedBox(height: AppDimens.sp16),
          SectionCard(title: '数据管理', children: [
            _navTile('导出数据', '运动记录与宠物档案摘要（文本分享）', Icons.download,
                onTap: _exportData),
            _navTile('删除运动记录', '清除本机缓存的历史运动记录', Icons.delete_outline,
                isDanger: true, onTap: _confirmClearRecords),
            _navTile('删除宠物档案', '删除全部宠物（同步服务端，不可恢复）', Icons.pets,
                isDanger: true, onTap: _confirmClearPets),
          ]),
          const SizedBox(height: AppDimens.sp16),
          SectionCard(title: '账号', children: [
            _navTile('修改手机号',
                '当前: ${context.watch<AppState>().user?.phone ?? '未登录'}', Icons.phone,
                onTap: () => _toast('手机号修改需要短信验证服务支持，即将开放')),
            _navTile('注销账号', '删除所有数据和账号', Icons.person_off, isDanger: true,
                onTap: () => _toast('账号注销需要后端服务支持，即将开放')),
          ]),
          const SizedBox(height: AppDimens.sp16),
          SectionCard(title: '开发环境', children: [_buildEnvTile()]),
          const SizedBox(height: AppDimens.sp24),
          Center(
            child: TextButton(
              onPressed: _showLogoutConfirm,
              child: const Text('退出登录',
                  style: TextStyle(
                      fontSize: AppDimens.fsSub,
                      fontWeight: FontWeight.w700,
                      color: AppColors.coral)),
            ),
          ),
          const SizedBox(height: AppDimens.sp16),
          Center(
            child: Text('宠动Keep v1.0.0',
                style: TextStyle(
                    fontSize: AppDimens.fsCaption, color: AppColors.textMute)),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 数据导出：把本机数据汇总为文本，走系统分享（网页端为网页分享/复制）
  Future<void> _exportData() async {
    final state = context.read<AppState>();
    final pets = state.pets.isEmpty
        ? '未添加'
        : state.pets.map((p) => '${p.name}（${p.breed}）').join('、');
    final totalMin =
        state.records.fold<int>(0, (s, r) => s + r.duration.inMinutes);
    final totalKm = state.records.fold<double>(0, (s, r) => s + r.distance);
    final now = DateTime.now();
    final text = '宠动Keep 数据导出（${now.year}-${now.month}-${now.day}）\n'
        '宠物：$pets\n'
        '运动记录：${state.records.length} 条，'
        '累计 $totalMin 分钟 / ${totalKm.toStringAsFixed(1)} 公里\n'
        '（详细轨迹与图片不包含在文本导出中）';
    await Share.share(text);
  }

  Future<void> _confirmClearRecords() async {
    final state = context.read<AppState>();
    final count = state.records.length;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除运动记录？'),
        content: Text('将清除本机缓存的 $count 条运动记录。'
            'Mock 模式下即全量删除；连接服务端时云端原始数据不受影响。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await state.clearLocalRecords();
    messenger.showSnackBar(const SnackBar(content: Text('已清除本机运动记录')));
  }

  Future<void> _confirmClearPets() async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    if (state.pets.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('当前没有宠物档案')));
      return;
    }
    final count = state.pets.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除全部宠物档案？'),
        content: Text('将删除 $count 只宠物的档案（服务端软删除，'
            '历史运动记录保留供周报）。此操作不可恢复，确定继续吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('全部删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      for (final p in List.of(state.pets)) {
        await state.removePet(p.id);
      }
      messenger.showSnackBar(SnackBar(content: Text('已删除 $count 只宠物档案')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
    }
  }

  Widget _switchTile(IconData icon, String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return MenuTile(
      leading: Icon(icon, size: AppDimens.sp20, color: AppColors.textSoft),
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _navTile(String title, String subtitle, IconData icon,
      {bool isDanger = false, VoidCallback? onTap}) {
    return MenuTile(
      leading: Icon(icon,
          size: AppDimens.sp20,
          color: isDanger ? AppColors.coral : AppColors.textSoft),
      title: title,
      subtitle: subtitle,
      danger: isDanger,
      onTap: onTap,
    );
  }

  /// 开发环境行：显示当前 Mock/Live 与主机名，可一键测连通性（契约 ping）。
  Widget _buildEnvTile() {
    final label = ApiConfig.isMock
        ? 'MOCK（内置假数据）'
        : '正式 · ${ApiConfig.liveHost ?? ApiConfig.apiBaseUrl}';
    return MenuTile(
      leading: const Icon(Icons.dns,
          size: AppDimens.sp20, color: AppColors.textSoft),
      title: '运行环境',
      subtitle: label,
      onTap: () {},
      trailing: TextButton.icon(
        onPressed: _testConnection,
        icon: const Icon(Icons.wifi_tethering, size: AppDimens.fsSub),
        label: const Text('测试连接', style: TextStyle(fontSize: AppDimens.fsFoot)),
      ),
    );
  }

  Future<void> _testConnection() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await AppServices.instance.api.ping();
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? '服务正常' : '网络异常，暂时连不上服务'),
    ));
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出登录？'),
        content: const Text('退出后需要重新登录才能使用'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              navigator.pop();
              await context.read<AppState>().logout();
              if (!mounted) return;
              // 与"我的"页登出保持一致：回落到根（根会按登录态切到登录页）
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
