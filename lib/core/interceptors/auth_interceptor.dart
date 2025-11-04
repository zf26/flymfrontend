import 'package:dio/dio.dart';
import 'package:flymfrontend/utils/storage_util.dart';
import 'package:flymfrontend/config/app_config.dart';
import 'package:flymfrontend/utils/logger_util.dart';

/// 认证拦截器
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
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
