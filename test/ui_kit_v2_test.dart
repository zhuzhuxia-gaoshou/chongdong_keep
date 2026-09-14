import 'package:chongdong_keep/theme/app_colors.dart';
import 'package:chongdong_keep/theme/app_dimens.dart';
import 'package:chongdong_keep/theme/app_theme.dart';
import 'package:chongdong_keep/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chongdong_keep/network/api_client.dart';
import 'package:chongdong_keep/network/api_exception.dart';
import 'package:chongdong_keep/network/token_store.dart';
import 'package:chongdong_keep/repositories/auth_repository.dart';
import 'package:chongdong_keep/repositories/user_repository.dart';
import 'package:chongdong_keep/services/mock/mock_transport.dart';

void main() {
  // ====== 质感底座 v2 组件 ======

  testWidgets('EmptyState：渲染标题/文案，actionLabel 为空时不渲染按钮',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EmptyState(
            emoji: '💬',
            title: '暂时没有新消息',
            message: '敬请期待哦',
          ),
        ),
      ),
    ));
    expect(find.text('暂时没有新消息'), findsOneWidget);
    expect(find.text('敬请期待哦'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('EmptyState：带 action 时渲染按钮且可点击', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EmptyState(
            emoji: '🐾',
            title: '还没有宠物',
            actionLabel: '去添加',
            onAction: () => tapped = true,
          ),
        ),
      ),
    ));
    expect(find.byType(ElevatedButton), findsOneWidget);
    await tester.tap(find.text('去添加'));
    expect(tapped, isTrue);
  });

  testWidgets('IconChip：尺寸与着色正确', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: IconChip(
          icon: Icons.dns,
          background: AppColors.sand,
          color: AppColors.textSoft,
        ),
      ),
    ));
    final box = tester.widget<Container>(
        find.descendant(of: find.byType(IconChip), matching: find.byType(Container)));
    expect(box.constraints?.maxWidth, 36);
    final icon = tester.widget<Icon>(find.byIcon(Icons.dns));
    expect(icon.color, AppColors.textSoft);
  });

  test('numericStat：20px 中粗紧字距（数据数字退役 w800 的合法出口）', () {
    final style = AppText.numericStat(color: AppColors.mint);
    expect(style.fontSize, AppDimens.fsStat);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.letterSpacing, lessThan(0));
  });

  // ====== ⑦b 注销链路（Mock 层） ======

  Future<(ApiClient, TokenStore)> stack() async {
    SharedPreferences.setMockInitialValues({});
    final store = TokenStore(prefs: SharedPreferences.getInstance());
    final transport = MockTransport(delay: Duration.zero);
    return (ApiClient(transport, store), store);
  }

  test('⑦b deleteMe：DELETE /users/me 携 confirm:true → 信封 code=0', () async {
    final (client, store) = await stack();
    final auth = AuthRepository(client, store);
    await auth.sendSmsCode('13800008000');
    await auth.login('13800008000', MockTransport.fixedSmsCode);

    await UserRepository(client).deleteMe(); // 不抛即通过

    // 注销后同 token 再读 /users/me → 40100（与服务端 jwt.validate 行为对齐）
    await expectLater(
      UserRepository(client).fetchMe(),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', kCodeAccessExpired)),
    );
  });

  test('⑦b deleteMe：缺 confirm → 40001（契约必显式确认）', () async {
    final (client, store) = await stack();
    final auth = AuthRepository(client, store);
    await auth.sendSmsCode('13800008000');
    await auth.login('13800008000', MockTransport.fixedSmsCode);

    final raw = await client.delete('/api/v1/users/me');
    expect(raw['code'], kCodeParamInvalid);
  });
}
