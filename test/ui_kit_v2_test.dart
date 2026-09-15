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
          icon: Icons.dns_rounded,
          background: AppColors.sand,
          color: AppColors.textSoft,
        ),
      ),
    ));
    final box = tester.widget<Container>(
        find.descendant(of: find.byType(IconChip), matching: find.byType(Container)));
    expect(box.constraints?.maxWidth, 36);
    final icon = tester.widget<Icon>(find.byIcon(Icons.dns_rounded));
    expect(icon.color, AppColors.textSoft);
  });

  test('numericStat：20px 中粗紧字距（数据数字退役 w800 的合法出口）', () {
    final style = AppText.numericStat(color: AppColors.mint);
    expect(style.fontSize, AppDimens.fsStat);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.letterSpacing, lessThan(0));
  });

  // ====== D1-3 AppChip 统一胶囊 ======

  BoxDecoration chipDecoration(WidgetTester tester) {
    final box = tester.widget<Container>(find.descendant(
        of: find.byType(AppChip), matching: find.byType(Container)));
    return box.decoration! as BoxDecoration;
  }

  testWidgets('AppChip：选中态 mintLight 底 + mint 1.5 描边；未选中 card 底 + line 1 描边',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AppChip(label: '柯基', selected: true)),
    ));
    var deco = chipDecoration(tester);
    expect(deco.color, AppColors.mintLight);
    expect((deco.border! as Border).top.color, AppColors.mint);
    expect((deco.border! as Border).top.width, 1.5);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AppChip(label: '柯基')),
    ));
    deco = chipDecoration(tester);
    expect(deco.color, AppColors.card);
    expect((deco.border! as Border).top.color, AppColors.line);
    expect((deco.border! as Border).top.width, 1);
    // 无 onTap 时不引入 InkWell（缩放物理交给外层 PressableScale）
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('AppChip：显式 tonal 配色覆盖双态默认（商城薄荷标签/日历珊瑚票点）',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AppChip(
          label: '补签卡',
          message: '点日历上带票点的过去日期就能补上哦',
          leading: Icon(Icons.confirmation_num_rounded,
              size: AppDimens.iconMd, color: AppColors.coral),
          background: AppColors.coralLight,
          borderColor: AppColors.coralLine,
          textColor: AppColors.coral,
          radius: AppDimens.rMd,
        ),
      ),
    ));
    final deco = chipDecoration(tester);
    expect(deco.color, AppColors.coralLight);
    expect((deco.border! as Border).top.color, AppColors.coralLine);
    expect(deco.borderRadius, BorderRadius.circular(AppDimens.rMd));
    // 说明条形态：主副文案同时渲染
    expect(find.text('补签卡'), findsOneWidget);
    expect(find.text('点日历上带票点的过去日期就能补上哦'), findsOneWidget);
    expect(find.byIcon(Icons.confirmation_num_rounded), findsOneWidget);
    final title = tester.widget<Text>(find.text('补签卡'));
    expect(title.style?.color, AppColors.coral);
    expect(title.style?.fontSize, AppDimens.fsFoot);
  });

  testWidgets('AppChip：传 onTap 时带 InkWell 且可点击', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppChip(label: '零食', onTap: () => tapped = true),
      ),
    ));
    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.text('零食'));
    expect(tapped, isTrue);
  });

  // ====== D1-7 ErrorRetry / LoadingView ======

  testWidgets('ErrorRetry：文案+默认断网图标+重试钮可点；无 onRetry 时不渲染按钮',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ErrorRetry(
            message: '加载失败，请重试',
            onRetry: () => retried = true,
          ),
        ),
      ),
    ));
    expect(find.text('加载失败，请重试'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '重试'));
    expect(retried, isTrue);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: ErrorRetry(message: '服务暂不可用'))),
    ));
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('LoadingView：品牌色进度圈；message 为空不渲染文案，有值则渲染',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: LoadingView())),
    ));
    final spinner = tester
        .widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
    expect(spinner.color, AppColors.mint);
    expect(find.byType(Text), findsNothing);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: LoadingView(message: '地图加载中...'))),
    ));
    expect(find.text('地图加载中...'), findsOneWidget);
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
