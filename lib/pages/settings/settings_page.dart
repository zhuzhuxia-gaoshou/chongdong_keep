import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _buildSection('通知提醒', [
            _buildSwitchTile('运动提醒', '每天定时提醒遛狗', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
            _buildSelectTile('提醒时间', '晚上 8:00', () {}),
          ]),
          const SizedBox(height: 16),
          _buildSection('隐私设置', [
            _buildSwitchTile('轨迹可见', '好友可查看运动路线', _locationVisible, (v) => setState(() => _locationVisible = v)),
            _buildSwitchTile('公开排行榜', '参与好友排行榜排名', _publicRanking, (v) => setState(() => _publicRanking = v)),
            _buildSwitchTile('显示距离', '分享卡片显示运动距离', _showDistance, (v) => setState(() => _showDistance = v)),
            _buildSwitchTile('分享位置', '分享卡片显示具体位置', _shareLocation, (v) => setState(() => _shareLocation = v)),
          ]),
          const SizedBox(height: 16),
          _buildSection('数据管理', [
            _buildNavTile('导出数据', '导出所有运动记录和宠物档案', Icons.download),
            _buildNavTile('删除运动记录', '删除历史运动记录', Icons.delete_outline),
            _buildNavTile('删除宠物档案', '删除宠物信息（不可恢复）', Icons.pets),
          ]),
          const SizedBox(height: 16),
          _buildSection('账号', [
            _buildNavTile('修改手机号', '当前: 138****8888', Icons.phone),
            _buildNavTile('注销账号', '删除所有数据和账号', Icons.person_off, isDanger: true),
          ]),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () {
                _showLogoutConfirm();
              },
              child: const Text('退出登录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.coral)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('宠动Keep v1.0.0', style: TextStyle(fontSize: 11, color: AppColors.textMute)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSoft)),
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.mint,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectTile(String title, String value, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
              Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textSoft)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textMute),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile(String title, String subtitle, IconData icon, {bool isDanger = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isDanger ? AppColors.coral : AppColors.textSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDanger ? AppColors.coral : AppColors.text)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textMute)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textMute),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出登录？'),
        content: const Text('退出后需要重新登录才能使用'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
