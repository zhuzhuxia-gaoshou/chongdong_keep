/// API密钥配置文件
///
/// 密钥不再硬编码在源码里，而是编译期通过 --dart-define 注入：
/// ```
/// flutter run \
///   --dart-define=QWEATHER_KEY=你的和风天气Key \
///   --dart-define=QWEATHER_HOST=你的和风天气专属Host \
///   --dart-define=TENCENT_MAP_KEY=你的腾讯地图Key
/// ```
/// 未注入时相关功能自动降级（天气用模拟数据、地图逆解析返回"当前位置"）。
class ApiConfig {
  ApiConfig._();

  // 和风天气
  static const String qweatherKey = String.fromEnvironment('QWEATHER_KEY');
  static const String qweatherHost = String.fromEnvironment('QWEATHER_HOST');

  // 腾讯地图
  static const String tencentMapKey = String.fromEnvironment('TENCENT_MAP_KEY');

  /// 是否已配置和风天气（Key 与 Host 都需要）
  static bool get hasQweather => qweatherKey.isNotEmpty && qweatherHost.isNotEmpty;

  /// 是否已配置腾讯地图
  static bool get hasTencentMap => tencentMapKey.isNotEmpty;
}
