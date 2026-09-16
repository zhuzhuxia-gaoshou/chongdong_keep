import 'package:flutter/material.dart';

/// 成功时刻微庆祝（D3 设计夜「克制的愉悦感」）：[celebrate] 信号
/// false→true 翻转时，子树播放一次 scale 弹跳（1.0 → [peak] → 1.0，
/// Spring 感落定）。典型场景：日历页「今日从未打卡 → 已打卡」点亮瞬间。
///
/// 红线自查（DESIGN_SYSTEM.md §0.2）：
/// - **纯 scale 动效**：无任何透明度（FadeTransition/AnimatedOpacity 禁用）；
/// - **初始可见性不依赖动画**：控制器静止时序列值恒为 1.0——组件一构建
///   就是完整可见的，动画只是锦上添花（09-13 教训）；
/// - **只由明确状态翻转驱动**：首次挂载即 celebrate=true 属历史态，静默
///   呈现绝不重播；恒 true 不重复触发。
///
/// AnimationController 用法与 PressableScale 同款（单 tick / late final /
/// dispose），不发明新写法。
class CelebrationScale extends StatefulWidget {
  const CelebrationScale({
    super.key,
    required this.celebrate,
    required this.child,
    this.peak = 1.15,
  });

  /// 庆祝请求信号：false→true 翻转触发一次弹跳；挂载时即为 true 不触发。
  final bool celebrate;

  final Widget child;

  /// 弹跳峰值缩放（默认 1.15，克制幅度——庆祝但不抢戏）
  final double peak;

  @override
  State<CelebrationScale> createState() => _CelebrationScaleState();
}

class _CelebrationScaleState extends State<CelebrationScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  /// 弹跳序列：起步与落点都在 1.0（静止态即完全还原）；
  /// 末段 easeOutBack 带轻微过冲，产生「弹一下再稳住」的 Spring 落定感。
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: widget.peak),
      weight: 0.4,
    ).chain(CurveTween(curve: Curves.easeOut)),
    TweenSequenceItem(
      tween: Tween(begin: widget.peak, end: 1.0),
      weight: 0.6,
    ).chain(CurveTween(curve: Curves.easeOutBack)),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      // 播完即复位到序列起点：scale 回到 1.0，格子还原静态完整可见
      if (status == AnimationStatus.completed) {
        _controller.value = 0;
      }
    });
  }

  @override
  void didUpdateWidget(covariant CelebrationScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只认 false→true 上升沿；播放中忽略重复请求（单飞）
    if (!oldWidget.celebrate && widget.celebrate && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
