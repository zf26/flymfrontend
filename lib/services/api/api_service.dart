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
    // 注意：GET 请求通常不需要 Content-Type，浏览器直接访问时也没有这个 header
    // 使用浏览器常见的 User-Agent，可能有助于匹配到直接路由而不是 Gateway 路由
    final Map<String, dynamic> headers = {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
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
        // headers: headers,
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
    // POST 请求需要 Content-Type
    final requestOptions = options ?? Options();
    final headers = Map<String, dynamic>.from(requestOptions.headers ?? {});
    headers['Content-Type'] = 'application/json';

    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: requestOptions.copyWith(headers: headers),
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
    // PUT 请求需要 Content-Type
    final requestOptions = options ?? Options();
    final headers = Map<String, dynamic>.from(requestOptions.headers ?? {});
    headers['Content-Type'] = 'application/json';

    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: requestOptions.copyWith(headers: headers),
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
