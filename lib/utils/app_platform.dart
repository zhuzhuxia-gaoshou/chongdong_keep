import 'package:flutter/foundation.dart';

/// 平台判断收敛处：web 与移动端的条件分支统一走这里，勿再散落 kIsWeb。
class AppPlatform {
  AppPlatform._();

  /// 是否运行在浏览器（Flutter Web 构建）
  static bool get isWeb => kIsWeb;

  /// 是否移动端（Android/iOS）
  static bool get isMobile => !kIsWeb;
}
