import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_config.dart';
import '../../services/app_services.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
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

  @override
  Widget build(BuildContext context) {
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
                onChanged: (v) => setState(() => _pushEnabled = v),
              ),
            ),
            MenuTile(
              leading: const Icon(Icons.alarm,
                  size: AppDimens.sp20, color: AppColors.textSoft),
              title: '提醒时间',
              subtitle: '晚上 8:00',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: AppDimens.sp16),
          SectionCard(title: '隐私设置', children: [
            _switchTile(Icons.route, '轨迹可见', '好友可查看运动路线', _locationVisible,
                (v) => setState(() => _locationVisible = v)),
            _switchTile(Icons.leaderboard_outlined, '公开排行榜', '参与好友排行榜排名',
                _publicRanking, (v) => setState(() => _publicRanking = v)),
            _switchTile(Icons.straighten, '显示距离', '分享卡片显示运动距离', _showDistance,
                (v) => setState(() => _showDistance = v)),
            _switchTile(Icons.location_on_outlined, '分享位置', '分享卡片显示具体位置',
                _shareLocation, (v) => setState(() => _shareLocation = v)),
          ]),
          const SizedBox(height: AppDimens.sp16),
          SectionCard(title: '数据管理', children: [
            _navTile('导出数据', '导出所有运动记录和宠物档案', Icons.download),
            _navTile('删除运动记录', '删除历史运动记录', Icons.delete_outline),
            _navTile('删除宠物档案', '删除宠物信息（不可恢复）', Icons.pets),
          ]),
          const SizedBox(height: AppDimens.sp16),
          SectionCard(title: '账号', children: [
            _navTile('修改手机号', '当前: 138****8888', Icons.phone),
            _navTile('注销账号', '删除所有数据和账号', Icons.person_off, isDanger: true),
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
      {bool isDanger = false}) {
    return MenuTile(
      leading: Icon(icon,
          size: AppDimens.sp20,
          color: isDanger ? AppColors.coral : AppColors.textSoft),
      title: title,
      subtitle: subtitle,
      danger: isDanger,
      onTap: () {},
    );
  }

  /// 开发环境行：显示当前 Mock/Live 与主机名，可一键测连通性（契约 ping）。
  /// 整行走 MenuTile 获得水波纹；动作收敛在尾部「测试连接」。
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
