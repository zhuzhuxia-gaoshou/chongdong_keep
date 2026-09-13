import 'package:flutter/material.dart';

/// 按压物理：按下轻微缩放、松手弹簧回弹（2026-09 质感底座）。
/// 用于卡片/入口等可点表面，替代生硬的整片水纹反馈；
/// 与 InkWell 波纹可叠加（内部仍是 GestureDetector，不影响子级自带 InkWell）。
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: widget.scale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (widget.onTap == null) return;
    down ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _press(true),
      onTapUp: (_) => _press(false),
      onTapCancel: () => _press(false),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
