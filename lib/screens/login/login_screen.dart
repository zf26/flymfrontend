import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/providers/auth_provider.dart';

/// 登录页
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // 登录表单控制器
  final _loginPhoneController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginCaptchaController = TextEditingController();
  bool _obscureLoginPassword = true;

  // 注册表单控制器
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerSmsCodeController = TextEditingController();
  bool _obscureRegisterPassword = true;

  // 图形验证码相关（登录用）
  String _captchaCode = '';
  final GlobalKey _captchaKey = GlobalKey();

  // 短信验证码倒计时相关（注册用）
  int _smsCountdown = 0;
  Timer? _smsTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateCaptcha();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _loginCaptchaController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerSmsCodeController.dispose();
    _smsTimer?.cancel();
    super.dispose();
  }

  /// 生成新的验证码（前端模拟，后续替换为API调用）
  void _generateCaptcha() {
    // TODO: 后续替换为实际的API调用
    // final response = await apiService.getCaptcha();
    // _captchaCode = response.captchaCode;

    // 前端模拟：生成4位字母数字混合验证码
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 排除易混淆字符
    final random = Random();
    _captchaCode = String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    // 验证验证码（不区分大小写）
    final inputCode = _loginCaptchaController.text.trim().toUpperCase();
    if (inputCode != _captchaCode.toUpperCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('验证码错误，请重新输入'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // 验证失败后刷新验证码
      _generateCaptcha();
      _loginCaptchaController.clear();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _loginPhoneController.text.trim(),
      _loginPasswordController.text,
    );

    if (mounted) {
      if (success) {
        context.go(AppConstants.routeHome);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? '登录失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleWeChatLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithWeChat();

    if (mounted) {
      if (success) {
        context.go(AppConstants.routeHome);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? '微信登录失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleAlipayLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithAlipay();

    if (mounted) {
      if (success) {
        context.go(AppConstants.routeHome);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? '支付宝登录失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 获取短信验证码
  Future<void> _handleGetSmsCode() async {
    // 验证手机号
    if (_registerPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入手机号'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!RegExp(
      r'^1[3-9]\d{9}$',
    ).hasMatch(_registerPhoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入正确的手机号'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 如果正在倒计时，不允许重复获取
    if (_smsCountdown > 0) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendSmsCode(
      _registerPhoneController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证码已发送'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // 开始倒计时
        _startSmsCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? '获取验证码失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 开始短信验证码倒计时
  void _startSmsCountdown() {
    _smsCountdown = 60;
    _smsTimer?.cancel();
    _smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_smsCountdown > 0) {
            _smsCountdown--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// 处理注册
  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _registerPhoneController.text.trim(),
      _registerPasswordController.text,
      _registerSmsCodeController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('注册成功'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppConstants.routeHome);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? '注册失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo和标题区域
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.medical_services_outlined,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '远程医疗问诊',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '安全便捷的在线医疗服务',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Tab切换
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: colorScheme.primary,
                            unselectedLabelColor: Colors.grey[600],
                            indicatorColor: colorScheme.primary,
                            indicatorWeight: 2,
                            tabs: const [Tab(text: '登录'), Tab(text: '注册')],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab内容区域
                        SizedBox(
                          height: constraints.maxHeight - 200,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLoginForm(colorScheme),
                              _buildRegisterForm(colorScheme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建登录表单
  Widget _buildLoginForm(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 手机号输入框
                  TextFormField(
                    controller: _loginPhoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: '手机号',
                      hintText: '请输入手机号',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入手机号';
                      }
                      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                        return '请输入正确的手机号';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // 密码输入框
                  TextFormField(
                    controller: _loginPasswordController,
                    obscureText: _obscureLoginPassword,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: '密码',
                      hintText: '请输入密码',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureLoginPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureLoginPassword = !_obscureLoginPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 6) {
                        return '密码长度至少6位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // 验证码输入框
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _loginCaptchaController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            labelText: '验证码',
                            hintText: '请输入验证码',
                            prefixIcon: Icon(
                              Icons.verified_outlined,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入验证码';
                            }
                            if (value.length != 4) {
                              return '验证码为4位字符';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 图形验证码
                      GestureDetector(
                        onTap: _generateCaptcha,
                        child: Container(
                          width: 100,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: _CaptchaImage(
                            code: _captchaCode,
                            key: _captchaKey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 登录按钮
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed:
                              authProvider.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child:
                              authProvider.isLoading
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    '登录',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 第三方登录区域
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '或',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
              ],
            ),
            const SizedBox(height: 12),
            // 微信和支付宝登录按钮
            Row(
              children: [
                Expanded(
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return _ThirdPartyLoginButton(
                        icon: _WeChatIcon(
                          size: 28,
                          color: const Color(0xFF07C160),
                        ),
                        label: '微信登录',
                        color: const Color(0xFF07C160),
                        onPressed:
                            authProvider.isLoading ? null : _handleWeChatLogin,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return _ThirdPartyLoginButton(
                        icon: _AlipayIcon(
                          size: 28,
                          color: const Color(0xFF1677FF),
                        ),
                        label: '支付宝登录',
                        color: const Color(0xFF1677FF),
                        onPressed:
                            authProvider.isLoading ? null : _handleAlipayLogin,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 底部提示
            Text(
              '登录即表示同意《用户协议》和《隐私政策》',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建注册表单
  Widget _buildRegisterForm(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 手机号输入框
                  TextFormField(
                    controller: _registerPhoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: '手机号',
                      hintText: '请输入手机号',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入手机号';
                      }
                      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                        return '请输入正确的手机号';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // 密码输入框
                  TextFormField(
                    controller: _registerPasswordController,
                    obscureText: _obscureRegisterPassword,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: '密码',
                      hintText: '请输入密码',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureRegisterPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureRegisterPassword =
                                !_obscureRegisterPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 6) {
                        return '密码长度至少6位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // 短信验证码输入框
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _registerSmsCodeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: '验证码',
                            hintText: '请输入验证码',
                            prefixIcon: Icon(
                              Icons.sms_outlined,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入验证码';
                            }
                            if (value.length != 6) {
                              return '验证码为6位数字';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 获取验证码按钮
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return SizedBox(
                            width: 120,
                            height: 48,
                            child: ElevatedButton(
                              onPressed:
                                  authProvider.isLoading || _smsCountdown > 0
                                      ? null
                                      : _handleGetSmsCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child:
                                  _smsCountdown > 0
                                      ? Text(
                                        '${_smsCountdown}s',
                                        style: const TextStyle(fontSize: 12),
                                      )
                                      : const Text(
                                        '获取验证码',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 注册按钮
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed:
                              authProvider.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: colorScheme.primary
                                .withOpacity(0.6),
                          ),
                          child:
                              authProvider.isLoading
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    '注册',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 底部提示
            Text(
              '注册即表示同意《用户协议》和《隐私政策》',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 图形验证码组件
class _CaptchaImage extends StatelessWidget {
  final String code;

  const _CaptchaImage({required this.code, super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 48),
      painter: _CaptchaPainter(code: code),
    );
  }
}

/// 验证码绘制器
class _CaptchaPainter extends CustomPainter {
  final String code;
  late final Random _random;

  _CaptchaPainter({required this.code}) {
    // 使用验证码字符串的哈希值作为随机种子，确保相同验证码绘制效果一致
    _random = Random(code.hashCode);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    final bgPaint =
        Paint()
          ..color = _getRandomLightColor()
          ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(10),
      ),
      bgPaint,
    );

    // 绘制干扰线
    for (int i = 0; i < 3; i++) {
      final linePaint =
          Paint()
            ..color = _getRandomColor()
            ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        linePaint,
      );
    }

    // 绘制干扰点
    for (int i = 0; i < 20; i++) {
      final pointPaint =
          Paint()
            ..color = _getRandomColor()
            ..strokeWidth = 1;
      canvas.drawCircle(
        Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        1,
        pointPaint,
      );
    }

    // 绘制验证码文字
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < code.length; i++) {
      final char = code[i];
      final textStyle = TextStyle(
        fontSize: 18 + _random.nextDouble() * 4 - 2, // 18-20之间随机
        fontWeight: FontWeight.bold,
        color: _getRandomDarkColor(),
        letterSpacing: 0,
      );

      textPainter.text = TextSpan(text: char, style: textStyle);
      textPainter.layout();

      // 计算字符位置（居中分布）
      final x = (size.width / code.length) * (i + 0.5) - textPainter.width / 2;
      final y = (size.height - textPainter.height) / 2;

      // 添加随机旋转
      canvas.save();
      canvas.translate(x + textPainter.width / 2, y + textPainter.height / 2);
      canvas.rotate((_random.nextDouble() - 0.5) * 0.3); // -15度到15度
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Color _getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(200),
      _random.nextInt(200),
      _random.nextInt(200),
      0.8,
    );
  }

  Color _getRandomLightColor() {
    return Color.fromRGBO(
      240 + _random.nextInt(15),
      240 + _random.nextInt(15),
      240 + _random.nextInt(15),
      1.0,
    );
  }

  Color _getRandomDarkColor() {
    final colors = [
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFE53935),
      const Color(0xFFFB8C00),
      const Color(0xFF7B1FA2),
      const Color(0xFF00897B),
    ];
    return colors[_random.nextInt(colors.length)];
  }
}

/// 微信图标组件
class _WeChatIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _WeChatIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/wechat.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// 支付宝图标组件
class _AlipayIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _AlipayIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/alipay.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// 第三方登录按钮组件
class _ThirdPartyLoginButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ThirdPartyLoginButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
