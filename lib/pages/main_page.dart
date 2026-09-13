import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../services/app_state.dart';
import '../utils/app_platform.dart';
import 'home/home_page.dart';
import 'walk/walk_page.dart';
import 'mall/mall_page.dart';
import 'profile/profile_page.dart';

/// 主框架：IndexedStack 五页 + 悬浮毛玻璃 Dock（2026-09 质感升级）。
/// extendBody 让页面内容延伸到 Dock 下方，毛玻璃才有"透"的质感；
/// 各页面底部需预留 ~96px 的 Dock 遮挡区。
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
      // 2026-09-13 事故排查：曾用 extendBody 让内容穿到 Dock 下方配合毛玻璃，
      // 真机出现「Dock 可见、页面内容整页空白」。两变量（BackdropFilter+extendBody）
      // 均已移除，Dock 走标准 bottomNavigationBar 渲染路径，悬浮造型保留。
      body: IndexedStack(
        index: state.currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.sp16, 0, AppDimens.sp16, AppDimens.sp12),
        // 影画在 ClipRRect 外层，否则会被裁掉
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.rXxl),
            boxShadow: AppDimens.shadowFloat,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.rXxl),
            // 2026-09-13 事故：此处曾用 BackdropFilter 毛玻璃，部分机型 GPU
            // 对 saveLayer 合成异常会连带丢掉整个 body 图层（Dock 可见/页面空白）。
            // 改为近实心底，悬浮造型保留、渲染路径回归普通 Container。
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.rXxl),
                border: Border.all(
                  color: AppColors.line.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.sp8, horizontal: AppDimens.sp4),
                  child: Row(
                    children: [
                      for (int i = 0; i < tabs.length; i++)
                        Expanded(
                          child: _DockItem(
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
          ),
        ),
      ),
    );
  }
}

/// Dock 导航项：薄荷实心胶囊选中态（白字白图标）+ 按压缩放 + 触感反馈
class _DockItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
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
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Semantics(
          label: widget.label,
          button: true,
          selected: selected,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: EdgeInsets.symmetric(
                horizontal: selected ? AppDimens.sp16 : AppDimens.sp8,
                vertical: AppDimens.sp8,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.mint : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimens.rFull),
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
                      size: 21,
                      color: selected ? Colors.white : AppColors.textMute,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      fontSize: AppDimens.fsMicro + 1,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.textMute,
                    ),
                    child: Text(widget.label),
                  ),
                ],
              ),
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
