// D3-1 打卡成功微庆祝组件测试（设计夜）：
// 守三条红线——① 静止/历史态子树完整可见且 scale 恒 1.0（初始可见性
// 不依赖动画推进）；② 纯 scale、无透明度组件；③ 仅 false→true 翻转
// 触发一次弹跳，结束回到 1.0。
// 注意：测试由主控终审门禁统一执行（设计夜不运行 flutter 命令）。
import 'package:chongdong_keep/widgets/celebration_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// 读取 CelebrationScale 子树内的 ScaleTransition 当前缩放值
  double scaleValue(WidgetTester tester) {
    final transition = tester.widget<ScaleTransition>(find.descendant(
      of: find.byType(CelebrationScale),
      matching: find.byType(ScaleTransition),
    ));
    return transition.scale.value;
  }

  Widget host({required bool celebrate}) => MaterialApp(
        home: Scaffold(
          body: CelebrationScale(
            celebrate: celebrate,
            child: const Text('15'),
          ),
        ),
      );

  testWidgets('无庆祝信号时格子静态可见，scale 恒 1.0（红线2：初始可见性不依赖动画）',
      (tester) async {
    await tester.pumpWidget(host(celebrate: false));
    expect(find.text('15'), findsOneWidget, reason: '子树构建出来即完整可见');
    expect(scaleValue(tester), 1.0);
    await tester.pump(const Duration(seconds: 1));
    expect(scaleValue(tester), 1.0, reason: '无动画推进，静止态保持 1.0');
  });

  testWidgets('首次挂载即 celebrate=true 属历史态：不播放，静态 1.0（历史格子绝不触发）',
      (tester) async {
    await tester.pumpWidget(host(celebrate: true));
    expect(find.text('15'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(scaleValue(tester), 1.0, reason: '挂载即为 true 不触发弹跳');
  });

  testWidgets('false→true 翻转触发弹跳：动画存在（forward）且结束回到 1.0',
      (tester) async {
    await tester.pumpWidget(host(celebrate: false));
    expect(find.byType(ScaleTransition), findsOneWidget);

    await tester.pumpWidget(host(celebrate: true)); // 明确状态翻转
    final transition = tester.widget<ScaleTransition>(find.descendant(
      of: find.byType(CelebrationScale),
      matching: find.byType(ScaleTransition),
    ));
    expect(transition.scale.status, AnimationStatus.forward,
        reason: '翻转后动画正在推进');

    await tester.pump(const Duration(milliseconds: 460));
    expect(scaleValue(tester), 1.0, reason: '弹跳结束落回 1.0，格子还原静态');
  });

  testWidgets('播放结束后重复保持 true 不重播（只认上升沿）', (tester) async {
    await tester.pumpWidget(host(celebrate: false));
    await tester.pumpWidget(host(celebrate: true));
    await tester.pump(const Duration(milliseconds: 460)); // 播完
    expect(scaleValue(tester), 1.0);

    await tester.pumpWidget(host(celebrate: true)); // 恒 true，无上升沿
    await tester.pump(const Duration(milliseconds: 100));
    expect(scaleValue(tester), 1.0, reason: '没有第二次弹跳');
  });

  testWidgets('纯 scale 红线：组件子树内不出现任何透明度动画组件', (tester) async {
    await tester.pumpWidget(host(celebrate: false));
    await tester.pumpWidget(host(celebrate: true));
    await tester.pump(const Duration(milliseconds: 100)); // 动画中
    // 断言收窄在组件子树内：MaterialApp 框架内部树不受本组件约束
    bool hasInSubtree(Type t) => find
        .descendant(of: find.byType(CelebrationScale), matching: find.byType(t))
        .evaluate()
        .isNotEmpty;
    expect(hasInSubtree(FadeTransition), isFalse, reason: '透明度类动效禁用');
    expect(hasInSubtree(AnimatedOpacity), isFalse);
    expect(hasInSubtree(ScaleTransition), isTrue, reason: '弹跳载体是纯 scale');
  });
}
