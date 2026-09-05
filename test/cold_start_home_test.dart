// 首页冷启动回归测试（2026-09-05 真机红屏事故的守卫）：
// 冷启动 + 本地缓存（用户/宠物含猫/历史记录）→ 构建首页。
// 事故根因：运动入口 Row 用 CrossAxisAlignment.stretch，在滚动视图无界高度下
// 产生 infinite height 渲染崩溃——布局类改动必须跑本用例。
//
// Mock 模式（默认）：flutter test test/cold_start_home_test.dart
// Live 模式（连真实服务器 + 真实账号数据）：
//   flutter test test/cold_start_home_test.dart \
//     --dart-define=API_BASE_URL=http://47.104.129.148 \
//     --dart-define=REPRO_PHONE=手机号
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chongdong_keep/main.dart';
import 'package:chongdong_keep/pages/home/home_page.dart';
import 'package:chongdong_keep/repositories/auth_repository.dart' show LoginResult;
import 'package:chongdong_keep/services/api_config.dart';
import 'package:chongdong_keep/services/app_services.dart';
import 'package:chongdong_keep/services/app_state.dart';

void main() {
  testWidgets(
    '冷启动+缓存数据构建首页（真机红屏回归守卫）',
    (tester) async {
      // 关键1：解除测试框架的 HTTP 拦截（默认全部返回 400），Live 模式要真连服务器
      // 关键2：AppServices.build() 必须在 runAsync 内做——TokenStore 的
      // SharedPreferences future 在 FakeAsync 区外永远等不到时间推进。
      await tester.runAsync(() async {
        // 模拟真机冷启动：本地缓存里有上次登录的用户、宠物（含猫）、历史记录
        final user = {
          'id': 'u_cache',
          'phone': '178****8269',
          'nickname': '测试官',
          'avatarUrl': null,
          'createdAt': '2026-09-01T10:00:00.000Z',
          'totalExerciseCount': 12,
          'streakDays': 3,
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
        final cat = {
          'id': 'pet_cat',
          'name': '花花',
          'species': 1,
          'breed': '英短',
          'gender': 1,
          'ageYears': 1,
          'weight': 4.0,
          'birthDate': '2025-06-01T00:00:00.000Z',
          'avatarUrl': null,
          'allergies': [],
          'chronicConditions': [],
          'isNeutered': false,
          'isVaccinated': true,
          'emergencyContact': null,
        };
        final walkRecord = {
          'id': 'r_cache_walk',
          'clientRecordId': 'cache-walk-1',
          'petId': 'pet_dog',
          'userId': 'u_cache',
          'type': 0,
          'catPlayType': null,
          'startTime': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'endTime':
              DateTime.now().subtract(const Duration(hours: 2, minutes: -30)).toIso8601String(),
          'duration': 1800,
          'distance': 1.2,
          'steps': 2000,
          'route': [],
          'locationName': '附近公园',
          'startPhotoPath': null,
          'startPhotoUrl': null,
          'isCompleted': true,
          'isManual': false,
        };
        final catRecord = {
          'id': 'r_cache_cat',
          'clientRecordId': 'cache-cat-1',
          'petId': 'pet_cat',
          'userId': 'u_cache',
          'type': 1,
          'catPlayType': 'featherWand',
          'startTime': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
          'endTime':
              DateTime.now().subtract(const Duration(hours: 1, minutes: -15)).toIso8601String(),
          'duration': 900,
          'distance': 0,
          'steps': 0,
          'route': [],
          'locationName': null,
          'startPhotoPath': null,
          'startPhotoUrl': null,
          'isCompleted': true,
          'isManual': true,
        };
        SharedPreferences.setMockInitialValues({
          'user': jsonEncode(user),
          'pets': [jsonEncode(dog), jsonEncode(cat)],
          'records': [jsonEncode(walkRecord), jsonEncode(catRecord)],
          'auth_access_token': 'stale-access',
          'auth_refresh_token': 'stale-refresh',
          'auth_expires_at_ms': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
        });
        HttpOverrides.global = null;
        AppServices.build();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      debugPrint('STEP2 services-built');
      await tester.pumpWidget(const ChongDongKeepApp());
      debugPrint('STEP3 app-pumped');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      debugPrint('STEP4 init-done');

      // 冷启动路径：缓存里已有登录态则直接走（同真机）；否则仓库层登录
      final appState =
          // ignore: use_build_context_synchronously
          tester.element(find.byType(MaterialApp)).read<AppState>();
      if (!appState.isLoggedIn) {
        final phone = const String.fromEnvironment(
          'REPRO_PHONE',
          defaultValue: '13800001234',
        );
        final code = ApiConfig.isMock ? '123456' : '8888';
        late final LoginResult loginResult;
        await tester.runAsync(() async {
          await AppServices.instance.auth.sendSmsCode(phone);
          loginResult = await AppServices.instance.auth.login(phone, code);
        });
        await tester.runAsync(() => appState.applyLogin(loginResult.user));
      }
      debugPrint('STEP8 applyLogin-done');

      // 反复 pump 让首页完成构建（网络/动画逐帧推进）
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(
        find.byType(HomePage),
        findsOneWidget,
        reason: '登录后应渲染首页；若首页构建抛异常，本用例上方会输出完整堆栈',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: false,
  );
}
