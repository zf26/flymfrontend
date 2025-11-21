import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flymfrontend/config/app_config.dart';
import 'package:flymfrontend/config/app_environment.dart';
import 'package:flymfrontend/core/interceptors/auth_interceptor.dart';
import 'package:flymfrontend/core/interceptors/logging_interceptor.dart';

/// API服务基类
class ApiService {
  late Dio _dio;

  ApiService() {
    // 构建基础请求头
    final Map<String, dynamic> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Web环境下添加额外请求头
    // 注意：不要手动添加 Origin 和 Referer，浏览器会自动添加
    if (kIsWeb) {
      headers['X-Requested-With'] = 'XMLHttpRequest';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: AppEnvironmentConfig.getApiBaseUrl(),
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
        headers: headers,
        // 设置响应类型
        responseType: ResponseType.json,
        // 允许跟随重定向
        followRedirects: true,
        // 最大重定向次数
        maxRedirects: 5,
        // 验证状态码
        validateStatus: (status) {
          // 允许所有状态码，不抛出异常，由业务层处理
          // 这样即使403也能获取到响应数据
          return status != null && status < 600;
        },
      ),
    );

    // 添加拦截器
    _dio.interceptors.add(AuthInterceptor());
    if (AppEnvironmentConfig.enableLogging) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// GET请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// POST请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// PUT请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// DELETE请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// 获取Dio实例（用于特殊需求）
  Dio get dio => _dio;
}
