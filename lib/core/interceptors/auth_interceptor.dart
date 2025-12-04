import 'package:dio/dio.dart';
import 'package:flymfrontend/utils/storage_util.dart';
import 'package:flymfrontend/config/app_config.dart';
import 'package:flymfrontend/utils/logger_util.dart';

/// 认证拦截器
class AuthInterceptor extends Interceptor {
  /// 不需要认证的接口路径（白名单）
  static final List<String> _publicPaths = [
    '/code', // 获取图形验证码
    '/auth/login', // 登录
    '/auth/loginWithSmsCode', // 短信验证码登录
    '/auth/register', // 注册
    '/auth/sendSmsVerifyCode', // 发送短信验证码
    '/auth/getCaptcha', // 获取普通验证码
  ];

  /// 检查路径是否在白名单中
  bool _isPublicPath(String path) {
    return _publicPaths.any((publicPath) => path.startsWith(publicPath));
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 如果路径在白名单中，不需要添加token，并确保移除可能存在的Authorization header
    if (_isPublicPath(options.path)) {
      // 明确移除Authorization header，确保公开接口不携带token
      options.headers.remove('Authorization');
      LoggerUtil.d('公开接口 ${options.path}，已移除Authorization header');
      LoggerUtil.d('最终请求头: ${options.headers}');
      handler.next(options);
      return;
    }

    // 从本地存储获取token
    final token = StorageUtil.getString(AppConfig.keyToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 处理401未授权错误
    if (err.response?.statusCode == 401) {
      LoggerUtil.w('认证失败，清除本地token');
      StorageUtil.remove(AppConfig.keyToken);
      StorageUtil.remove(AppConfig.keyUserInfo);
      // 注意：这里不进行路由跳转，因为拦截器不应该依赖UI层
      // 路由跳转应该在错误处理层或Provider中处理
    }
    handler.next(err);
  }
}
