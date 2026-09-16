// D3-2 首页连胜里程碑徽标测试（设计夜）：
// streak 恰好命中 3/7/14/30 时连胜卡出现奖杯徽标（纯静态、零动画），
// 文案取 BrandCopy.streakMilestones；非命中日（如 2）不出现。
// 基架沿用 cold_start_home_test 的模式：AppServices.build 与 SharedPreferences
// 读写放在 runAsync 内；Mock 模式下 AppState.init 不触发任何网络同步。
// 注意：测试由主控终审门禁统一执行（设计夜不运行 flutter 命令）。
import 'dart:convert';

import 'package:chongdong_keep/pages/home/home_page.dart';
import 'package:chongdong_keep/services/app_services.dart';
import 'package:chongdong_keep/services/app_state.dart';
import 'package:chongdong_keep/utils/brand_copy.dart';
import 'package:chongdong_keep/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// 冷启动缓存：一位用户 + 一只狗（首页需要至少一只宠物才渲染连胜卡）
  Future<AppState> bootState(WidgetTester tester, {required int streak}) async {
    late final AppState state;
    await tester.runAsync(() async {
      final user = {
        'id': 'u_badge',
        'phone': '13800000000',
        'nickname': '测试官',
        'avatarUrl': null,
        'createdAt': '2026-09-01T10:00:00.000Z',
        'totalExerciseCount': 12,
        'streakDays': streak,
        'signCardCount': 3,
      };
      final dog = {
        'id': 'pet_dog',
        'name': '旺财',
        'species': 0,
        'breed': '金毛',
        'gender': 0,
        'ageYears': 2,
        'weight': 20.0,
        'birthDate': '2024-05-01T00:00:00.000Z',
        'avatarUrl': null,
        'allergies': [],
        'chronicConditions': [],
        'isNeutered': true,
        'isVaccinated': true,
        'emergencyContact': null,
      };
      SharedPreferences.setMockInitialValues({
        'user': jsonEncode(user),
        'pets': [jsonEncode(dog)],
        'records': <String>[],
      });
      AppServices.build();
      state = AppState();
      await state.init();
    });
    return state;
  }

  Future<void> pumpHome(WidgetTester tester, AppState state) async {
    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: HomePage()),
    ));
    // 让天气加载等异步分支走完（服务在测试环境安全降级）
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('streak=2：非里程碑，连胜卡无奖杯徽标', (tester) async {
    final state = await bootState(tester, streak: 2);
    await pumpHome(tester, state);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('连续打卡'), findsOneWidget, reason: '连胜卡在');
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(find.text('连胜里程碑'), findsNothing);
  });

  testWidgets('streak=3：命中里程碑，出现奖杯徽标 + BrandCopy 3 天专属句',
      (tester) async {
    final state = await bootState(tester, streak: 3);
    await pumpHome(tester, state);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.text('连胜里程碑'), findsOneWidget);
    expect(find.text(BrandCopy.streakMilestones[3]!), findsOneWidget);
    // 纯静态：徽标是 AppChip 说明条，不挂任何动画组件
    final chip = find.ancestor(
      of: find.text('连胜里程碑'),
      matching: find.byType(AppChip),
    );
    expect(chip, findsOneWidget);
    expect(
      find.descendant(of: chip, matching: find.byType(ScaleTransition)),
      findsNothing,
    );
  });

  testWidgets('streak=7：命中里程碑，出现奖杯徽标 + BrandCopy 7 天专属句',
      (tester) async {
    final state = await bootState(tester, streak: 7);
    await pumpHome(tester, state);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.text(BrandCopy.streakMilestones[7]!), findsOneWidget);
  });

  testWidgets('streak=8：过档不滞留——上一档 7 天徽标不再显示（下一档也不预告）',
      (tester) async {
    final state = await bootState(tester, streak: 8);
    await pumpHome(tester, state);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(find.text(BrandCopy.streakMilestones[7]!), findsNothing);
    expect(find.text(BrandCopy.streakMilestones[14]!), findsNothing);
  });
}
