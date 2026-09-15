import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../network/api_exception.dart';
import '../../services/app_services.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 登录页（2026-09-15 品牌时刻重做）：
/// 渐变 logo 浮起 + 品牌渐变标题 + 表单白卡 + 全格间距。
/// 红线自查：无 stretch / 无松约束 Center 包整页 / 无透明度入场动效。
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
        const SnackBar(content: Text('手机号还没输够 11 位哦')),
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
        const SnackBar(content: Text('先勾一下用户协议和隐私政策，就能继续啦')),
      );
      return;
    }
    if (_phoneController.text.length != 11 || _codeController.text.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('手机号或验证码好像没填对呢，再核对一下哦')),
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
    final codeReady = _countdown == 0 && !_sendingCode;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.sp24),
          child: Column(
            children: [
              const SizedBox(height: AppDimens.sp60),
              // 品牌图章：渐变圆 + 柔和薄荷辉光，浮起于画布
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.heroGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mint.withValues(alpha: 0.35),
                      offset: const Offset(0, 10),
                      blurRadius: 28,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🐾', style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: AppDimens.sp20),
              // 品牌名：字重交响——品牌词允许重字重，紧字距
              const Text(
                '宠动Keep',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: AppDimens.sp8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppDimens.rFull),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppDimens.sp8),
                    child: Text(
                      '和宝贝一起动起来',
                      style: TextStyle(
                        fontSize: AppDimens.fsBodyMid,
                        letterSpacing: 2,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppDimens.rFull),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sp40),
              // 表单白卡：两张输入聚拢成一张浮起面板
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.sp16),
                decoration: AppDimens.cardBox(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('手机号'),
                    const SizedBox(height: AppDimens.sp8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      decoration: const InputDecoration(
                        hintText: '你的手机号',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: AppDimens.sp16),
                    _fieldLabel('验证码'),
                    const SizedBox(height: AppDimens.sp8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              hintText: '短信验证码',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimens.sp8),
                        // 压缩感反馈交给配色态变化（克制原则：不加动效）
                        GestureDetector(
                          onTap: codeReady ? _sendCode : null,
                          child: Container(
                            height: 48, // 与主题输入框精确等高
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.sp12),
                            decoration: BoxDecoration(
                              color: codeReady
                                  ? AppColors.mint
                                  : AppColors.sand,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.rMd),
                            ),
                            child: Text(
                              _sendingCode
                                  ? '发送中…'
                                  : (_countdown == 0
                                      ? '获取验证码'
                                      : '${_countdown}s'),
                              style: TextStyle(
                                fontSize: AppDimens.fsFoot,
                                fontWeight: FontWeight.w700,
                                color: codeReady
                                    ? AppColors.onAccent
                                    : AppColors.textMute,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.sp24),
              // 登录主按钮
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
                      : const Icon(Icons.pets_rounded, size: AppDimens.iconSm),
                  label: Text(_busy ? '登录中…' : '登录 / 注册'),
                ),
              ),
              const SizedBox(height: AppDimens.sp16),
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
                          border: Border.all(
                              color: _agreed
                                  ? AppColors.mint
                                  : AppColors.textMute,
                              width: 1.5),
                          color: _agreed ? AppColors.mint : Colors.transparent,
                        ),
                        child: _agreed
                            ? const Icon(Icons.check_rounded,
                                size: 13, color: Colors.white)
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
                        style: TextStyle(
                            fontSize: AppDimens.fsCaption,
                            color: AppColors.textSoft),
                        children: [
                          TextSpan(text: '《用户协议》',
                              style: const TextStyle(color: AppColors.mint)),
                          TextSpan(text: '和',
                              style: TextStyle(color: AppColors.textSoft)),
                          TextSpan(text: '《隐私政策》',
                              style: const TextStyle(color: AppColors.mint)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sp12),
              Text(
                '微信登录将在二期上线',
                style: TextStyle(
                    fontSize: AppDimens.fsMicro, color: AppColors.textMute),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: AppDimens.fsFoot,
          color: AppColors.textSoft,
          fontWeight: FontWeight.w600,
        ),
      );
}
