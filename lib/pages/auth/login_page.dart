import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../network/api_exception.dart';
import '../../services/app_services.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _agreed = false;
  bool _sendingCode = false;
  bool _busy = false;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_phoneController.text.length != 11) {
      messenger.showSnackBar(
        const SnackBar(content: Text('请输入11位手机号')),
      );
      return;
    }
    if (_sendingCode || _countdown > 0) return;
    setState(() => _sendingCode = true);
    try {
      await AppServices.instance.auth.sendSmsCode(_phoneController.text);
      if (!mounted) return;
      setState(() => _countdown = 60); // 成功后才启动倒计时
      _tick();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
        if (_countdown > 0) _tick();
      }
    });
  }

  Future<void> _login() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_agreed) {
      messenger.showSnackBar(
        const SnackBar(content: Text('请先同意用户协议和隐私政策')),
      );
      return;
    }
    if (_phoneController.text.length != 11 || _codeController.text.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号和验证码')),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await AppServices.instance.auth
          .login(_phoneController.text, _codeController.text);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(result.isNewUser ? '欢迎加入宠动Keep！' : '欢迎回来'),
      ));
      // ignore: use_build_context_synchronously
      context.read<AppState>().applyLogin(result.user);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.sp16),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(AppDimens.rXl),
                ),
                child: const Center(
                  child: Text('🐾', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '宠动Keep',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '和宝贝一起动起来',
                style: TextStyle(fontSize: 13, color: AppColors.textSoft),
              ),
              const SizedBox(height: 40),
              // 手机号
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('手机号', style: TextStyle(fontSize: AppDimens.fsFoot, color: AppColors.textSoft, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    decoration: const InputDecoration(
                      hintText: '请输入手机号',
                      counterText: '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sp16),
              // 验证码
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('验证码', style: TextStyle(fontSize: AppDimens.fsFoot, color: AppColors.textSoft, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            hintText: '请输入验证码',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap:
                            (_countdown == 0 && !_sendingCode) ? _sendCode : null,
                        child: Container(
                          height: 48, // 与主题输入框精确等高
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: AppDimens.sp12),
                          decoration: BoxDecoration(
                            color: (_countdown == 0 && !_sendingCode)
                                ? AppColors.mintLight
                                : AppColors.sand,
                            borderRadius: BorderRadius.circular(AppDimens.rMd),
                          ),
                          child: Text(
                            _sendingCode
                                ? '发送中…'
                                : (_countdown == 0 ? '获取验证码' : '${_countdown}s'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: (_countdown == 0 && !_sendingCode)
                                  ? AppColors.mint
                                  : AppColors.textMute,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 登录按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _login,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.pets, size: 16),
                  label: Text(_busy ? '登录中…' : '登录 / 注册'),
                ),
              ),
              const SizedBox(height: 16),
              // 协议
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 4px 透明热区，实际点击面积 ≥26px
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.sp4),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _agreed ? AppColors.mint : AppColors.textMute, width: 1.5),
                          color: _agreed ? AppColors.mint : Colors.transparent,
                        ),
                        child: _agreed
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sp4),
                  Flexible(
                    child: Text.rich(
                      softWrap: true,
                      TextSpan(
                        text: '登录即同意',
                        style: TextStyle(fontSize: 11, color: AppColors.textSoft),
                        children: [
                          TextSpan(text: '《用户协议》', style: TextStyle(color: AppColors.mint)),
                          TextSpan(text: '和', style: TextStyle(color: AppColors.textSoft)),
                          TextSpan(text: '《隐私政策》', style: TextStyle(color: AppColors.mint)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '微信登录将在二期上线',
                style: TextStyle(fontSize: 10, color: AppColors.textMute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
