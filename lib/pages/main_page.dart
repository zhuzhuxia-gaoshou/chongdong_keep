import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
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
      (emoji: '🏠', label: '首页'),
      (emoji: '🗺️', label: '运动'),
      (emoji: '🛒', label: '商城'),
      (emoji: '💬', label: '消息'),
      (emoji: '👤', label: '我的'),
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
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line, width: 1)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
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
                      emoji: tabs[i].emoji,
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
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.emoji,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: EdgeInsets.symmetric(horizontal: selected ? 13 : 9, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.mintLight : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Text(widget.emoji, style: const TextStyle(fontSize: 21)),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: selected ? 11.5 : 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.mint : AppColors.textMute,
                ),
                child: Text(widget.label),
              ),
            ],
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
