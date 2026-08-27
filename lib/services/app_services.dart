import '../network/api_client.dart';
import '../network/token_store.dart';
import '../network/transport.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import 'api_config.dart';
import 'mock/mock_transport.dart';

/// 应用级服务组装根：进程内唯一实例。
///
/// Mock/Live 的差异**只**体现为 Transport 的选择——页面与后续
/// 仓库层对其完全无感知。切环境仅需改 --dart-define 后重启。
class AppServices {
  AppServices._({
    required this.api,
    required this.tokens,
    required this.auth,
    required this.users,
  });

  static AppServices? _instance;

  /// 取当前容器；必须先经 main.dart 调用 [build]。
  static AppServices get instance {
    final s = _instance;
    assert(s != null, 'AppServices 未初始化：请先调用 AppServices.build()');
    return s!;
  }

  /// 幂等构建。SharedPreferences 延迟到首次凭据读写才触碰，
  /// 保证测试环境下构造应用不会拉起插件。
  factory AppServices.build() {
    final existing = _instance;
    if (existing != null) return existing;
    final Transport transport = ApiConfig.isMock
        ? MockTransport()
        : HttpTransport(ApiConfig.apiBaseUrl);
    final tokens = TokenStore();
    final api = ApiClient(transport, tokens);
    return _instance = AppServices._(
      api: api,
      tokens: tokens,
      auth: AuthRepository(api, tokens),
      users: UserRepository(api),
    );
  }

  /// 替换/清空容器，仅供自动化测试隔离使用。
  static void resetForTests([AppServices? replacement]) =>
      _instance = replacement;

  final ApiClient api;
  final TokenStore tokens;
  final AuthRepository auth;
  final UserRepository users;
}
