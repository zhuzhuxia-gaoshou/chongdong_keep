import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../services/app_state.dart';
import 'home/home_page.dart';
import 'walk/walk_page.dart';
import 'mall/mall_page.dart';
import 'profile/profile_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tabs = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: '首页'),
      (icon: Icons.map_outlined, activeIcon: Icons.map, label: '运动'),
      (icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: '商城'),
      (icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: '消息'),
      (icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
    ];
    final pages = [
      const HomePage(),
      const WalkPage(),
      const MallPage(),
      const _MessagePage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: state.currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.line, width: 1)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimens.rXl),
            topRight: Radius.circular(AppDimens.rXl),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabItem(
                      icon: tabs[i].icon,
                      activeIcon: tabs[i].activeIcon,
                      label: tabs[i].label,
                      selected: state.currentIndex == i,
                      onTap: () => state.setIndex(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部导航项：按压缩放 + 选中胶囊底色/弹跳动效 + 触感反馈
class _TabItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick(); // 轻微触感反馈
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Semantics(
          label: widget.label,
          button: true,
          selected: selected,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.sp4),
            padding: EdgeInsets.symmetric(
                horizontal: selected ? AppDimens.sp12 : AppDimens.sp8,
                vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.mintLight : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimens.rFull),
              border: selected
                  ? Border.all(color: AppColors.mintLine, width: 1)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected ? widget.activeIcon : widget.icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: selected ? AppColors.mint : AppColors.textMute,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize:
                        selected ? AppDimens.fsCaption + 1 : AppDimens.fsCaption,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.mint : AppColors.textMute,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 消息页占位
class _MessagePage extends StatelessWidget {
  const _MessagePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('暂无消息', style: TextStyle(color: AppColors.textSoft)),
          ],
        ),
      ),
    );
  }
}
