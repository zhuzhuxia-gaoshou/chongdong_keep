import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_services.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'pages/auth/login_page.dart';
import 'pages/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppServices.build(); // 组装网络/仓库容器（Mock 或 Live 由编译期开关决定）
  runApp(const ChongDongKeepApp());
}

class ChongDongKeepApp extends StatelessWidget {
  const ChongDongKeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: _AppLifecycleObserver(
        child: MaterialApp(
          title: '宠动Keep',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Consumer<AppState>(
            builder: (context, state, _) {
              if (state.isLoggedIn) {
                return const MainPage();
              }
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}

/// 监听应用生命周期：切后台恢复时立即补传弱网期间积压的运动记录
class _AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const _AppLifecycleObserver({required this.child});

  @override
  State<_AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<_AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AppState>().retryPendingUploadsNow();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
