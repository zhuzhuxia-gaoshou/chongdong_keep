// 宠动Keep 基础冒烟测试：
// 验证应用入口能正常构建并渲染，而不是报错。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chongdong_keep/main.dart';

void main() {
  testWidgets('应用可以正常构建', (WidgetTester tester) async {
    await tester.pumpWidget(const ChongDongKeepApp());
    await tester.pump();

    // 确认 MaterialApp 已渲染
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}