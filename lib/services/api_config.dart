/// API密钥配置文件
///
/// 密钥不再硬编码在源码里，而是编译期通过 --dart-define 注入：
/// ```
/// 连接真实后端（Live 模式）：
/// flutter run \
///   --dart-define=API_BASE_URL=https://后端地址 \
///   --dart-define=QWEATHER_KEY=你的和风天气Key \
///   --dart-define=QWEATHER_HOST=你的和风天气专属Host \
///   --dart-define=TENCENT_MAP_KEY=你的腾讯地图Key
///
/// 后端未就绪时的本地假数据模式：
/// flutter run --dart-define=MOCK=1
/// ```
/// - 不注入 API_BASE_URL 时自动进入 Mock 模式；提供 BASE_URL 的同时显式传
///   `--dart-define=MOCK=1` 可强制回 Mock。
/// - 未注入天气/地图 Key 时相关功能自动降级（天气用模拟数据、地图逆解析返回"当前位置"）。
class ApiConfig {
  ApiConfig._();

  // ---- 后端服务（Mock/Live 双模式开关）----
  /// 真实后端地址，如 https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String _mockFlag = String.fromEnvironment('MOCK');

  /// 显式强制 Mock（值取 '1' 或 'true' 均可）
  static bool get forceMock =>
      _mockFlag == '1' || _mockFlag.toLowerCase() == 'true';

  /// 当前是否运行在内置 Mock 模式（未配 BASE_URL 也视为 Mock）
  static bool get isMock => forceMock || apiBaseUrl.isEmpty;

  /// 当前是否连接真实后端
  static bool get isLive => !isMock;

  /// Live 模式下用于界面展示的主机名；Mock 模式下为 null
  static String? get liveHost => Uri.tryParse(apiBaseUrl)?.host;

  // ---- 和风天气 ----
  static const String qweatherKey = String.fromEnvironment('QWEATHER_KEY');
  static const String qweatherHost = String.fromEnvironment('QWEATHER_HOST');

  // 腾讯地图
  static const String tencentMapKey = String.fromEnvironment('TENCENT_MAP_KEY');

  /// 是否已配置和风天气（Key 与 Host 都需要）
  static bool get hasQweather => qweatherKey.isNotEmpty && qweatherHost.isNotEmpty;

  /// 是否已配置腾讯地图
  static bool get hasTencentMap => tencentMapKey.isNotEmpty;
}
