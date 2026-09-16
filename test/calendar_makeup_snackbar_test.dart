// D3-4 补签成功轻提示测试（设计夜）：
// SnackBar 体系内升级——珊瑚票点图标（confirmation_num_rounded, iconSm, coral）
// + BrandCopy 补签成功文案（按剩余卡数取变体）。
// 注意：测试由主控终审门禁统一执行（设计夜不运行 flutter 命令）。
import 'package:chongdong_keep/pages/calendar/checkin_calendar_page.dart';
import 'package:chongdong_keep/theme/app_colors.dart';
import 'package:chongdong_keep/theme/app_dimens.dart';
import 'package:chongdong_keep/theme/app_theme.dart';
import 'package:chongdong_keep/utils/brand_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// 用一个按钮把 SnackBar 挂到 ScaffoldMessenger 上，再推进入场动画
  Future<void> showViaMessenger(WidgetTester tester, int remaining) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(makeUpSuccessSnackBar(remaining)),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('show'));
    await tester.pump(); // 调度
    await tester.pump(const Duration(milliseconds: 750)); // 入场动画走完
  }

  /// 把 SnackBar 的自动消隐（默认 4s）推完，避免 FakeAsync 残留定时器
  Future<void> settleSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('补签成功 SnackBar：带珊瑚票点图标（iconSm）+ BrandCopy 文案',
      (tester) async {
    await showViaMessenger(tester, 2);

    expect(find.byType(SnackBar), findsOneWidget, reason: '仍走 SnackBar 体系');
    final icon =
        tester.widget<Icon>(find.byIcon(Icons.confirmation_num_rounded));
    expect(icon.color, AppColors.coral);
    expect(icon.size, AppDimens.iconSm);
    // 文案与页面调用口径一致：seed = remaining（确定性变体）
    expect(find.text(BrandCopy.makeupSuccess(2, seed: 2)), findsOneWidget);
    await settleSnackBar(tester);
  });

  testWidgets('补签成功 SnackBar：剩余卡数进文案（{n} 占位符已替换）', (tester) async {
    await showViaMessenger(tester, 0);
    final text = tester.widget<Text>(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Text)),
    );
    expect(text.data, isNot(contains('{n}')));
    expect(text.data, contains('0'));
    await settleSnackBar(tester);
  });
}
